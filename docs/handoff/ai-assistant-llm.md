# Connect a real LLM to the in-app AI assistant

Owner-originated feature. Provider decided by the owner: **NaN Builders**
(nan.builders) with **`qwen3.8-flash`**.

## 1. Today's state (verified)

- The "Asistente IA" is local and rule-based. All of it sits behind the
  `Asistente IA local` marker inside
  `lib/presentation/pages/chats/chat_detail_page.dart` — grep the marker rather
  than a line number, which moves with the next edit. It answers from canned
  logic, offline, with no provider.
- There is no backend: no `functions/`, no Cloud Functions, no API of our own.
  The remote side is Firestore (rules + indexes + `storage.rules`).
- `.env` carries only `OPENWEATHER_API_KEY`, `GOOGLE_MAPS_API_KEY` and
  RevenueCat placeholders. `.env.example` states the rule that matters here:
  **Flutter assets are extractable; never put a backend secret in `.env`.**

## 2. Provider facts (verified against the provider's own documentation)

NaN Builders is a flat-rate, EU-hosted, zero-logging community inference cluster
exposed through an **OpenAI-compatible API**:

- Base URL `https://api.nan.builders/v1`, auth `Authorization: Bearer $NAN_API_KEY`.
- `qwen3.8-flash`: 125B-parameter MoE, 6B active, 1M-token context (1,048,576),
  131K max answer, text + image input, **tool calling**, **reasoning always on
  and its depth is not adjustable** (the `reasoning_effort` parameter is accepted
  and ignored), SSE streaming with the reasoning trace delivered separately in
  `message.reasoning_content`.
- Quota: 500M tokens/month per member; 60 requests/minute per key; 7 concurrent
  requests on the base plan (10 on premium).
- The same key also reaches `qwen3-embedding` (4096-dim), a Qwen3 reranker, and
  Whisper — useful later for semantic search over places and voice input to the
  assistant, out of scope for v1.

Two consequences to design around, both real:

1. **Reasoning on by default** costs latency and output budget. Cap `max_tokens`,
   never render `reasoning_content` in the app, and measure real latency before
   shipping.
2. **A proxy is mandatory.** `NAN_API_KEY` is a personal member key. Putting it in
   the APK hands it to anyone who unzips it.

## 3. Architecture

**Boundary first**, mirroring the places boundary the repository already uses
(`lib/core/services/places/`): a provider-neutral `AssistantGateway` under
`lib/core/services/assistant/`, with

- `AssistantAvailability { configured, demo, unavailable }`,
- `Future<Either<Failure, AssistantReply>> send({required List<AssistantMessage> history, String? tripContext, String locale})`,
- an optional `Stream<AssistantChunk>` for streaming,
- provider-neutral failures mirroring `places_failures.dart`
  (config / quota / parse / network).

Implementations: `LocalAssistantGateway` (today's rule-based answers, the
offline default) and `NanAssistantGateway` (talks to the proxy). Registration in
`lib/injection/injection.dart` picks the implementation from configuration.

**Proxy contract** (the only place the key lives):

- `POST /assistant/chat`, `Authorization: <Firebase ID token>`.
- Body: `{ messages: [{role, content}], locale, tripContext? }`.
- Server side: verify the Firebase ID token and derive `uid`; apply per-uid rate
  limits (suggested 10/min and 200/day) because one shared key serves every user;
  build the system prompt server-side; call
  `https://api.nan.builders/v1/chat/completions` with
  `model: "qwen3.8-flash"`, `stream: true`, a capped `max_tokens`; relay only
  `content` deltas and drop `reasoning_content`; 30 s timeout; return a neutral
  429/503 on limit or failure.
- **Stateless, zero content logging.** Do not persist prompts or answers
  server-side; do not log message bodies. Usage counters (tokens, uid hash) are
  fine; content is not.
- Host choice, one decision to make: **Cloudflare Workers free tier** (no card,
  EU region, secrets in Worker env) or **Firebase Cloud Functions** (same
  ecosystem, but the Blaze plan with a card on file). Workers is the cheaper path
  and does not touch the Firebase project.

## 4. Behaviour rules

- **Offline first.** If the gateway is `unavailable` or the call fails, the
  existing local assistant answers. The UI must never imply an LLM is answering
  when it is not, exactly like the places boundary refuses to simulate live
  results.
- The assistant stays inside the product: travel planning, itineraries, packing,
  weather, destination questions. Refuse medical, legal and financial advice and
  anything requiring personal data beyond the trip context.
- **No PII in prompts.** Send the trip and the conversation, nothing else. No
  email, no uid, no contact list, no precise home coordinates.
- Streaming is an enhancement: with no stream, show a typing indicator and the
  full answer.
- Cap and surface cost: server-side counters, and a client-side guard on absurd
  histories (trim to the last N turns).

## 5. Legal and store consequences (do not skip)

Sending user text to a third party changes the privacy story:

- The privacy policy and the in-app notices must name the AI provider and the
  proxy host as processors, and state that conversation content is transmitted
  and not retained.
- The Play Store **data-safety form** must declare it (it currently truthfully
  says the app collects nothing; that stops being true).
- `docs/production/launch-plan.md` Milestone 1 item 5 (data-safety form) and the
  privacy-policy work in the legal annex both depend on this decision.
- NaN Builders' own posture helps (EU hosting, zero-log claim), but the
  processor contract and the record of processing still belong to the owner's
  obligations.

## 6. Terms-of-service risk — read this before shipping

NaN Builders is a **community, flat-rate subscription for individual builders**,
with a per-member monthly token allowance and per-key concurrency limits. Using
one member key as the unseen backend of a published app, for an unbounded number
of end users, is very likely outside those terms, and the quota is charged to the
owner's membership either way.

Recommended posture, which this architecture already supports:

- NaN is the **development and personal provider**: perfect for building and
  demonstrating the feature at zero marginal cost.
- For production, either ask NaN explicitly for permission, or swap the proxy's
  upstream to a commercial provider. Because the app only knows
  `AssistantGateway`, that swap is one file in the proxy plus no app change.
- Alternatively, keep the LLM as a **premium** feature behind the subscription
  work (Milestone 2) and cap it per user — which also keeps the cost per user
  bounded and makes the flat-rate provider defensible.

## 7. Required tests

- Gateway contract tests with a fake HTTP client: success, timeout, 429, 5xx,
  malformed body → the right provider-neutral failure, and never a thrown
  exception into the UI.
- A test that proves a key cannot reach the client: no `NAN_API_KEY` or
  `api.nan.builders` literal in `lib/`, `assets/` or `.env.example` (a grep test
  is enough and it is worth having).
- Bloc tests: streaming chunks assemble in order; reasoning chunks never reach
  the visible message; failure falls back to the local assistant.
- Widget test: an unavailable provider shows the local assistant and says so.
- Regression: full suite green, analyzer clean in touched files.

## 8. Out of scope for v1

- Function/tool calling into the app's own data (itinerary writes, packing) —
  the provider supports it; adding write authority through an LLM needs its own
  safety design.
- Image input, voice input (Whisper is available on the same key), embeddings and
  semantic place search.
- Multi-turn memory across devices, and any server-side conversation history.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../../tool/release_config_validator.dart';

void main() {
  late Directory root;

  Future<void> writeValidCiWorkflow() async {
    final workflow = File('${root.path}/.github/workflows/ci.yml');
    await workflow.parent.create(recursive: true);
    await workflow.writeAsString('''
name: CI
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262
      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2
      - run: flutter pub get --enforce-lockfile
      - run: dart run tool/release_config_validator.dart
      - run: flutter analyze --no-fatal-infos --no-fatal-warnings
      - run: flutter test
''');
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('release_config_validator_');
    await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
flutter:
  assets:
    - .env
''');
    await File('${root.path}/pubspec.lock').writeAsString('packages: {}\n');
    await File('${root.path}/.env.example').writeAsString('''
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
REVENUECAT_API_KEY=YOUR_REVENUECAT_API_KEY
REVENUECAT_API_KEY_IOS=YOUR_REVENUECAT_API_KEY_IOS
''');
    await writeValidCiWorkflow();
  });

  Future<List<ConfigViolation>> validate() =>
      ReleaseConfigValidator.validate(root);

  test('accepts only approved placeholder-only client configuration', () async {
    expect(await validate(), isEmpty);
  });

  test('reports a missing CI workflow', () async {
    await File('${root.path}/.github/workflows/ci.yml').delete();

    expect(
      (await validate()).map((violation) => violation.code),
      contains('missing_ci_workflow'),
    );
  });

  test('rejects CI actions pinned to a tag', () async {
    final workflow = File('${root.path}/.github/workflows/ci.yml');
    final content = await workflow.readAsString();
    await workflow.writeAsString(content.replaceFirst(
      'actions/checkout@11d5960a326750d5838078e36cf38b85af677262',
      'actions/checkout@v4.4.0',
    ));

    final violations = await validate();

    expect(
      violations.map((violation) => violation.code),
      contains('ci_action_not_sha_pinned'),
    );
    expect(violations.map((violation) => violation.subject),
        contains('actions/checkout'));
    expect(violations.join('\n'), isNot(contains('v4.4.0')));
  });

  test('reports CI without least-privilege contents-read permissions',
      () async {
    final workflow = File('${root.path}/.github/workflows/ci.yml');
    final content = await workflow.readAsString();
    await workflow.writeAsString(
        content.replaceFirst('  contents: read\n', '  contents: write\n'));

    expect(
      (await validate()).map((violation) => violation.code),
      contains('missing_ci_contents_read_permission'),
    );
  });

  test('reports CI missing a required baseline command', () async {
    final workflow = File('${root.path}/.github/workflows/ci.yml');
    final content = await workflow.readAsString();
    await workflow
        .writeAsString(content.replaceFirst('      - run: flutter test\n', ''));

    final violations = await validate();

    expect(
      violations.map((violation) => violation.code),
      contains('missing_ci_baseline_command'),
    );
    expect(violations.map((violation) => violation.subject), contains('test'));
  });

  test('reports a missing environment template', () async {
    await File('${root.path}/.env.example').delete();

    expect(
      (await validate()).map((violation) => violation.code),
      contains('missing_env_example'),
    );
  });

  test('reports real-looking placeholder values without revealing them',
      () async {
    await File('${root.path}/.env.example').writeAsString(
      'OPENWEATHER_API_KEY=live-client-key-123\n',
    );

    final violations = await validate();

    expect(
      violations.map((violation) => violation.code),
      contains('non_placeholder_value'),
    );
    expect(violations.join('\n'), isNot(contains('live-client-key-123')));
  });

  test('reports forbidden server-secret variable names', () async {
    await File('${root.path}/.env.example').writeAsString(
      'PRIVATE_KEY=YOUR_PRIVATE_KEY\n',
    );

    expect(
      (await validate()).map((violation) => violation.code),
      contains('forbidden_server_secret'),
    );
  });

  test('reports a missing dependency lockfile', () async {
    await File('${root.path}/pubspec.lock').delete();

    expect(
      (await validate()).map((violation) => violation.code),
      contains('missing_pubspec_lock'),
    );
  });

  test('reports unapproved configuration variables exposed by pubspec',
      () async {
    await File('${root.path}/pubspec.yaml').writeAsString('''
name: fixture
flutter:
  assets:
    - .env
    - EXTRA_CLIENT_KEY
''');

    expect(
      (await validate()).map((violation) => violation.code),
      contains('unapproved_pubspec_variable'),
    );
  });

  test('reports unapproved variables in the environment template', () async {
    await File('${root.path}/.env.example').writeAsString('''
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
REVENUECAT_API_KEY=YOUR_REVENUECAT_API_KEY
REVENUECAT_API_KEY_IOS=YOUR_REVENUECAT_API_KEY_IOS
EXTRA_CLIENT_KEY=YOUR_EXTRA_CLIENT_KEY
''');

    expect(
      (await validate()).map((violation) => violation.code),
      contains('unapproved_env_variable'),
    );
  });

  test('reports a missing required approved placeholder', () async {
    await File('${root.path}/.env.example').writeAsString('''
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
REVENUECAT_API_KEY=YOUR_REVENUECAT_API_KEY
''');

    expect(
      (await validate()).map((violation) => violation.code),
      contains('missing_client_placeholder'),
    );
  });

  test('reports each duplicate placeholder environment entry', () async {
    await File('${root.path}/.env.example').writeAsString('''
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY
OPENWEATHER_API_KEY=YOUR_OTHER_OPENWEATHER_API_KEY
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
REVENUECAT_API_KEY=YOUR_REVENUECAT_API_KEY
REVENUECAT_API_KEY_IOS=YOUR_REVENUECAT_API_KEY_IOS
''');

    final violations = await validate();

    expect(
      violations.where((violation) =>
          violation.code == 'duplicate_env_variable' &&
          violation.subject == 'OPENWEATHER_API_KEY'),
      hasLength(1),
    );
  });

  test('validates every duplicate environment entry without revealing values',
      () async {
    await File('${root.path}/.env.example').writeAsString('''
OPENWEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY
OPENWEATHER_API_KEY=live-client-key-123
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
REVENUECAT_API_KEY=YOUR_REVENUECAT_API_KEY
REVENUECAT_API_KEY_IOS=YOUR_REVENUECAT_API_KEY_IOS
''');

    final violations = await validate();

    expect(
      violations.map((violation) => violation.code),
      contains('non_placeholder_value'),
    );
    expect(violations.join('\n'), isNot(contains('live-client-key-123')));
  });

  test('detects PEM private-key blocks in production roots', () async {
    final file = File('${root.path}/lib/secrets.dart');
    await file.parent.create();
    await file.writeAsString('-----BEGIN PRIVATE KEY-----\nprivate-value\n');

    expect(
      (await validate()).map((violation) => violation.subject),
      contains('lib/secrets.dart: pem_private_key'),
    );
  });

  test('detects service-account markers in production roots', () async {
    final file = File('${root.path}/backend/service-account.json');
    await file.parent.create();
    await file.writeAsString('{"type": "service_account"}');

    expect(
      (await validate()).map((violation) => violation.subject),
      contains('backend/service-account.json: service_account_json'),
    );
  });

  test('detects forbidden secret assignments in production roots', () async {
    final file = File('${root.path}/infra/deployment.env');
    await file.parent.create();
    await file.writeAsString('WEBHOOK_SECRET=real-secret-value');

    final violations = await validate();

    expect(
      violations.map((violation) => violation.subject),
      contains('infra/deployment.env: forbidden_server_secret_assignment'),
    );
    expect(violations.join('\n'), isNot(contains('real-secret-value')));
  });

  test('never reads .env', () async {
    final env = File('${root.path}/lib/.env');
    await env.parent.create();
    await env.writeAsString(
      'WEBHOOK_SECRET=real-secret-value',
    );

    final violations = await validate();

    expect(violations, isEmpty);
    expect(violations.join('\n'), isNot(contains('real-secret-value')));
  });

  test('excludes docs tests tool and root config from secret scanning',
      () async {
    for (final path in <String>[
      'docs/key.txt',
      'test/key.txt',
      'tool/key.txt',
      'config/key.txt',
    ]) {
      final file = File('${root.path}/$path');
      await file.parent.create();
      await file.writeAsString('-----BEGIN PRIVATE KEY-----');
    }

    expect(await validate(), isEmpty);
  });
}

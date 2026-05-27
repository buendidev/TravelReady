import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ready/domain/entities/user.dart';
import 'package:travel_ready/domain/entities/trip.dart';
import 'package:travel_ready/domain/entities/chat.dart';
import 'package:travel_ready/domain/entities/packing_item.dart';
import 'package:travel_ready/domain/repositories/auth_repository.dart';
import 'package:travel_ready/domain/repositories/chats_repository.dart';
import 'package:travel_ready/domain/repositories/trips_repository.dart';
import 'package:travel_ready/domain/usecases/auth/sign_in_usecase.dart';
import 'package:travel_ready/domain/usecases/auth/sign_up_usecase.dart';
import 'package:travel_ready/domain/usecases/trips/create_trip_usecase.dart';

// ── Mocks reutilizables ────────────────────────────────────────────────────
class MockAuthRepository    extends Mock implements AuthRepository {}
class MockTripsRepository   extends Mock implements TripsRepository {}
class MockPackingRepository extends Mock implements PackingRepository {}
class MockChatsRepository   extends Mock implements ChatsRepository {}

// ── Registro de fallbacks (llamar en setUpAll) ────────────────────────────
void registerFallbacks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(User(
    id: 'fb_uid',
    name: 'Test User',
    email: 'test@test.com',
    createdAt: DateTime(2026),
  ));
  registerFallbackValue(Trip(
    id: '',
    userId: 'fb_uid',
    name: 'Test Trip',
    destination: 'Test',
    startDate: DateTime(2026, 7, 1),
    endDate:   DateTime(2026, 7, 8),
    createdAt: DateTime(2026),
  ));
  registerFallbackValue(const SignInParams(email: '', password: ''));
  registerFallbackValue(const SignUpParams(name: '', email: '', password: ''));
  registerFallbackValue(const PackingItem(id: '', listId: '', tripId: '', name: ''));
  registerFallbackValue(PackingList(id: '', tripId: '', name: '', createdAt: DateTime(2026)));
  registerFallbackValue(CreateTripParams(
    userId: '', name: '', destination: '',
    startDate: DateTime(2026), endDate: DateTime(2026),
  ));
  registerFallbackValue(Chat(id: '', type: ChatType.private, createdAt: DateTime(2026)));
  registerFallbackValue(Message(id: '', chatId: '', senderId: '', text: '', createdAt: DateTime(2026)));
  registerFallbackValue(const ChatSummary(chatId: '', type: ChatType.private, name: ''));
}

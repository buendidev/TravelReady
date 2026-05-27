import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/data/models/packing_item_model.dart';
import 'package:travel_ready/domain/entities/packing_item.dart';
import 'package:travel_ready/domain/entities/trip.dart';
import 'package:travel_ready/domain/entities/user.dart';

// ── Constantes ────────────────────────────────────────────────────────────
const tEmail    = 'pablo@travelready.com';
const tPassword = 'password123';
const tName     = 'Pablo Buendicho';

final tNow = DateTime(2026, 4, 14);

// ── Entidades ─────────────────────────────────────────────────────────────
final tUserFull = User(
  id:        'user_test_01',
  name:      tName,
  email:     tEmail,
  plan:      UserPlan.free,
  createdAt: tNow,
);

final tTrip = Trip(
  id:          'trip_test_01',
  userId:      'user_test_01',
  name:        'Viaje a París',
  destination: 'París, Francia',
  startDate:   DateTime(2026, 7, 1),
  endDate:     DateTime(2026, 7, 8),
  tripType:    TripType.city,
  transport:   [TransportType.plane],
  activities:  ['turismo', 'gastronomía'],
  createdAt:   tNow,
);

final tTrip2 = Trip(
  id:          'trip_test_02',
  userId:      'user_test_01',
  name:        'Playa en Mallorca',
  destination: 'Mallorca, España',
  startDate:   DateTime(2026, 8, 1),
  endDate:     DateTime(2026, 8, 10),
  tripType:    TripType.beach,
  createdAt:   tNow,
);

// tripId obligatorio en PackingItem (añadido en sesión previa)
final tPackingList = PackingListModel(
  id:        'list_test_01',
  tripId:    tTrip.id,
  name:      'Equipaje París',
  createdAt: tNow,
  items: [
    PackingItemModel(
      id: 'item_01', listId: 'list_test_01', tripId: tTrip.id,
      name: 'Pasaporte', category: PackingCategory.documents),
    PackingItemModel(
      id: 'item_02', listId: 'list_test_01', tripId: tTrip.id,
      name: 'Cargador móvil', category: PackingCategory.electronics,
      isPacked: true),
  ],
);

// ── Failures ───────────────────────────────────────────────────────────────
const tServerFailure  = ServerFailure('Error del servidor de prueba');
const tNetworkFailure = NetworkFailure('Sin conexión de prueba');
const tAuthFailure    = AuthFailure('Credenciales inválidas');
const tNotFound       = NotFoundFailure('Viaje no encontrado');

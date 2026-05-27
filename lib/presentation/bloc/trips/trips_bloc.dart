import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/trip.dart';
import '../../../domain/usecases/trips/create_trip_usecase.dart';
import '../../../domain/repositories/trips_repository.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/utils/security_log.dart';

part 'trips_event.dart';
part 'trips_state.dart';

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final CreateTripUseCase _createTrip;
  final TripsRepository   _repo;

  TripsBloc({
    required CreateTripUseCase createTripUseCase,
    required TripsRepository repo,
  })  : _createTrip = createTripUseCase,
        _repo       = repo,
        super(const TripsInitial()) {
    on<TripsLoaded>(_onLoaded);
    on<TripCreated>(_onCreated);
    on<TripDeleted>(_onDeleted);
    on<TripUpdated>(_onUpdated);
  }

  /// Usa watchTrips (stream) → actualización en tiempo real sin reiniciar.
  Future<void> _onLoaded(TripsLoaded e, Emitter<TripsState> emit) async {
    emit(const TripsLoading());
    await emit.forEach(
      _repo.watchTrips(e.userId),
      onData: (result) => result.fold(
        (f) => TripsError(f.message),
        (trips) => TripsReady(trips),
      ),
      onError: (_, __) => const TripsError('Error cargando viajes.'),
    );
  }

  Future<void> _onCreated(TripCreated e, Emitter<TripsState> emit) async {
    final name = InputSanitizer.sanitizeTruncate(e.name, 80);
    final dest = InputSanitizer.sanitizeTruncate(e.destination, 100);
    if (!InputSanitizer.isValidTripName(name)) {
      SecurityLog.inputRejected('trip_name', 'invalid');
      return; // El stream actualiza automáticamente
    }
    // Crea en Firestore → el stream watchTrips emite automáticamente
    await _createTrip(CreateTripParams(
      userId:      e.userId,
      name:        name,
      destination: dest,
      startDate:   e.startDate,
      endDate:     e.endDate,
      tripType:    e.tripType,
      transport:   e.transport,
      activities:  e.activities,
    ));
    // No emitimos estado — el stream reacciona solo
  }

  Future<void> _onDeleted(TripDeleted e, Emitter<TripsState> emit) async {
    await _repo.deleteTrip(e.tripId);
    // El stream reacciona automáticamente
  }

  Future<void> _onUpdated(TripUpdated e, Emitter<TripsState> emit) async {
    await _repo.updateTrip(e.trip);
  }
}

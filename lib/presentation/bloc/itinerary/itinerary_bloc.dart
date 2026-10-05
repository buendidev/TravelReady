import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/utils/security_log.dart';
import '../../../domain/entities/itinerary/itinerary_item.dart';
import '../../../domain/entities/itinerary/place_snapshot.dart';
import '../../../domain/repositories/itinerary_repository.dart';

part 'itinerary_event.dart';
part 'itinerary_state.dart';

/// ItineraryBloc reactivo basado en el stream del repositorio.
/// Mismo patrón que PackingBloc: el stream emite en cada CUD,
/// sin optimistic updates manuales.
class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final ItineraryRepository _repo;
  ItineraryReady? _lastReady;

  ItineraryBloc({required ItineraryRepository repo})
      : _repo = repo,
        super(const ItineraryInitial()) {
    on<ItineraryLoaded>(_onLoaded);
    on<ItineraryItemAdded>(_onItemAdded);
    on<ItineraryItemUpdated>(_onItemUpdated);
    on<ItineraryItemDeleted>(_onItemDeleted);
    on<ItineraryItemsReordered>(_onReordered);
  }

  Future<void> _onLoaded(
      ItineraryLoaded e, Emitter<ItineraryState> emit) async {
    emit(const ItineraryLoading());
    await emit.forEach(
      _repo.watchItems(e.tripId),
      onData: (either) => either.fold(
        (f) => ItineraryError(f.message),
        (items) => _lastReady =
            ItineraryReady(items: items, tripId: e.tripId),
      ),
      onError: (_, __) => const ItineraryError('Error cargando itinerario.'),
    );
  }

  Future<void> _onItemAdded(
      ItineraryItemAdded e, Emitter<ItineraryState> emit) async {
    final title = InputSanitizer.sanitizeTruncate(e.title, 120);
    if (!InputSanitizer.isValidItemName(title)) {
      SecurityLog.inputRejected('itinerary_title', 'invalid');
      return;
    }
    final notes = e.notes == null
        ? null
        : InputSanitizer.sanitizeTruncate(e.notes!, 500);
    final result = await _repo.addItem(ItineraryItem(
      id: '',
      tripId: e.tripId,
      day: DateTime(e.day.year, e.day.month, e.day.day),
      startMinutes: e.startMinutes,
      endMinutes: e.endMinutes,
      title: title,
      category: e.category,
      notes: notes,
      place: e.place,
    ));
    _emitMutationResult(result, emit);
  }

  Future<void> _onItemUpdated(
      ItineraryItemUpdated e, Emitter<ItineraryState> emit) async {
    final title = InputSanitizer.sanitizeTruncate(e.item.title, 120);
    if (!InputSanitizer.isValidItemName(title)) {
      SecurityLog.inputRejected('itinerary_title', 'invalid');
      return;
    }
    final notes = e.item.notes == null
        ? null
        : InputSanitizer.sanitizeTruncate(e.item.notes!, 500);
    final result =
        await _repo.updateItem(e.item.copyWith(title: title, notes: notes));
    _emitMutationResult(result, emit);
  }

  Future<void> _onItemDeleted(
      ItineraryItemDeleted e, Emitter<ItineraryState> emit) async {
    final result = await _repo.deleteItem(e.itemId);
    _emitMutationResult(result, emit);
  }

  Future<void> _onReordered(
      ItineraryItemsReordered e, Emitter<ItineraryState> emit) async {
    final result = await _repo.reorderItems(e.tripId, e.orderedIds);
    _emitMutationResult(result, emit);
  }

  void _emitMutationResult<T>(
      Either<Failure, T> result, Emitter<ItineraryState> emit) {
    result.fold(
      (failure) => emit(ItineraryError(failure.message)),
      (_) {
        emit(const ItineraryMutationSucceeded());
        if (_lastReady != null) emit(_lastReady!);
      },
    );
  }
}

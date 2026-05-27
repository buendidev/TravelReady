import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/packing_item.dart';
import '../../../domain/repositories/trips_repository.dart';
import '../../../data/datasources/local/trips_local_datasource.dart';
import '../../../injection/injection.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../core/utils/security_log.dart';

part 'packing_event.dart';
part 'packing_state.dart';

/// PackingBloc reactivo basado en stream de SQLite.
/// El stream del datasource emite cada vez que hay cambios (CUD), por lo que
/// no necesitamos optimistic updates manuales: confiamos en el stream.
class PackingBloc extends Bloc<PackingEvent, PackingState> {
  final PackingRepository    _repo;
  final TripsLocalDataSource _ds;

  PackingBloc({required PackingRepository repo})
      : _repo = repo,
        _ds   = getIt<TripsLocalDataSource>(),
        super(const PackingInitial()) {
    on<PackingListsLoaded>(_onLoaded);
    on<PackingListCreated>(_onListCreated);
    on<PackingListDeleted>(_onListDeleted);
    on<PackingItemAdded>(_onItemAdded);
    on<PackingItemToggled>(_onItemToggled);
    on<PackingItemDeleted>(_onItemDeleted);
  }

  /// Suscribe al stream de listas. El stream emite cuando hay cambios.
  Future<void> _onLoaded(
      PackingListsLoaded e, Emitter<PackingState> emit) async {
    emit(const PackingLoading());
    await emit.forEach<List<PackingList>>(
      _ds.watchPackingLists(e.tripId),
      onData: (lists) => PackingListsReady(lists: lists, tripId: e.tripId),
      onError: (_, __) => const PackingError('Error cargando listas.'),
    );
  }

  Future<void> _onListCreated(
      PackingListCreated e, Emitter<PackingState> emit) async {
    final name = InputSanitizer.sanitizeTruncate(e.name, 80);
    if (!InputSanitizer.isValidItemName(name)) {
      SecurityLog.inputRejected('list_name', 'invalid');
      return;
    }
    await _repo.createList(PackingList(
        id: '', tripId: e.tripId, name: name, createdAt: DateTime.now()));
  }

  Future<void> _onListDeleted(
      PackingListDeleted e, Emitter<PackingState> emit) async {
    await _repo.deleteList(e.listId);
  }

  Future<void> _onItemAdded(
      PackingItemAdded e, Emitter<PackingState> emit) async {
    final name = InputSanitizer.sanitizeTruncate(e.name, 80);
    if (!InputSanitizer.isValidItemName(name)) {
      SecurityLog.inputRejected('item_name', 'invalid');
      return;
    }
    await _repo.addItem(PackingItem(
      id: '', listId: e.listId, tripId: e.tripId,
      name: name, category: e.category, quantity: e.quantity,
    ));
  }

  Future<void> _onItemToggled(
      PackingItemToggled e, Emitter<PackingState> emit) async {
    await _repo.updateItem(e.item.toggle());
  }

  Future<void> _onItemDeleted(
      PackingItemDeleted e, Emitter<PackingState> emit) async {
    await _repo.deleteItem(e.item.id);
  }
}

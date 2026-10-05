import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travel_ready/core/errors/failures.dart';
import 'package:travel_ready/domain/entities/itinerary/itinerary_item.dart';
import 'package:travel_ready/domain/repositories/itinerary_repository.dart';
import 'package:travel_ready/presentation/bloc/itinerary/itinerary_bloc.dart';

class MockItineraryRepository extends Mock implements ItineraryRepository {}

class FakeItineraryItem extends Fake implements ItineraryItem {}

void main() {
  late MockItineraryRepository repo;

  ItineraryItem item({String id = 'a', int order = 0}) => ItineraryItem(
        id: id,
        tripId: 't1',
        day: DateTime(2025, 7, 15),
        startMinutes: 600,
        title: 'Plan $id',
        orderIndex: order,
      );

  setUpAll(() => registerFallbackValue(FakeItineraryItem()));

  setUp(() {
    repo = MockItineraryRepository();
    when(() => repo.watchItems('t1'))
        .thenAnswer((_) => Stream.value(Right([item()])));
  });

  blocTest<ItineraryBloc, ItineraryState>(
    'emits loading then ready with the watched items',
    build: () => ItineraryBloc(repo: repo),
    act: (b) => b.add(const ItineraryLoaded(tripId: 't1')),
    expect: () => [
      isA<ItineraryLoading>(),
      isA<ItineraryReady>(),
    ],
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'emits empty-ready state when the trip has no items',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.watchItems('t1'))
        .thenAnswer((_) => Stream.value(const Right([]))),
    act: (b) => b.add(const ItineraryLoaded(tripId: 't1')),
    expect: () => [
      isA<ItineraryLoading>(),
      isA<ItineraryReady>().having((s) => s.items, 'items', isEmpty),
    ],
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'emits error state when the watch stream fails',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.watchItems('t1')).thenAnswer((_) =>
        Stream.value(const Left(ServerFailure('boom')))),
    act: (b) => b.add(const ItineraryLoaded(tripId: 't1')),
    expect: () => [
      isA<ItineraryLoading>(),
      isA<ItineraryError>(),
    ],
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'add event sanitizes the title and calls the repository',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.addItem(any()))
        .thenAnswer((i) async => Right(i.positionalArguments.first)),
    act: (b) => b.add(ItineraryItemAdded(
      tripId: 't1',
      day: DateTime(2025, 7, 15),
      startMinutes: 600,
      title: '  Museo<Prado>  ',
    )),
    verify: (_) {
      final saved =
          verify(() => repo.addItem(captureAny())).captured.single
              as ItineraryItem;
      expect(saved.title, 'MuseoPrado');
      expect(saved.tripId, 't1');
      expect(saved.startMinutes, 600);
    },
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'add event rejects an empty title without touching the repository',
    build: () => ItineraryBloc(repo: repo),
    act: (b) => b.add(ItineraryItemAdded(
      tripId: 't1',
      day: DateTime(2025, 7, 15),
      startMinutes: 600,
      title: '   ',
    )),
    verify: (_) => verifyNever(() => repo.addItem(any())),
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'emits an error when adding fails to persist',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.addItem(any()))
        .thenAnswer((_) async => const Left(ServerFailure('write failed'))),
    act: (b) => b.add(ItineraryItemAdded(
      tripId: 't1',
      day: DateTime(2025, 7, 15),
      startMinutes: 600,
      title: 'Museo',
    )),
    expect: () => [
      isA<ItineraryError>().having((s) => s.message, 'message', 'write failed'),
    ],
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'emits an error when updating fails to persist',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.updateItem(any()))
        .thenAnswer((_) async => const Left(ServerFailure('write failed'))),
    act: (b) => b.add(ItineraryItemUpdated(item: item(id: 'a'))),
    expect: () => [
      isA<ItineraryError>().having((s) => s.message, 'message', 'write failed'),
    ],
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'emits an error when deleting fails to persist',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.deleteItem(any()))
        .thenAnswer((_) async => const Left(ServerFailure('write failed'))),
    act: (b) => b.add(const ItineraryItemDeleted(itemId: 'a')),
    expect: () => [
      isA<ItineraryError>().having((s) => s.message, 'message', 'write failed'),
    ],
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'emits an error when reordering fails to persist',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.reorderItems(any(), any()))
        .thenAnswer((_) async => const Left(ServerFailure('write failed'))),
    act: (b) => b.add(const ItineraryItemsReordered(
        tripId: 't1', orderedIds: ['c', 'a'])),
    expect: () => [
      isA<ItineraryError>().having((s) => s.message, 'message', 'write failed'),
    ],
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'reorder event delegates ordered ids to the repository',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.reorderItems(any(), any()))
        .thenAnswer((_) async => const Right(unit)),
    act: (b) => b.add(const ItineraryItemsReordered(
        tripId: 't1', orderedIds: ['c', 'a'])),
    verify: (_) =>
        verify(() => repo.reorderItems('t1', ['c', 'a'])).called(1),
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'delete event delegates to the repository',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.deleteItem(any()))
        .thenAnswer((_) async => const Right(unit)),
    act: (b) => b.add(const ItineraryItemDeleted(itemId: 'a')),
    verify: (_) => verify(() => repo.deleteItem('a')).called(1),
  );

  blocTest<ItineraryBloc, ItineraryState>(
    'update event delegates to the repository',
    build: () => ItineraryBloc(repo: repo),
    setUp: () => when(() => repo.updateItem(any()))
        .thenAnswer((i) async => Right(i.positionalArguments.first)),
    act: (b) => b.add(ItineraryItemUpdated(item: item(id: 'a'))),
    verify: (_) => verify(() => repo.updateItem(any())).called(1),
  );
}

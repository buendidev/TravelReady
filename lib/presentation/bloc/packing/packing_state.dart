part of 'packing_bloc.dart';

sealed class PackingState extends Equatable {
  const PackingState();
  @override List<Object?> get props => [];
}

final class PackingInitial extends PackingState {
  const PackingInitial();
}

final class PackingLoading extends PackingState {
  const PackingLoading();
}

final class PackingListsReady extends PackingState {
  final List<PackingList> lists;
  final String tripId;
  const PackingListsReady({required this.lists, required this.tripId});
  @override List<Object> get props => [lists, tripId];
}

final class PackingError extends PackingState {
  final String message;
  const PackingError(this.message);
  @override List<Object> get props => [message];
}

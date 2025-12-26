import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/place.dart';
import '../services/place_service.dart';

final placeServiceProvider = Provider<PlaceService>((ref) => PlaceService());

final placesStreamProvider = StreamProvider<List<Place>>((ref) {
  return ref.watch(placeServiceProvider).placesStream();
});

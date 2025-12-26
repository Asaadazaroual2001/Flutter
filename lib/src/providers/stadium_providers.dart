import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stadium.dart';
import '../services/stadium_service.dart';

final stadiumServiceProvider =
    Provider<StadiumService>((ref) => StadiumService());

final stadiumsStreamProvider = StreamProvider<List<Stadium>>((ref) {
  return ref.watch(stadiumServiceProvider).stadiumsStream();
});

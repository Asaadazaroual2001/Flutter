import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/place.dart';
import '../../models/stadium.dart';
import '../../providers/place_providers.dart';
import '../../providers/stadium_providers.dart';

class SeedDataScreen extends ConsumerWidget {
  static const routeName = '/seed';
  const SeedDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> seed() async {
      final placeService = ref.read(placeServiceProvider);
      final stadiumService = ref.read(stadiumServiceProvider);

      // Places (example – بدّلهم براحتك)
      final p1 = Place(id: 'rabat-agdal', city: 'Rabat', area: 'Agdal');
      final p2 = Place(id: 'rabat-hayriad', city: 'Rabat', area: 'Hay Riad');
      final p3 = Place(id: 'fes-routeimm', city: 'Fes', area: 'Route Imouzzer');

      await placeService.upsertPlace(p1);
      await placeService.upsertPlace(p2);
      await placeService.upsertPlace(p3);

      // Stadiums
      await stadiumService.upsertStadium(Stadium(
        id: 'stade-agdal-1',
        name: 'Stade Agdal 1',
        placeId: p1.id,
        city: p1.city,
        area: p1.area,
        address: 'Agdal, Rabat',
        pricePerHour: 100,
        hasLights: true,
        images: const [],
        createdAt: DateTime.now(),
      ));

      await stadiumService.upsertStadium(Stadium(
        id: 'stade-hayriad-1',
        name: 'Terrain Hay Riad',
        placeId: p2.id,
        city: p2.city,
        area: p2.area,
        address: 'Hay Riad, Rabat',
        pricePerHour: 100,
        hasLights: true,
        images: const [],
        createdAt: DateTime.now(),
      ));

      await stadiumService.upsertStadium(Stadium(
        id: 'stade-fes-1',
        name: 'Terrain Route Imouzzer',
        placeId: p3.id,
        city: p3.city,
        area: p3.area,
        address: 'Fes - Route Imouzzer',
        pricePerHour: 100,
        hasLights: true,
        images: const [],
        createdAt: DateTime.now(),
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seed done ✅')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seed data')),
      body: Center(
        child: FilledButton(
          onPressed: seed,
          child: const Text('Insert sample Places + Stadiums'),
        ),
      ),
    );
  }
}

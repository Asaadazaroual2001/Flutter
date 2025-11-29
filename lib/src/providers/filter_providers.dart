import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Text entered in the search bar.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Difficulty filter: 'Easy', 'Medium', 'Hard', or null for no filter.
final difficultyFilterProvider = StateProvider<String?>((ref) => null);

/// Max prep time (in minutes). Example: 30 or null for no limit.
final maxPrepTimeFilterProvider = StateProvider<int?>((ref) => null);

final categoryFilterProvider = StateProvider<String?>((ref) => null);

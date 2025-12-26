import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/match_announcement.dart';
import '../../models/stadium.dart';
import '../../providers/auth_providers.dart';
import '../../providers/match_providers.dart';
import '../../providers/stadium_providers.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  static const routeName = '/create-match';

  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();

  // بدل manual stadium/city/area
  String? _stadiumId;
  Stadium? _selectedStadium;

  final _notes = TextEditingController();
  final _players = TextEditingController(text: '10');

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  int _duration = 60;

  final Set<String> _positions = {'Any'};

  @override
  void dispose() {
    _notes.dispose();
    _players.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  DateTime _startAt() {
    return DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (_selectedStadium == null) return;

    final service = ref.read(matchServiceProvider);

    final totalPlayers = int.tryParse(_players.text.trim()) ?? 10;

    final s = _selectedStadium!;

    final match = MatchAnnouncement(
      id: '',
      organizerId: user.uid,
      stadiumId: s.id,
      stadiumName: s.name,
      city: s.city,
      area: s.area,
      startAt: _startAt(),
      durationMin: _duration,
      totalPlayersNeeded: totalPlayers,
      acceptedCount: 0,
      positionsNeeded: _positions.toList(),
      notes: _notes.text.trim(),
      status: 'OPEN',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await service.createMatch(match);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final posOptions = const ['Any', 'GK', 'DF', 'MF', 'FW'];
    final stadiumsAsync = ref.watch(stadiumsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create match')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ✅ Stadium Dropdown
              stadiumsAsync.when(
                data: (stadiums) {
                  if (stadiums.isEmpty) {
                    return const Text(
                      "No stadiums found. Add some stadiums (seed) first.",
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _stadiumId,
                    items: stadiums
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text("${s.name} (${s.city} - ${s.area})"),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _stadiumId = v;
                        _selectedStadium =
                            stadiums.firstWhere((x) => x.id == v);
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Choose stadium'),
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text("Error loading stadiums: $e"),
              ),

              const SizedBox(height: 10),

              // ✅ عرض City/Area auto (غير read-only)
              if (_selectedStadium != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("City: ${_selectedStadium!.city}"),
                        ),
                        Expanded(
                          child: Text("Area: ${_selectedStadium!.area}"),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text("${_date.day}/${_date.month}/${_date.year}"),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        "${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}",
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _duration,
                items: const [
                  DropdownMenuItem(value: 60, child: Text('60 min')),
                  DropdownMenuItem(value: 90, child: Text('90 min')),
                  DropdownMenuItem(value: 120, child: Text('120 min')),
                ],
                onChanged: (v) => setState(() => _duration = v ?? 60),
                decoration: const InputDecoration(labelText: 'Duration'),
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: _players,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total players needed (e.g. 10/11/14)',
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 2 || n > 22) {
                    return 'Enter a number 2..22';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),
              const Text(
                "Positions needed",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: posOptions.map((p) {
                  final selected = _positions.contains(p);
                  return FilterChip(
                    label: Text(p),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _positions.add(p);
                        } else {
                          if (_positions.length > 1) _positions.remove(p);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Example: bring shoes / time strict / level...',
                ),
              ),

              const SizedBox(height: 18),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Publish match'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

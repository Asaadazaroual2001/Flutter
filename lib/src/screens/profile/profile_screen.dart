import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../services/image_service.dart';

class ProfileScreen extends ConsumerWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  int _calcAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    final hadBirthdayThisYear =
        (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);

    if (!hadBirthdayThisYear) age--;
    return age;
  }

  Future<void> _editExtraInfo({
    required BuildContext context,
    required WidgetRef ref,
    required String uid,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Read existing values (if any)
    final snap = await userRef.get();
    final data = snap.data() ?? {};

    final cityCtrl = TextEditingController(
      text: (data['city'] as String?) ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: (data['phone'] as String?) ?? '',
    );

    DateTime? birthDate;
    final bd = data['birthDate'];
    if (bd is Timestamp) birthDate = bd.toDate();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add info'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Birth date
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        birthDate == null
                            ? 'Birth date: —'
                            : 'Birth date: ${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cake_outlined),
                      label: const Text('Pick birth date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: birthDate ?? DateTime(2001, 1, 1),
                          firstDate: DateTime(1950, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => birthDate = picked);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'City required';
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: 'Ex: 06xxxxxxxx أو +2126xxxxxxx',
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Phone required';
                        final ok = RegExp(r'^\+?\d{9,15}$').hasMatch(s);
                        if (!ok) return 'Invalid phone';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    if (birthDate == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Pick birth date first')),
                      );
                      return;
                    }

                    final age = _calcAge(birthDate!);

                    await userRef.set({
                      'birthDate': Timestamp.fromDate(birthDate!),
                      'age': age,
                      'city': cityCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    ref.invalidate(appUserProvider);

                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Info updated')),
                      );
                    }

                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    cityCtrl.dispose();
    phoneCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = ref.watch(currentUserProvider);
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: appUserAsync.when(
        data: (appUser) {
          if (firebaseUser == null || appUser == null) {
            return const Center(child: Text('No user data'));
          }

          final hasPhoto = appUser.photoUrl.isNotEmpty;

          final initials =
              (appUser.displayName.isNotEmpty
                      ? appUser.displayName[0]
                      : (appUser.email.isNotEmpty ? appUser.email[0] : '?'))
                  .toUpperCase();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ---------- HEADER ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _changePhoto(
                            context: context,
                            ref: ref,
                            userId: firebaseUser.uid,
                            existingPhotoUrl: appUser.photoUrl,
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundImage: hasPhoto
                                    ? NetworkImage(appUser.photoUrl)
                                    : null,
                                backgroundColor: hasPhoto
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                child: hasPhoto
                                    ? null
                                    : Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the photo to change it',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appUser.displayName.isNotEmpty
                              ? appUser.displayName
                              : 'No display name',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Account details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Display name'),
                          subtitle: Text(
                            appUser.displayName.isNotEmpty
                                ? appUser.displayName
                                : 'Not set',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editDisplayName(
                              context: context,
                              ref: ref,
                              userId: firebaseUser.uid,
                              currentName: appUser.displayName,
                            ),
                          ),
                        ),
                        const Divider(height: 0),

                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email'),
                          subtitle: Text(appUser.email),
                        ),
                        const Divider(height: 0),

                        // ✅ BUTTON / TILE Add info
                        ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: const Text('Add info'),
                          subtitle: const Text('Birth date • City • Phone'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _editExtraInfo(
                            context: context,
                            ref: ref,
                            uid: firebaseUser.uid,
                          ),
                        ),
                        const Divider(height: 0),

                        ListTile(
                          leading: const Icon(Icons.favorite_outline),
                          title: const Text('Favorites'),
                          subtitle: Text(
                            '${appUser.favorites.length} recipes saved',
                          ),
                        ),
                        const Divider(height: 0),

                        ListTile(
                          leading: const Icon(Icons.fingerprint),
                          title: const Text('User ID'),
                          subtitle: Text(firebaseUser.uid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ========= CHANGE PROFILE PHOTO =========
  Future<void> _changePhoto({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String existingPhotoUrl,
  }) async {
    final imageService = ImageService();

    final File? picked = await imageService.pickImageFromGallery();
    if (picked == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String newUrl = await imageService.uploadRecipeImage(picked);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoUrl': newUrl,
      });

      ref.invalidate(appUserProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
      }
    } finally {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  // ========= EDIT DISPLAY NAME =========
  Future<void> _editDisplayName({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Edit display name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogCtx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || newName == currentName) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'displayName': newName,
      });

      ref.invalidate(appUserProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Display name updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update display name: $e')),
        );
      }
    } finally {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }
}

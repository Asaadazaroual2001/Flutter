import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../services/image_service.dart';

class ProfileScreen extends ConsumerWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = ref.watch(currentUserProvider);
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: appUserAsync.when(
        data: (appUser) {
          if (firebaseUser == null || appUser == null) {
            return const Center(
              child: Text('No user data'),
            );
          }

          final hasPhoto = appUser.photoUrl.isNotEmpty;

          final initials = (appUser.displayName.isNotEmpty
                  ? appUser.displayName[0]
                  : (appUser.email.isNotEmpty ? appUser.email[0] : '?'))
              .toUpperCase();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ---------- HEADER AVEC PHOTO + NOM ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Avatar utilisateur + bouton de modification
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
                                backgroundImage:
                                    hasPhoto ? NetworkImage(appUser.photoUrl) : null,
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appUser.displayName.isNotEmpty
                              ? appUser.displayName
                              : 'No display name',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        // 🔹 Email supprimé du header comme demandé
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- INFOS DÉTAILLÉES ----------
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
                        // 🔹 Display name en premier
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
                        // 🔹 Email ensuite
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email'),
                          subtitle: Text(appUser.email),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.favorite_outline),
                          title: const Text('Favorites'),
                          subtitle:
                              Text('${appUser.favorites.length} recipes saved'),
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

    // 1) Choisir une image dans la galerie
    final File? picked = await imageService.pickImageFromGallery();
    if (picked == null) return;

    // 2) Afficher un loader pendant l'upload
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // 3) Upload sur Cloudinary (via ImageService)
      final String newUrl = await imageService.uploadRecipeImage(picked);

      // 4) Mettre à jour Firestore (users/{uid}.photoUrl)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'photoUrl': newUrl});

      // 5) Forcer le refresh des données utilisateur
      ref.invalidate(appUserProvider);

      // 6) Snackbar de succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    } finally {
      // Fermer le loader
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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

    // 1) Dialog pour saisir le nouveau nom
    final String? newName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Edit display name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Display name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(dialogCtx).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    // Si annulé ou vide ou identique, on ne fait rien
    if (newName == null || newName.isEmpty || newName == currentName) {
      return;
    }

    // 2) Loader pendant la mise à jour
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // 3) Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'displayName': newName});

      // 4) Refresh des données utilisateur
      ref.invalidate(appUserProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update display name')),
        );
      }
    } finally {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}

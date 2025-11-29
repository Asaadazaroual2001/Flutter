import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../../models/comment.dart';
import '../../providers/auth_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../services/pdf_service.dart';
import '../recipe/edit_recipe_screen.dart';

import 'package:http/http.dart' as http;

class RecipeDetailScreenArgs {
  final String recipeId;

  RecipeDetailScreenArgs({required this.recipeId});
}

class RecipeDetailScreen extends ConsumerWidget {
  static const routeName = '/recipe-detail';

  final RecipeDetailScreenArgs args;

  const RecipeDetailScreen({super.key, required this.args});

  // ✅ NEW: helper to show full-screen image preview
  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeByIdProvider(args.recipeId));
    final commentsAsync = ref.watch(commentsProvider(args.recipeId));
    final user = ref.watch(currentUserProvider);
    final appUser = ref.watch(appUserProvider).asData?.value;
    final isFavorite = appUser?.favorites.contains(args.recipeId) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Detail'),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: user == null
                ? null
                : () async {
                    final auth = ref.read(authServiceProvider);
                    await auth.toggleFavorite(
                      userId: user.uid,
                      recipeId: args.recipeId,
                      isFavorite: isFavorite,
                    );
                  },
          ),
          // ---------- SHARE PDF ----------
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final recipe = recipeAsync.asData?.value;
              if (recipe == null) return;

              Uint8List? bytes;
              if (recipe.imageUrl.isNotEmpty) {
                try {
                  bytes = await networkImageToByte(
                    recipe.imageUrl,
                  );
                } catch (_) {}
              }

              final pdfService = PdfService();
              await pdfService.shareRecipePdf(
                recipe: recipe,
                authorName: appUser?.displayName ?? 'Unknown',
                imageBytes: bytes,
              );
            },
          ),
          // ---------- DOWNLOAD / SAVE PDF ----------
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final recipe = recipeAsync.asData?.value;
              if (recipe == null) return;

              Uint8List? bytes;
              if (recipe.imageUrl.isNotEmpty) {
                try {
                  bytes = await networkImageToByte(
                    recipe.imageUrl,
                  );
                } catch (_) {}
              }

              try {
                final pdfService = PdfService();
                final path = await pdfService.saveRecipePdf(
                  recipe: recipe,
                  authorName: appUser?.displayName ?? 'Unknown',
                  imageBytes: bytes,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF saved to: $path'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save PDF: $e'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: recipeAsync.when(
        data: (recipe) {
          if (recipe == null) {
            return const Center(child: Text('Recipe not found'));
          }
          final canEdit = user != null && user.uid == recipe.authorId;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe.imageUrl.isNotEmpty)
                  // ✅ UPDATED: tap to open full-screen preview
                  GestureDetector(
                    onTap: () =>
                        _showImagePreview(context, recipe.imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: recipe.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // ######## NEW: owner profile + title ########
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(recipe.authorId)
                      .get(),
                  builder: (context, snapshot) {
                    String displayName = 'Unknown';
                    String? photoUrl;

                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      final data = snapshot.data!.data()!;
                      displayName = (data['displayName'] ??
                              data['name'] ??
                              data['username'] ??
                              'Unknown') as String;
                      final rawPhoto = data['photoUrl'] ?? data['imageUrl'];
                      if (rawPhoto is String && rawPhoto.isNotEmpty) {
                        photoUrl = rawPhoto;
                      }
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl!)
                              : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // ######## END NEW PART ########

                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text(recipe.category)),
                    const SizedBox(width: 8),
                    Chip(label: Text(recipe.difficulty)),
                    const SizedBox(width: 8),
                    Chip(label: Text('${recipe.prepTimeMin} min')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: recipe.avgRating,
                      itemCount: 5,
                      itemSize: 20,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${recipe.avgRating.toStringAsFixed(1)} '
                      '(${recipe.ratingsCount})',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(recipe.description),
                const SizedBox(height: 16),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                ...recipe.ingredients.map(
                  (i) => ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.circle, size: 8),
                    title: Text('${i.qty} - ${i.name}'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Steps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                ...recipe.steps.asMap().entries.map(
                      (e) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          child: Text('${e.key + 1}'),
                        ),
                        title: Text(e.value),
                      ),
                    ),
                const Divider(height: 32),
                _RatingSection(recipeId: recipe.id),
                const Divider(height: 32),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Text('No comments yet.');
                    }
                    return Column(
                      children: comments
                          .map((c) => _CommentTile(comment: c))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 8),
                if (user != null)
                  _AddCommentField(recipeId: recipe.id)
                else
                  const Text(
                    'Login to add comments.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 24),
                if (canEdit)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          EditRecipeScreen.routeName,
                          arguments: EditRecipeScreenArgs(recipe: recipe),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<Uint8List> networkImageToByte(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image from $url');
    }
  }
}

class _RatingSection extends ConsumerStatefulWidget {
  final String recipeId;

  const _RatingSection({required this.recipeId});

  @override
  ConsumerState<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<_RatingSection> {
  double _current = 3;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canRate = user != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate this recipe',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (!canRate)
          const Text('Login to add a rating.')
        else
          Row(
            children: [
              RatingBar.builder(
                initialRating: _current,
                minRating: 1,
                itemSize: 30,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (value) {
                  setState(() => _current = value);
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final service = ref.read(recipeServiceProvider);
                  await service.rateRecipe(
                    recipeId: widget.recipeId,
                    userId: user!.uid,
                    stars: _current.toInt(),
                  );
                },
                child: const Text('Submit'),
              ),
            ],
          ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    // Fetch the user document of the commenter
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(comment.userId)
          .get(),
      builder: (context, snapshot) {
        String displayName = 'User';
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          // adapt these keys to your User model if different
          displayName = (data['displayName'] ??
                  data['name'] ??
                  data['username'] ??
                  'User') as String;
          final rawPhoto = data['photoUrl'] ?? data['imageUrl'];
          if (rawPhoto is String && rawPhoto.isNotEmpty) {
            photoUrl = rawPhoto;
          }
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.text),
              const SizedBox(height: 2),
              Text(
                comment.createdAt.toLocal().toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddCommentField extends ConsumerStatefulWidget {
  final String recipeId;

  const _AddCommentField({required this.recipeId});

  @override
  ConsumerState<_AddCommentField> createState() =>
      _AddCommentFieldState();
}

class _AddCommentFieldState extends ConsumerState<_AddCommentField> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to comment.')),
        );
        return;
      }

      final service = ref.read(recipeServiceProvider);
      await service.addComment(
        recipeId: widget.recipeId,
        userId: user.uid,
        text: text,
      );

      _ctrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration:
                const InputDecoration(hintText: 'Write a comment...'),
          ),
        ),
        const SizedBox(width: 8),
        _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.send),
                onPressed: _submit,
              ),
      ],
    );
  }
}

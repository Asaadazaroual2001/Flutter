import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../../providers/auth_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../services/image_service.dart';
import '../../utils/validators.dart';

class EditRecipeScreenArgs {
  final Recipe? recipe;

  const EditRecipeScreenArgs({this.recipe});
}

class EditRecipeScreen extends ConsumerStatefulWidget {
  static const routeName = '/edit-recipe';

  final EditRecipeScreenArgs args;

  const EditRecipeScreen({super.key, required this.args});

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  String? _difficulty; // Dropdown value
  final _prepTimeCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController(); // multiline
  final _stepsCtrl = TextEditingController(); // multiline

  File? _pickedImage;
  String? _existingImage;

  // 🔽 NEW: fixed list of categories + selected value
  static const List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
  ];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    final recipe = widget.args.recipe;
    if (recipe != null) {
      _titleCtrl.text = recipe.title;
      _descriptionCtrl.text = recipe.description;
      _categoryCtrl.text = recipe.category;
      _difficulty = recipe.difficulty;

      // MULTILINE ingredients
      _ingredientsCtrl.text =
          recipe.ingredients.map((e) => "${e.name}:${e.qty}").join("\n");

      // MULTILINE steps
      _stepsCtrl.text = recipe.steps.join("\n");

      _prepTimeCtrl.text = recipe.prepTimeMin.toString();
      _existingImage = recipe.imageUrl;

      // 🔽 NEW: initialize dropdown value from existing recipe
      if (recipe.category.isNotEmpty) {
        _selectedCategory = recipe.category;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _prepTimeCtrl.dispose();
    _ingredientsCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImageService().pickImageFromGallery();
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      // ------------ PARSE MULTILINE INGREDIENTS ------------
      final ingredients = _ingredientsCtrl.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) {
        final parts = line.split(':');
        return Ingredient(
          name: parts[0].trim(),
          qty: parts.length > 1 ? parts[1].trim() : '',
        );
      }).toList();

      // ------------ PARSE MULTILINE STEPS ------------
      final steps = _stepsCtrl.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      // ------------ IMAGE UPLOAD ------------
      String imageUrl = _existingImage ?? "";

      if (_pickedImage != null) {
        final imageService = ImageService();

        // ✅ Your ImageService takes only the File argument
        imageUrl = await imageService.uploadRecipeImage(_pickedImage!);
      }

      final now = DateTime.now();
      final old = widget.args.recipe;

      final recipe = Recipe(
        id: old?.id ?? "",
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        authorId: old?.authorId ?? user.uid,
        // 🔽 UPDATED: use selected category from dropdown
        category: _selectedCategory ?? _categoryCtrl.text.trim(),
        difficulty: _difficulty ?? "Easy",
        prepTimeMin: int.tryParse(_prepTimeCtrl.text.trim()) ?? 0,
        ingredients: ingredients,
        steps: steps,
        imageUrl: imageUrl,
        avgRating: old?.avgRating ?? 0,
        ratingsCount: old?.ratingsCount ?? 0,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      );

      final service = ref.read(recipeServiceProvider);

      if (old == null) {
        await service.createRecipe(recipe);
      } else {
        await service.updateRecipe(recipe);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recipe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteRecipe() async {
    final old = widget.args.recipe;
    if (old == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe'),
        content: const Text(
          'Are you sure you want to delete this recipe? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final service = ref.read(recipeServiceProvider);
      await service.deleteRecipe(old.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete recipe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.args.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Recipe" : "Add Recipe"),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _loading ? null : _deleteRecipe,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ----------------- IMAGE -----------------
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.grey[200],
                  ),
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : (_existingImage != null && _existingImage!.isNotEmpty)
                          ? Image.network(_existingImage!, fit: BoxFit.cover)
                          : const Center(child: Text("Tap to select image")),
                ),
              ),
              const SizedBox(height: 16),

              // ---------------- TITLE ----------------
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
                validator: Validators.required,
              ),
              const SizedBox(height: 12),

              // ---------------- DESCRIPTION ----------------
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description"),
                validator: Validators.required,
              ),
              const SizedBox(height: 12),

              // ---------------- CATEGORY (DROPDOWN) ----------------
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: "Category"),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _categoryCtrl.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select a category";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ---------------- DIFFICULTY DROPDOWN ----------------
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: const InputDecoration(labelText: "Difficulty"),
                items: const [
                  DropdownMenuItem(value: "Easy", child: Text("Easy")),
                  DropdownMenuItem(value: "Medium", child: Text("Medium")),
                  DropdownMenuItem(value: "Hard", child: Text("Hard")),
                ],
                onChanged: (value) => setState(() => _difficulty = value),
                validator: (v) =>
                    v == null ? "Please select difficulty" : null,
              ),
              const SizedBox(height: 12),

              // ---------------- PREP TIME ----------------
              TextFormField(
                controller: _prepTimeCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Prep Time (minutes)"),
                validator: Validators.required,
              ),
              const SizedBox(height: 12),

              // ---------------- INGREDIENTS (MULTILINE) ----------------
              TextFormField(
                controller: _ingredientsCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: "Ingredients (one per line: name:qty)",
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 12),

              // ---------------- STEPS (MULTILINE) ----------------
              TextFormField(
                controller: _stepsCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: "Steps (one per line)",
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 20),

              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveRecipe,
                      child:
                          Text(isEdit ? "Save Changes" : "Create Recipe"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

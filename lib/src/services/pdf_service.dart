import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Colors;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/recipe.dart';

class PdfService {
  Future<Uint8List> buildRecipePdf({
    required Recipe recipe,
    required String authorName,
    Uint8List? imageBytes,
  }) async {
    final pdf = pw.Document();

    final image = imageBytes != null ? pw.MemoryImage(imageBytes) : null;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          pw.Text(
            recipe.title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Category: ${recipe.category}'),
              pw.Text('Difficulty: ${recipe.difficulty}'),
              pw.Text('Prep: ${recipe.prepTimeMin} min'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Author: $authorName'),
          pw.SizedBox(height: 4),
          pw.Text(
            'Average Rating: ${recipe.avgRating.toStringAsFixed(1)} '
            '(${recipe.ratingsCount} ratings)',
          ),
          pw.SizedBox(height: 16),
          if (image != null)
            pw.Center(
              child: pw.Container(
                height: 200,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(image, fit: pw.BoxFit.cover),
                ),
              ),
            ),
          if (image != null) pw.SizedBox(height: 16),
          pw.Text(
            'Description',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(recipe.description),
          pw.SizedBox(height: 16),
          pw.Text(
            'Ingredients',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: recipe.ingredients
                .map(
                  (i) => pw.Bullet(
                    text: '${i.qty} - ${i.name}',
                  ),
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Steps',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < recipe.steps.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('${i + 1}. ${recipe.steps[i]}'),
                ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> shareRecipePdf({
    required Recipe recipe,
    required String authorName,
    Uint8List? imageBytes,
  }) async {
    final data = await buildRecipePdf(
      recipe: recipe,
      authorName: authorName,
      imageBytes: imageBytes,
    );

    await Printing.sharePdf(
      bytes: data,
      filename: '${recipe.title}.pdf',
    );
  }

  // ---------- SAVE / DOWNLOAD PDF LOCALLY ----------
  Future<String> saveRecipePdf({
    required Recipe recipe,
    required String authorName,
    Uint8List? imageBytes,
  }) async {
    final data = await buildRecipePdf(
      recipe: recipe,
      authorName: authorName,
      imageBytes: imageBytes,
    );

    final dir = await _getSaveDirectory();

    final sanitizedName = _sanitizeFileName('${recipe.title}.pdf');
    final file = File('${dir.path}/$sanitizedName');

    await file.writeAsBytes(data);

    return file.path;
  }

  /// ANDROID:
  ///   -> /storage/emulated/0/Download
  ///
  /// OTHER:
  ///   -> application documents directory
  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      try {
        final dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      } catch (_) {
        // fall through to default below if something goes wrong
      }
    }

    // iOS or fallback
    return await getApplicationDocumentsDirectory();
  }

  String _sanitizeFileName(String name) {
    final forbidden = RegExp(r'[\\/:*?"<>|]');
    return name.replaceAll(forbidden, '_');
  }
}

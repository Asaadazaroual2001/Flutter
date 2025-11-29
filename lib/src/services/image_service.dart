import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class ImageService {
  final ImagePicker _picker;

  // 🔹 Your Cloudinary config
  static const String cloudName = "dqbaatkzq";      // ✅ your value
  static const String uploadPreset = "flutter_uploads"; // ✅ your preset name

  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<File?> pickImageFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Uploads an image file to Cloudinary and returns the public URL.
  Future<String> uploadRecipeImage(File file) async {
    final mimeType = lookupMimeType(file.path)?.split('/') ?? ['image', 'jpeg'];

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType(mimeType[0], mimeType[1]),
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Cloudinary upload failed (${response.statusCode}): $body");
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null) {
      throw Exception("Cloudinary response missing secure_url: $body");
    }

    return secureUrl;
  }
}

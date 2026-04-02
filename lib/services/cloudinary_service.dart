import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/url_utils.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  CloudinaryUploadResult({required this.secureUrl, required this.publicId});
}

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  Future<CloudinaryUploadResult> uploadImage(File file) async {
    final cloudName = AppConfig.cloudinaryCloudName;
    final preset = AppConfig.cloudinaryUploadPreset;

    if (cloudName.isEmpty || preset.isEmpty) {
      throw Exception(
        'Cloudinary config missing. Set CLOUDINARY_CLOUD_NAME & CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    // Cloudinary Upload API endpoint format:
    // https://api.cloudinary.com/v1_1/<cloud_name>/image/upload :contentReference[oaicite:9]{index=9}
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..fields['folder'] = AppConfig.cloudinaryFolder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed: ${res.statusCode} ${res.body}',
      );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final secureUrl = UrlUtils.normalizeMediaUrl(((data['secure_url'] ?? data['url'] ?? '') as String));
    final publicId = (data['public_id'] ?? '') as String;

    if (secureUrl.isEmpty) throw Exception('Cloudinary: secure_url missing.');
    return CloudinaryUploadResult(secureUrl: secureUrl, publicId: publicId);
  }
}

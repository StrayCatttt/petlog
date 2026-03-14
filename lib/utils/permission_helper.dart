import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// ギャラリー権限をリクエストし、許可されたら true を返す
Future<bool> requestGalleryPermission(BuildContext context) async {
  // Android 13以上は READ_MEDIA_IMAGES、以下は READ_EXTERNAL_STORAGE
  final status = await Permission.photos.request();

  if (status.isGranted) return true;

  if (status.isPermanentlyDenied && context.mounted) {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('写真へのアクセスが必要です'),
        content: const Text('設定アプリから「ペットログ」の写真アクセスを許可してください。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); openAppSettings(); },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }
  return false;
}

/// カメラ権限をリクエストし、許可されたら true を返す
Future<bool> requestCameraPermission(BuildContext context) async {
  final status = await Permission.camera.request();
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied && context.mounted) {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('カメラへのアクセスが必要です'),
        content: const Text('設定アプリから「ペットログ」のカメラアクセスを許可してください。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); openAppSettings(); },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }
  return false;
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import '../repositories/app_provider.dart';

/// ウィジェットのデータをAndroid側に送る
/// home_widget パッケージ経由でSharedPreferences互換のデータを共有
class WidgetHelper {
  static const _appGroupId = 'com.petlog.app';

  /// 写真ウィジェット用：最新の写真パスとペット名を送信
  static Future<void> updatePhotoWidget(AppProvider provider) async {
    try {
      final pet = provider.activePet;
      if (pet == null) return;

      final latestEntry = await provider.getLatestEntry();
      final photoPath = latestEntry?.photoUris.isNotEmpty == true
          ? latestEntry!.photoUris.first
          : pet.profilePhotoPath ?? '';

      await HomeWidget.saveWidgetData<String>('widget_pet_name', pet.name);
      await HomeWidget.saveWidgetData<String>('widget_pet_emoji', pet.species.emoji);
      await HomeWidget.saveWidgetData<String>('widget_photo_path', photoPath);
      await HomeWidget.updateWidget(
        androidName: 'PetPhotoWidget',
        qualifiedAndroidName: 'com.petlog.app.widget.PetPhotoWidget',
      );
    } catch (e) {
      debugPrint('widget update error: $e');
    }
  }

  /// カウントウィジェット用：ペット名・日数・絵文字を送信
  static Future<void> updateCountWidget(AppProvider provider) async {
    try {
      final pet = provider.activePet;
      if (pet == null) return;

      await HomeWidget.saveWidgetData<String>('count_pet_name', pet.name);
      await HomeWidget.saveWidgetData<String>('count_pet_emoji', pet.species.emoji);
      await HomeWidget.saveWidgetData<int>('count_days', pet.daysFromWelcome);
      await HomeWidget.saveWidgetData<String>('count_age', pet.ageString);
      await HomeWidget.updateWidget(
        androidName: 'PetCountWidget',
        qualifiedAndroidName: 'com.petlog.app.widget.PetCountWidget',
      );
    } catch (e) {
      debugPrint('count widget update error: $e');
    }
  }
}

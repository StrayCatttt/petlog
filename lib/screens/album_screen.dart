import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/ad_helper.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // 日記エントリーから写真を全部集める
    final allPhotos = provider.diaryEntries
        .expand((e) => e.photoUris)
        .where((uri) => uri.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        const SliverAppBar(
          title: Text('📷 フォトアルバム', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFFBF0DE), floating: true,
        ),
        if (allPhotos.isEmpty)
          const SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('📷', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('日記に写真を追加すると\nここに表示されます', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
          ])))
        else
          SliverPadding(
            padding: const EdgeInsets.all(3),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _PhotoCell(path: allPhotos[i]),
                childCount: allPhotos.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3,
              ),
            ),
          ),
        if (!provider.isPro)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: BannerAdWidget()))),
      ]),
    );
  }
}

class _PhotoCell extends StatelessWidget {
  final String path;
  const _PhotoCell({required this.path});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: Image.file(File(path), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.caramelPale)),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
    )));
  }
}

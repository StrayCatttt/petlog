import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/ad_helper.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});
  @override Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allMedia = provider.diaryEntries.expand((e) => e.photoUris).where((u) => u.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        const SliverAppBar(title: Text('📷 フォトアルバム', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFFFBF0DE), floating: true),
        if (allMedia.isEmpty)
          const SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('📷', style: TextStyle(fontSize: 56)), SizedBox(height: 12),
            Text('日記に写真・動画を追加すると\nここに表示されます', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
          ])))
        else
          SliverPadding(padding: const EdgeInsets.all(3), sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _MediaCell(allMedia: allMedia, index: i),
              childCount: allMedia.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
          )),
        if (!provider.isPro) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: BannerAdWidget()))),
      ]),
    );
  }
}

class _MediaCell extends StatelessWidget {
  final List<String> allMedia; final int index;
  const _MediaCell({required this.allMedia, required this.index});
  bool get _isVideo { final u = allMedia[index]; return u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.avi'); }
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _MediaViewer(media: allMedia, initialIndex: index))),
    child: Stack(fit: StackFit.expand, children: [
      _isVideo
          ? Container(color: Colors.black87, child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)))
          : Image.file(File(allMedia[index]), fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: AppColors.caramelPale)),
      if (_isVideo) Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.videocam, color: Colors.white, size: 14))),
    ]),
  );
}

// フルスクリーン＋スワイプビューア
class _MediaViewer extends StatefulWidget {
  final List<String> media; final int initialIndex;
  const _MediaViewer({required this.media, required this.initialIndex});
  @override State<_MediaViewer> createState() => _MediaViewerState();
}
class _MediaViewerState extends State<_MediaViewer> {
  late PageController _ctrl;
  late int _current;
  @override void initState() { super.initState(); _current = widget.initialIndex; _ctrl = PageController(initialPage: widget.initialIndex); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  bool _isVideo(String u) => u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.avi');
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white,
      title: Text('${_current + 1} / ${widget.media.length}', style: const TextStyle(color: Colors.white))),
    body: PageView.builder(
      controller: _ctrl, itemCount: widget.media.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (ctx, i) {
        final path = widget.media[i];
        if (_isVideo(path)) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.play_circle_fill, color: Colors.white70, size: 80),
            const SizedBox(height: 12),
            Text(path.split('/').last, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]));
        }
        return InteractiveViewer(child: Center(child: Image.file(File(path),
          errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 80)))));
      },
    ),
  );
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/ad_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DiaryEntry? _latestEntry;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    rewardAdManager.loadAd();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLatest());
  }

  Future<void> _loadLatest() async {
    final e = await context.read<AppProvider>().getLatestEntry();
    if (mounted) setState(() => _latestEntry = e);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadLatest,
        color: AppColors.caramel,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader(provider)),
          const SliverToBoxAdapter(child: SectionTitle(title: '✨ きょうのおもいで')),
          SliverToBoxAdapter(child: _buildMemoryCard(provider)),
          if (!provider.isPro)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: PhotoQuotaBar(
                  used: provider.quotaUsed, total: provider.quotaTotal,
                  rewardWatched: provider.rewardWatched,
                  onRewardTap: () async {
                    final rewarded = await rewardAdManager.show(context);
                    if (rewarded && mounted) provider.applyRewardBonus();
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SectionTitle(title: '📅 カレンダー')),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildCalendar(provider))),
          if (!provider.isPro)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: BannerAdWidget()))),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFBF0DE), AppColors.background])),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('🐾 ぺちろぐ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.caramel)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppColors.caramel, borderRadius: BorderRadius.circular(20)),
            child: Text(DateFormat('M月d日（E）','ja').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 76, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: provider.activePets.length + (provider.isPro || provider.activePets.isEmpty ? 1 : 0),
          separatorBuilder: (_,__) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) {
            if (i == provider.activePets.length) return _buildAddPetButton();
            final pet = provider.activePets[i];
            return _PetAvatar(pet: pet, isActive: i == provider.activePetIndex, onTap: () => provider.setActivePet(i));
          },
        )),
      ]),
    );
  }

  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddPetSheet()),
      child: Column(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.caramelLight, width: 2)),
          child: const Center(child: Text('＋', style: TextStyle(fontSize: 22, color: AppColors.caramelLight)))),
        const SizedBox(height: 4),
        const Text('追加', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
    );
  }

  Widget _buildMemoryCard(AppProvider provider) {
    final entry = _latestEntry;
    // 最新エントリーの最初のメディア（動画or写真）
    final firstMedia = entry?.photoUris.isNotEmpty == true ? entry!.photoUris.first : null;
    final isVideo = firstMedia != null && (firstMedia.endsWith('.mp4') || firstMedia.endsWith('.mov') || firstMedia.endsWith('.avi'));

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 200, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Stack(fit: StackFit.expand, children: [
          // 背景：最新メディアまたはデフォルト
          firstMedia != null && !isVideo
              ? Image.file(File(firstMedia), fit: BoxFit.cover, errorBuilder: (_,__,___) => _defaultBg(provider))
              : _defaultBg(provider),
          if (isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 64)),
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.4,1.0], colors: [Colors.transparent, Color(0x80000000)]))),
          Positioned(left: 16, right: 16, bottom: 16,
            child: entry != null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📅 ${DateFormat('yyyy年M月d日').format(entry.date)}の記録', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(entry.body.isEmpty ? '（本文なし）' : entry.body.length > 40 ? '${entry.body.substring(0,40)}…' : entry.body,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ])
              : const Text('日記を書いてみよう 📝', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }

  Widget _defaultBg(AppProvider provider) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF5CBA7), Color(0xFFFDEBD0), Color(0xFFD5DBDB)])),
    child: Center(child: Text(provider.activePet?.species.emoji ?? '🐾', style: const TextStyle(fontSize: 72))));

  Widget _buildCalendar(AppProvider provider) {
    final diaryDates = provider.getDatesWithEntries();
    final scheduleDates = provider.getDatesWithSchedules();
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      child: TableCalendar(
        firstDay: DateTime(2020), lastDay: DateTime(2030),
        focusedDay: _focusedDay, selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        locale: 'ja',
        calendarStyle: CalendarStyle(
          // 今日は単純な円だけ
          todayDecoration: const BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle),
          todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(color: AppColors.caramel.withOpacity(0.3), shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
          markersMaxCount: 2, markerSize: 5, markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true, formatButtonVisible: false,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.caramel),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.caramel),
        ),
        onDaySelected: (selected, focused) {
          setState(() { _selectedDay = selected; _focusedDay = focused; });
          _onDayTapped(context, provider, selected);
        },
        onPageChanged: (d) => setState(() => _focusedDay = d),
        eventLoader: (day) {
          final d = DateTime(day.year, day.month, day.day);
          final events = [];
          if (diaryDates.contains(d)) events.add('diary');
          if (scheduleDates.contains(d)) events.add('schedule');
          return events;
        },
      ),
    );
  }

  Future<void> _onDayTapped(BuildContext context, AppProvider provider, DateTime day) async {
    final schedules = await provider.getSchedulesOnDay(day);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _DaySheet(day: day, schedules: schedules, provider: provider),
    );
  }
}

class _DaySheet extends StatelessWidget {
  final DateTime day; final List<PetSchedule> schedules; final AppProvider provider;
  const _DaySheet({required this.day, required this.schedules, required this.provider});

  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateFormat('M月d日（E）','ja').format(day), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ElevatedButton.icon(onPressed: () { Navigator.pop(context); _addSchedule(context); },
            icon: const Icon(Icons.add, size: 16), label: const Text('予定を追加'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramel, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
        ]),
        const SizedBox(height: 12),
        if (schedules.isEmpty) const Text('予定なし', style: TextStyle(color: AppColors.textLight))
        else ...schedules.map((s) => ListTile(
          leading: const Text('📌', style: TextStyle(fontSize: 20)),
          title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: s.note != null ? Text(s.note!, style: const TextStyle(fontSize: 11)) : null,
          trailing: IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () { Navigator.pop(context); provider.deleteSchedule(s.id!); }),
        )),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _addSchedule(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AddScheduleSheet(date: day));
  }
}

class _AddScheduleSheet extends StatefulWidget {
  final DateTime date;
  const _AddScheduleSheet({required this.date});
  @override State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _notify = true;
  @override Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📌 ${DateFormat('M月d日').format(widget.date)}の予定を追加', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'タイトル', hintText: '例：ワクチン接種', hintStyle: TextStyle(color: AppColors.textLight))),
        const SizedBox(height: 12),
        TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'メモ（任意）', hintText: '例：かかりつけ医 14:00〜', hintStyle: TextStyle(color: AppColors.textLight))),
        const SizedBox(height: 12),
        SwitchListTile(value: _notify, onChanged: (v) => setState(() => _notify = v),
          title: const Text('通知する', style: TextStyle(fontSize: 14)), contentPadding: EdgeInsets.zero,
          activeColor: AppColors.caramel),
        const SizedBox(height: 16),
        PetoButton(label: '✓ 追加する', onPressed: _titleCtrl.text.trim().isEmpty ? null : () async {
          await context.read<AppProvider>().addSchedule(PetSchedule(
            petId: context.read<AppProvider>().activePet?.id,
            date: widget.date, title: _titleCtrl.text.trim(),
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
            notifyEnabled: _notify, createdAt: DateTime.now()));
          if (mounted) Navigator.pop(context);
        }),
      ]),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final Pet pet; final bool isActive; final VoidCallback onTap;
  const _PetAvatar({required this.pet, required this.isActive, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Column(children: [
    Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.caramelPale, border: Border.all(color: isActive ? AppColors.goldRing : Colors.transparent, width: 2.5)),
      child: ClipOval(child: pet.profilePhotoPath != null
          ? Image.file(File(pet.profilePhotoPath!), fit: BoxFit.cover, errorBuilder: (_,__,___) => Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26))))
          : Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26))))),
    const SizedBox(height: 4),
    Text(pet.name, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.caramel : AppColors.textMid)),
  ]));
}

class _AddPetSheet extends StatefulWidget {
  const _AddPetSheet();
  @override State<_AddPetSheet> createState() => _AddPetSheetState();
}
class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  PetSpecies _species = PetSpecies.dog;
  @override Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🐾 ペットを追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 16),
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名前', hintText: '例：むぎ', hintStyle: TextStyle(color: AppColors.textLight)), onChanged: (_) => setState(() {})),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: PetSpecies.values.map((s) => ChoiceChip(label: Text('${s.emoji} ${s.label}'), selected: _species == s, onSelected: (_) => setState(() => _species = s), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
      const SizedBox(height: 20),
      PetoButton(label: '✓ 追加する', onPressed: _nameCtrl.text.trim().isEmpty ? null : () async {
        await context.read<AppProvider>().addPet(Pet(name: _nameCtrl.text.trim(), species: _species, createdAt: DateTime.now()));
        if (mounted) Navigator.pop(context);
      }),
    ])),
  );
}

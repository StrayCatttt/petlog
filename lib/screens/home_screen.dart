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
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DiaryEntry? _todayMemory;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    rewardAdManager.loadAd();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMemory());
  }

  Future<void> _loadMemory() async {
    final memory = await context.read<AppProvider>().getRandomMemory();
    if (mounted) setState(() => _todayMemory = memory);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadMemory,
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
                  used: provider.quotaUsed,
                  total: provider.quotaTotal,
                  rewardWatched: provider.rewardWatched,
                  onRewardTap: () async {
                    final rewarded = await rewardAdManager.show(context);
                    if (rewarded && mounted) provider.applyRewardBonus();
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SectionTitle(title: '📅 カレンダー',
              trailing: TextButton(onPressed: () {}, child: const Text('全て見る →', style: TextStyle(color: AppColors.caramel, fontSize: 12)))),
          ),
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
          const Text('🐾 ペットログ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.caramel)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppColors.caramel, borderRadius: BorderRadius.circular(20)),
            child: Text(DateFormat('M月d日（E）', 'ja').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.activePets.length + (provider.isPro || provider.activePets.isEmpty ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              if (i == provider.activePets.length) return _buildAddPetButton();
              final pet = provider.activePets[i];
              return _PetAvatar(pet: pet, isActive: i == provider.activePetIndex, onTap: () => provider.setActivePet(i));
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AddPetSheet()),
      child: Column(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.caramelLight, width: 2)), child: const Center(child: Text('＋', style: TextStyle(fontSize: 22, color: AppColors.caramelLight)))),
        const SizedBox(height: 4),
        const Text('追加', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
    );
  }

  Widget _buildMemoryCard(AppProvider provider) {
    final entry = _todayMemory;
    final firstPhoto = entry?.photoUris.isNotEmpty == true ? entry!.photoUris.first : null;
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 200, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Stack(fit: StackFit.expand, children: [
          firstPhoto != null
              ? Image.file(File(firstPhoto), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultBg(provider))
              : _defaultBg(provider),
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.4, 1.0], colors: [Colors.transparent, Color(0x80000000)]))),
          Positioned(left: 16, right: 16, bottom: 16,
            child: entry != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('📅 ${DateFormat('yyyy年M月d日').format(entry.date)}の記録', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 3),
                    Text(entry.body.isEmpty ? '（本文なし）' : entry.body.length > 40 ? '${entry.body.substring(0, 40)}…' : entry.body,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ])
                : const Text('日記を書いてみよう 📝', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }

  Widget _defaultBg(AppProvider provider) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF5CBA7), Color(0xFFFDEBD0), Color(0xFFD5DBDB)])),
      child: Center(child: Text(provider.activePet?.species.emoji ?? '🐾', style: const TextStyle(fontSize: 72))),
    );
  }

  Widget _buildCalendar(AppProvider provider) {
    final dates = provider.getDatesWithEntries();
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      child: TableCalendar(
        firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: _focusedDay, locale: 'ja',
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle),
          markersMaxCount: 1, markerSize: 5,
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true, formatButtonVisible: false,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.caramel),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.caramel),
        ),
        onPageChanged: (d) => setState(() => _focusedDay = d),
        eventLoader: (day) => dates.contains(DateTime(day.year, day.month, day.day)) ? [true] : [],
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final Pet pet; final bool isActive; final VoidCallback onTap;
  const _PetAvatar({required this.pet, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.caramelPale, border: Border.all(color: isActive ? AppColors.goldRing : Colors.transparent, width: 2.5)),
          child: ClipOval(child: pet.profilePhotoPath != null
              ? Image.file(File(pet.profilePhotoPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26))))
              : Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26)))),
        ),
        const SizedBox(height: 4),
        Text(pet.name, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.caramel : AppColors.textMid)),
      ]),
    );
  }
}

class _AddPetSheet extends StatefulWidget {
  const _AddPetSheet();
  @override
  State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  PetSpecies _species = PetSpecies.dog;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🐾 ペットを追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        const Text('名前', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: '例：むぎ'), onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        const Text('種類', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: PetSpecies.values.map((s) => ChoiceChip(
          label: Text('${s.emoji} ${s.label}'), selected: _species == s,
          onSelected: (_) => setState(() => _species = s),
          selectedColor: AppColors.caramel,
          labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12),
        )).toList()),
        const SizedBox(height: 20),
        PetoButton(
          label: '✓ 追加する',
          onPressed: _nameCtrl.text.trim().isEmpty ? null : () async {
            await context.read<AppProvider>().addPet(Pet(name: _nameCtrl.text.trim(), species: _species, createdAt: DateTime.now()));
            if (mounted) Navigator.pop(context);
          },
        ),
      ])),
    );
  }
}

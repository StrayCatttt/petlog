import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../repositories/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

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
    _loadMemory();
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
        child: CustomScrollView(
          slivers: [
            // ─── ヘッダー ──────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(provider)),

            // ─── きょうのおもいで ───────────────────────
            const SliverToBoxAdapter(child: SectionTitle(title: '✨ きょうのおもいで')),
            SliverToBoxAdapter(child: _buildMemoryCard()),

            // ─── 写真枠バー ────────────────────────────
            if (!provider.isPro)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: PhotoQuotaBar(
                    used: provider.quotaUsed,
                    total: provider.quotaTotal,
                    rewardWatched: provider.rewardWatched,
                    onRewardTap: () async {
                      final ok = await showRewardDialog(context);
                      if (ok && mounted) provider.applyRewardBonus();
                    },
                  ),
                ),
              ),

            // ─── カレンダー ────────────────────────────
            SliverToBoxAdapter(
              child: SectionTitle(
                title: '📅 カレンダー',
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('全て見る →', style: TextStyle(color: AppColors.caramel, fontSize: 12)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCalendar(provider),
              ),
            ),

            // ─── バナー広告 ────────────────────────────
            if (!provider.isPro)
              const SliverToBoxAdapter(child: BannerAdPlaceholder()),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBF0DE), AppColors.background],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🐾 ペットログ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.caramel)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppColors.caramel, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  DateFormat('M月d日（E）', 'ja').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ペット切り替えリスト
          if (provider.pets.isEmpty)
            _buildAddPetButton()
          else
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.pets.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  if (i == provider.pets.length) return _buildAddPetButton();
                  final pet = provider.pets[i];
                  final isActive = i == provider._activePetIndex;
                  return _PetAvatar(pet: pet, isActive: isActive, onTap: () => provider.setActivePet(i));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: () => _showAddPetDialog(),
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.caramelLight, width: 2),
            ),
            child: const Center(child: Text('＋', style: TextStyle(fontSize: 22, color: AppColors.caramelLight))),
          ),
          const SizedBox(height: 4),
          const Text('追加', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildMemoryCard() {
    final entry = _todayMemory;
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景
            entry != null && entry.photoUris.isNotEmpty
                ? Image.asset(entry.photoUris.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultMemoryBg())
                : _defaultMemoryBg(),
            // グラデーション
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 1.0],
                  colors: [Colors.transparent, Color(0x80000000)],
                ),
              ),
            ),
            // テキスト
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: entry != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 ${DateFormat('yyyy年M月d日').format(entry.date)}の記録',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.body.length > 40 ? '${entry.body.substring(0, 40)}…' : entry.body.isEmpty ? '（本文なし）' : entry.body,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : const Text('日記を書いてみよう 📝', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultMemoryBg() {
    final provider = context.read<AppProvider>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF5CBA7), Color(0xFFFDEBD0), Color(0xFFD5DBDB)]),
      ),
      child: Center(child: Text(provider.activePet?.species.emoji ?? '🐾', style: const TextStyle(fontSize: 72))),
    );
  }

  Widget _buildCalendar(AppProvider provider) {
    final dates = provider.getDatesWithEntries();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        locale: 'ja',
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: AppColors.caramelLight, shape: BoxShape.circle),
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle),
          markerSize: 5,
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.caramel),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.caramel),
        ),
        onPageChanged: (d) => setState(() => _focusedDay = d),
        eventLoader: (day) {
          final d = DateTime(day.year, day.month, day.day);
          return dates.contains(d) ? [true] : [];
        },
      ),
    );
  }

  void _showAddPetDialog() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _AddPetSheet());
  }
}

// ─── ペットアバター ────────────────────────────────────

class _PetAvatar extends StatelessWidget {
  final Pet pet;
  final bool isActive;
  final VoidCallback onTap;

  const _PetAvatar({required this.pet, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.caramelPale,
              border: Border.all(color: isActive ? AppColors.goldRing : Colors.transparent, width: 2.5),
            ),
            child: ClipOval(
              child: pet.profilePhotoPath != null
                  ? Image.asset(pet.profilePhotoPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26))))
                  : Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26))),
            ),
          ),
          const SizedBox(height: 4),
          Text(pet.name, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.caramel : AppColors.textMid)),
        ],
      ),
    );
  }
}

// ─── ペット追加シート ──────────────────────────────────

class _AddPetSheet extends StatefulWidget {
  const _AddPetSheet();

  @override
  State<_AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<_AddPetSheet> {
  final _nameCtrl = TextEditingController();
  PetSpecies _species = PetSpecies.dog;
  PetGender _gender = PetGender.unknown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐾 ペットを追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            const Text('名前', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: '例：むぎ'),
            ),
            const SizedBox(height: 16),
            const Text('種類', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: PetSpecies.values.map((s) => ChoiceChip(
                label: Text('${s.emoji} ${s.label}'),
                selected: _species == s,
                onSelected: (_) => setState(() => _species = s),
                selectedColor: AppColors.caramel,
                labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12),
              )).toList(),
            ),
            const SizedBox(height: 20),
            PetoButton(
              label: '✓ 追加する',
              onPressed: _nameCtrl.text.isEmpty ? null : () async {
                await context.read<AppProvider>().addPet(Pet(name: _nameCtrl.text.trim(), species: _species, gender: _gender, createdAt: DateTime.now()));
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

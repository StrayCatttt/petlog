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
                    if (rewarded && mounted) await provider.applyRewardBonus();
                  },
                ),
              ),
            ),
          // カレンダーヘッダー（右側に通知設定ボタン）
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const Expanded(child: Text('📅 カレンダー', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.caramel, size: 22),
                  tooltip: '通知設定',
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  onPressed: () => _showNotifSettings(context, provider),
                ),
              ]),
            ),
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
          // ✅ ぺとろぐ（正しい名前）
          const Text('🐾 ぺとろぐ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.caramel)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppColors.caramel, borderRadius: BorderRadius.circular(20)),
            child: Text(DateFormat('M月d日（E）','ja').format(DateTime.now()),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.activePets.length + (provider.isPro || provider.activePets.isEmpty ? 1 : 0),
            separatorBuilder: (_,__) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              if (i == provider.activePets.length) return _buildAddPetButton();
              final pet = provider.activePets[i];
              return _PetAvatar(
                pet: pet,
                isActive: i == provider.activePetIndex,
                onTap: () => provider.setActivePet(i),
                // ✅ 長押しで編集・削除
                onLongPress: () => _showPetOptions(context, provider, pet, i),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildAddPetButton() {
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => const _AddPetDialog()),
      child: Column(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.caramelLight, width: 2)),
          child: const Center(child: Text('＋', style: TextStyle(fontSize: 22, color: AppColors.caramelLight)))),
        const SizedBox(height: 4),
        const Text('追加', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
      ]),
    );
  }

  // ✅ ペットアイコン長押し: 編集・削除
  void _showPetOptions(BuildContext context, AppProvider provider, Pet pet, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${pet.species.emoji} ${pet.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit, color: AppColors.caramel), title: const Text('プロフィールを編集'), onTap: () {
            Navigator.pop(ctx);
            showDialog(context: context, builder: (_) => _EditPetDialog(pet: pet));
          }),
          ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('削除', style: TextStyle(color: Colors.red)), onTap: () {
            Navigator.pop(ctx);
            _confirmDeletePet(context, provider, pet);
          }),
        ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _confirmDeletePet(BuildContext context, AppProvider provider, Pet pet) {
    showDialog(context: context, builder: (d) => AlertDialog(
      title: Text('${pet.name}を削除しますか？'),
      content: const Text('このペットに関連する日記・支出データも全て削除されます。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('キャンセル')),
        ElevatedButton(onPressed: () { Navigator.pop(d); provider.deletePet(pet.id!); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('削除')),
      ],
    ));
  }

  Widget _buildMemoryCard(AppProvider provider) {
    final entry = _latestEntry;
    final firstMedia = entry?.photoUris.isNotEmpty == true ? entry!.photoUris.first : null;
    final isVideo = firstMedia != null && (firstMedia.endsWith('.mp4') || firstMedia.endsWith('.mov') || firstMedia.endsWith('.avi'));
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 200, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Stack(fit: StackFit.expand, children: [
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
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        locale: 'ja',
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(color: AppColors.caramel, shape: BoxShape.circle),
          todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(color: AppColors.caramel.withOpacity(0.25), shape: BoxShape.circle),
          // ✅ 予定がある日のマーカーをより目立たせる
          markerDecoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
          markersMaxCount: 3,
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        calendarBuilders: CalendarBuilders(
          // ✅ 予定がある日は背景に薄い色を付ける
          defaultBuilder: (ctx, day, focusedDay) {
            final d = DateTime(day.year, day.month, day.day);
            final hasSchedule = scheduleDates.contains(d);
            final hasDiary = diaryDates.contains(d);
            if (!hasSchedule && !hasDiary) return null;
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasSchedule ? AppColors.sagePale : Colors.transparent,
                border: hasDiary ? Border.all(color: AppColors.caramelLight, width: 1.5) : null,
              ),
              child: Center(child: Text('${day.day}', style: const TextStyle(fontSize: 14))),
            );
          },
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

  // ✅ カレンダー日付タップ → Dialog（画面中央）
  Future<void> _onDayTapped(BuildContext context, AppProvider provider, DateTime day) async {
    final schedules = await provider.getSchedulesOnDay(day);
    if (!mounted) return;
    // BottomSheetではなくDialogで中央に表示
    showDialog(
      context: context,
      builder: (_) => _DayDialog(day: day, schedules: schedules, provider: provider),
    );
  }

  // 通知設定（カレンダー右上のベルアイコンから）
  void _showNotifSettings(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => _NotifSettingsDialog(settings: provider.notifSettings),
    );
  }
}

// ✅ 日付タップ → Dialog（画面中央）
class _DayDialog extends StatelessWidget {
  final DateTime day; final List<PetSchedule> schedules; final AppProvider provider;
  const _DayDialog({required this.day, required this.schedules, required this.provider});

  @override Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(DateFormat('M月d日（E）','ja').format(day), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        IconButton(icon: const Icon(Icons.add_circle, color: AppColors.caramel, size: 28), padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          onPressed: () { Navigator.pop(context); showDialog(context: context, builder: (_) => _AddScheduleDialog(date: day)); }),
      ]),
      content: schedules.isEmpty
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('予定なし\n＋ボタンで予定を追加', style: TextStyle(color: AppColors.textLight), textAlign: TextAlign.center))
          : SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: schedules.map((s) => ListTile(
              leading: const Text('📌', style: TextStyle(fontSize: 20)),
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🕐 ${s.dateTime.hour.toString().padLeft(2,'0')}:${s.dateTime.minute.toString().padLeft(2,'0')}  ${s.notifyLabel}', style: const TextStyle(fontSize: 11, color: AppColors.caramel)),
                if (s.note != null) Text(s.note!, style: const TextStyle(fontSize: 11)),
              ]),
              trailing: IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () { Navigator.pop(context); provider.deleteSchedule(s.id!); }),
              dense: true,
            )).toList())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる', style: TextStyle(color: AppColors.textMid)))],
    );
  }
}

// ✅ 予定追加 → Dialog（時間必須・通知タイミング選択）
class _AddScheduleDialog extends StatefulWidget {
  final DateTime date;
  const _AddScheduleDialog({required this.date});
  @override State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}
class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  bool _notify = true;
  int _notifyMinutes = 30; // デフォルト30分前

  @override Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text('📌 ${DateFormat("M月d日").format(widget.date)}の予定', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'タイトル', hintText: '例：ワクチン接種', hintStyle: TextStyle(color: AppColors.textLight)), onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      // ✅ 時間選択（必須）
      Row(children: [
        const Text('時間（必須）：', style: TextStyle(fontSize: 13, color: AppColors.textMid)),
        TextButton(
          onPressed: () async {
            final t = await showTimePicker(context: context, initialTime: _time);
            if (t != null) setState(() => _time = t);
          },
          child: Text(
            '${_time.hour.toString().padLeft(2,"0")}:${_time.minute.toString().padLeft(2,"0")}',
            style: const TextStyle(color: AppColors.caramel, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ]),
      const SizedBox(height: 8),
      TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'メモ（任意）', hintText: '例：かかりつけ医', hintStyle: TextStyle(color: AppColors.textLight))),
      const SizedBox(height: 10),
      SwitchListTile(value: _notify, onChanged: (v) => setState(() => _notify = v),
        title: const Text('通知する', style: TextStyle(fontSize: 13)), activeColor: AppColors.caramel, contentPadding: EdgeInsets.zero, dense: true),
      if (_notify) ...[
        const Text('通知タイミング', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        Wrap(spacing: 6, children: [
          for (final entry in {0:"当日",10:"10分前",30:"30分前",60:"1時間前",360:"6時間前",720:"12時間前"}.entries)
            ChoiceChip(
              label: Text(entry.value, style: const TextStyle(fontSize: 11)),
              selected: _notifyMinutes == entry.key,
              onSelected: (_) => setState(() => _notifyMinutes = entry.key),
              selectedColor: AppColors.caramel,
              labelStyle: TextStyle(color: _notifyMinutes == entry.key ? Colors.white : AppColors.textMid),
            ),
        ]),
      ],
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid))),
      ElevatedButton(
        onPressed: _titleCtrl.text.trim().isEmpty ? null : () async {
          final dt = DateTime(widget.date.year, widget.date.month, widget.date.day, _time.hour, _time.minute);
          await context.read<AppProvider>().addSchedule(PetSchedule(
            petId: context.read<AppProvider>().activePet?.id,
            dateTime: dt, title: _titleCtrl.text.trim(),
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
            notifyEnabled: _notify, notifyMinutesBefore: _notifyMinutes,
            createdAt: DateTime.now()));
          if (mounted) Navigator.pop(context);
        },
        child: const Text('追加'),
      ),
    ],
  );
}

// ✅ 通知設定Dialog（画面中央）
class _NotifSettingsDialog extends StatefulWidget {
  final NotificationSettings settings;
  const _NotifSettingsDialog({required this.settings});
  @override State<_NotifSettingsDialog> createState() => _NotifSettingsDialogState();
}
class _NotifSettingsDialogState extends State<_NotifSettingsDialog> {
  late bool _vaccineReminder, _anniversaryNotify;
  late int _vaccineDays;
  late String _sound;

  late int _defaultNotifyMinutes;

  @override void initState() {
    super.initState();
    final s = widget.settings;
    _vaccineReminder = s.vaccineReminder; _vaccineDays = s.vaccineDaysBefore;
    _anniversaryNotify = s.anniversaryNotify; _sound = s.notifySound;
    _defaultNotifyMinutes = s.defaultNotifyMinutesBefore;
  }

  @override Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('🔔 通知設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ✅ 全般：デフォルト通知タイミング
      const Text('全般', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 4),
      const Text('予定のデフォルト通知タイミング', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
      Wrap(spacing: 6, children: [
        for (final entry in {0:"当日",10:"10分前",30:"30分前",60:"1時間前",360:"6時間前",720:"12時間前"}.entries)
          ChoiceChip(
            label: Text(entry.value, style: const TextStyle(fontSize: 11)),
            selected: _defaultNotifyMinutes == entry.key,
            onSelected: (_) => setState(() => _defaultNotifyMinutes = entry.key),
            selectedColor: AppColors.caramel,
            labelStyle: TextStyle(color: _defaultNotifyMinutes == entry.key ? Colors.white : AppColors.textMid),
          ),
      ]),
      const Divider(),
      SwitchListTile(value: _vaccineReminder, onChanged: (v) => setState(() => _vaccineReminder = v), activeColor: AppColors.caramel,
        title: const Text('ワクチン・健診リマインダー', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: const Text('予定の前に通知', style: TextStyle(fontSize: 11)), contentPadding: EdgeInsets.zero, dense: true),
      if (_vaccineReminder) Row(children: [
        const Text('何日前に通知：', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
        DropdownButton<int>(value: _vaccineDays, items: [1,3,7,14,30].map((d) => DropdownMenuItem(value: d, child: Text('$d日前'))).toList(), onChanged: (v) => setState(() => _vaccineDays = v!)),
      ]),
      const Divider(),
      SwitchListTile(value: _anniversaryNotify, onChanged: (v) => setState(() => _anniversaryNotify = v), activeColor: AppColors.caramel,
        title: const Text('お迎え記念日の通知', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), contentPadding: EdgeInsets.zero, dense: true),
      const Divider(),
      const Text('通知の方法', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ...["default","vibrate","silent"].map((s) => RadioListTile<String>(
        value: s, groupValue: _sound, onChanged: (v) => setState(() => _sound = v!),
        title: Text(s == "default" ? '🔊 サウンドあり' : s == "vibrate" ? '📳 バイブのみ' : '🔇 サイレント', style: const TextStyle(fontSize: 12)),
        activeColor: AppColors.caramel, contentPadding: EdgeInsets.zero, dense: true,
      )),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid))),
      ElevatedButton(onPressed: () async {
        final settings = NotificationSettings(
          vaccineReminder: _vaccineReminder, vaccineDaysBefore: _vaccineDays,
          anniversaryNotify: _anniversaryNotify, notifySound: _sound,
          defaultNotifyMinutesBefore: _defaultNotifyMinutes);
        await context.read<AppProvider>().saveNotifSettings(settings);
        if (mounted) Navigator.pop(context);
      }, child: const Text('保存')),
    ],
  );
}

// ─── ペットアバター（長押し対応）─────────────────────────

class _PetAvatar extends StatelessWidget {
  final Pet pet; final bool isActive; final VoidCallback onTap; final VoidCallback onLongPress;
  const _PetAvatar({required this.pet, required this.isActive, required this.onTap, required this.onLongPress});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, onLongPress: onLongPress,
    child: Column(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.caramelPale,
          border: Border.all(color: isActive ? AppColors.goldRing : Colors.transparent, width: 2.5)),
        child: ClipOval(child: pet.profilePhotoPath != null
            ? Image.file(File(pet.profilePhotoPath!), fit: BoxFit.cover, errorBuilder: (_,__,___) => Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26))))
            : Center(child: Text(pet.species.emoji, style: const TextStyle(fontSize: 26))))),
      const SizedBox(height: 4),
      Text(pet.name, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.caramel : AppColors.textMid)),
    ]),
  );
}

// ─── ペット追加 Dialog ────────────────────────────────────

class _AddPetDialog extends StatefulWidget {
  const _AddPetDialog();
  @override State<_AddPetDialog> createState() => _AddPetDialogState();
}
class _AddPetDialogState extends State<_AddPetDialog> {
  final _nameCtrl = TextEditingController();
  PetSpecies _species = PetSpecies.dog;
  @override Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('🐾 ペットを追加', style: TextStyle(fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名前', hintText: '例：むぎ', hintStyle: TextStyle(color: AppColors.textLight)), onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: PetSpecies.values.map((s) => ChoiceChip(label: Text('${s.emoji} ${s.label}'), selected: _species == s, onSelected: (_) => setState(() => _species = s), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 12))).toList()),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid))),
      ElevatedButton(onPressed: _nameCtrl.text.trim().isEmpty ? null : () async {
        await context.read<AppProvider>().addPet(Pet(name: _nameCtrl.text.trim(), species: _species, createdAt: DateTime.now()));
        if (mounted) Navigator.pop(context);
      }, child: const Text('追加')),
    ],
  );
}

// ─── ペット編集 Dialog ────────────────────────────────────

class _EditPetDialog extends StatefulWidget {
  final Pet pet;
  const _EditPetDialog({required this.pet});
  @override State<_EditPetDialog> createState() => _EditPetDialogState();
}
class _EditPetDialogState extends State<_EditPetDialog> {
  late TextEditingController _nameCtrl;
  late PetSpecies _species; late PetGender _gender;
  DateTime? _birthDate, _welcomeDate, _passedDate;
  bool _showPassed = false;

  @override void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet.name);
    _species = widget.pet.species; _gender = widget.pet.gender;
    _birthDate = widget.pet.birthDate; _welcomeDate = widget.pet.welcomeDate;
    _passedDate = widget.pet.passedDate; _showPassed = widget.pet.hasPassed;
  }

  @override Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('✏️ プロフィール編集', style: TextStyle(fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '名前', hintStyle: TextStyle(color: AppColors.textLight))),
      const SizedBox(height: 10),
      Wrap(spacing: 6, children: PetSpecies.values.map((s) => ChoiceChip(label: Text('${s.emoji} ${s.label}'), selected: _species == s, onSelected: (_) => setState(() => _species = s), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _species == s ? Colors.white : AppColors.textMid, fontSize: 11))).toList()),
      const SizedBox(height: 8),
      Wrap(spacing: 6, children: PetGender.values.map((g) => ChoiceChip(label: Text(g.label), selected: _gender == g, onSelected: (_) => setState(() => _gender = g), selectedColor: AppColors.caramel, labelStyle: TextStyle(color: _gender == g ? Colors.white : AppColors.textMid, fontSize: 11))).toList()),
      const SizedBox(height: 8),
      _dateRow(context, '誕生日', _birthDate, (d) => setState(() => _birthDate = d), () => setState(() => _birthDate = null)),
      _dateRow(context, 'お迎えした日', _welcomeDate, (d) => setState(() => _welcomeDate = d), () => setState(() => _welcomeDate = null)),
      InkWell(onTap: () => setState(() => _showPassed = !_showPassed), child: Row(children: [
        Icon(_showPassed ? Icons.expand_less : Icons.expand_more, color: AppColors.textLight, size: 18),
        Text(' 🌈 虹の橋', style: TextStyle(fontSize: 11, color: _showPassed ? AppColors.textMid : AppColors.textLight)),
      ])),
      if (_showPassed) _dateRow(context, '虹の橋を渡った日', _passedDate, (d) => setState(() => _passedDate = d), () => setState(() => _passedDate = null)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル', style: TextStyle(color: AppColors.textMid))),
      ElevatedButton(onPressed: () async {
        await context.read<AppProvider>().updatePet(widget.pet.copyWith(
          name: _nameCtrl.text.trim(), species: _species, gender: _gender,
          birthDate: _birthDate, clearBirth: _birthDate == null,
          welcomeDate: _welcomeDate, clearWelcome: _welcomeDate == null,
          passedDate: _passedDate, clearPassed: _passedDate == null));
        if (mounted) Navigator.pop(context);
      }, child: const Text('保存')),
    ],
  );

  Widget _dateRow(BuildContext context, String label, DateTime? date, Function(DateTime) onPick, VoidCallback onClear) {
    return Row(children: [
      Expanded(child: Text(date != null ? '$label: ${date.year}/${date.month}/${date.day}' : '$label: 未設定', style: const TextStyle(fontSize: 11, color: AppColors.textMid))),
      if (date != null) IconButton(icon: const Icon(Icons.clear, size: 14, color: AppColors.textLight), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: onClear),
      TextButton(onPressed: () async { final p = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) onPick(p); },
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
        child: Text(date != null ? '変更' : '設定', style: const TextStyle(color: AppColors.caramel, fontSize: 12))),
    ]);
  }
}

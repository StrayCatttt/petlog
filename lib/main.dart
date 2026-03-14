import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'repositories/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/diary_screen.dart';
import 'screens/album_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/other_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  await MobileAds.instance.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
  runApp(const PetlogApp());
}

class PetlogApp extends StatelessWidget {
  const PetlogApp({super.key});
  @override Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(title: 'ペットログ', theme: buildAppTheme(), debugShowCheckedModeBanner: false, home: const MainShell()),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  static const _screens = [HomeScreen(), DiaryScreen(), AlbumScreen(), ExpenseScreen(), SettingsScreen()];
  static const _navItems = [
    BottomNavigationBarItem(icon: Text('🏠', style: TextStyle(fontSize: 22)), label: 'ホーム'),
    BottomNavigationBarItem(icon: Text('📅', style: TextStyle(fontSize: 22)), label: '日記'),
    BottomNavigationBarItem(icon: Text('📷', style: TextStyle(fontSize: 22)), label: 'アルバム'),
    BottomNavigationBarItem(icon: Text('💰', style: TextStyle(fontSize: 22)), label: '支出'),
    BottomNavigationBarItem(icon: Text('⚙️', style: TextStyle(fontSize: 22)), label: '設定'),
  ];
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed, backgroundColor: Colors.white,
        selectedItemColor: AppColors.caramel, unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11), elevation: 8, items: _navItems,
      ),
    );
  }
}

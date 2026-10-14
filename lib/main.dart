import 'package:bk_absen/app/app_router.dart';
import 'package:bk_absen/core/database/hive_service.dart';
import 'package:bk_absen/core/network/connectivity_service.dart';
import 'package:bk_absen/offline/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/dio_client.dart';
import 'core/storage/cache_service.dart';
import 'core/storage/token_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");
  await CacheService.init();
  await TokenManager.init();

  await HiveService.init();
  final syncService = SyncService();
  final connectivity = ConnectivityService();
  connectivity.listen(() async {
    await syncService.syncPending();
  });

  DioClient.init();
  runApp(const ProviderScope(child: MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const AppRouter(),
    );
  }
}
//1. ServerChecker
//2. NetworkErrorHelper (hapus aja)
//3. AttendanceNotifier

// 7. Bahkan lebih baik: jangan cek message, cek status + kondisi attendance

//kemungkinan gini (skenario server hidup)
//user checkin gagal menjangkau server jadinya masuk ke data Hive
//lalu user buka lagi mencoba krim hive ke server tapi gagal kirim dan terlanjur terhapus data hive nya
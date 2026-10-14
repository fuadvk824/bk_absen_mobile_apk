import 'package:bk_absen/features/update/presentatioon/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bottom_navbar.dart';
import '../features/auth/presentation/auth_login_screen.dart';
import '../features/auth/provider/auth_provider.dart';
import '../features/update/service/update_service.dart';

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({
    super.key,
  });

  @override
  ConsumerState<AppRouter> createState() =>
      _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {

  final UpdateService updateService = UpdateService();
  bool _checkedUpdate = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    if (_checkedUpdate) {
      return;
    }

    _checkedUpdate = true;

    try {
      final currentVersion = await updateService.getCurrentVersion();
      final latest = await updateService.getLatestVersion();

      final hasUpdate = updateService.isNewerVersion(
        latest.version,
        currentVersion,
      );

      debugPrint(
        '====================================',
      );
      debugPrint(
        'Current Version : $currentVersion',
      );
      debugPrint(
        'Latest Version  : ${latest.version}',
      );
      debugPrint(
        'APK URL         : ${latest.apkUrl}',
      );
      debugPrint(
        'Has Update      : $hasUpdate',
      );
      debugPrint(
        '====================================',
      );

      if (!mounted) {
        return;
      }

      if (hasUpdate) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return UpdateDialog(
              currentVersion: currentVersion,
              latest: latest,
              updateService: updateService,
            );
          },
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Check update error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },

      error: (e, s) {
        return const AuthLoginScreen();
      },

      data: (user) {
        if (user == null) {
          return const AuthLoginScreen();
        }

        return const BottomNavbar();
      },
    );
  }
}
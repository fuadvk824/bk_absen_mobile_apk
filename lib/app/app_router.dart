import 'package:bk_absen/features/auth/presentation/update_password_screen.dart';
import 'package:bk_absen/features/update/presentatioon/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bottom_navbar.dart';
import '../features/auth/presentation/auth_login_screen.dart';
import '../features/auth/provider/auth_provider.dart';

import '../features/update/service/update_service.dart';

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  final updateService = UpdateService();
  bool _checkedUpdate = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    if (_checkedUpdate) return;

    _checkedUpdate = true;

    try {
      final latest = await updateService.getLatestVersion();
      final hasUpdate = await updateService.hasUpdate();

      if (!mounted) return;

      if (hasUpdate) {
        final currentVersion = await updateService.getCurrentVersion();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(
            currentVersion: currentVersion,
            latest: latest,
            updateService: updateService,
          ),
        );
      }
    } catch (e) {
      debugPrint("Check update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (_, _) => const AuthLoginScreen(),

      data: (user) {
        if (user == null) {
          return const AuthLoginScreen();
        }

        if (user.keyStatus == 'new') {
          return const ForceChangePasswordScreen();
        }

        return const BottomNavbar();
      },
    );
  }
}

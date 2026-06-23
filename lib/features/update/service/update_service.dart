import 'package:bk_absen/model/app_version_model.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:version/version.dart';
import '../data/version_repository.dart';

class UpdateService {
  final repo = VersionRepository();

  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();

    return info.version;
  }

  Future<AppVersionModel> getLatestVersion() async {
    return await repo.checkVersion();
  }

  Future<bool> hasUpdate() async {
    final currentVersion = await getCurrentVersion();
    final latest = await getLatestVersion();
    return currentVersion != latest.version;
  }
  // Future<bool> hasUpdate() async {
  //   final current = Version.parse(await getCurrentVersion());
  //   final latest = Version.parse((await getLatestVersion()).version);

  //   return latest > current;
  // }

  // Future<String> getDownloadUrl(AppVersionModel latest) async {
  //   final androidInfo = await DeviceInfoPlugin().androidInfo;

  //   final abis = androidInfo.supportedAbis;

  //   // print("ABI DEVICE : $abis");
  //   // print("ABI DEVICE : ${androidInfo.supportedAbis}");

  //   if (abis.contains('arm64-v8a')) {
  //     return latest.apkArm64;
  //   }

  //   return latest.apkV7a;
  // }

  Future<void> downloadAndInstall(
    String apkUrl, {
    required Function(double progress) onProgress,
  }) async {
    final dir = await getExternalStorageDirectory();
    final path = '${dir!.path}/update.apk';

    await Dio().download(
      apkUrl,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total);
        }
      },
    );
    await OpenFilex.open(path);
  }
}

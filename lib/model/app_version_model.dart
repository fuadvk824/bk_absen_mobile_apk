

class AppVersionModel {
  final String version;
  final String apkUrl;
  final bool forceUpdate;
  final String? message;

  AppVersionModel({
    required this.version,
    required this.apkUrl,
    required this.forceUpdate,
    this.message,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      version: json['version'],
      apkUrl: json['apk_url'],
      forceUpdate: json['force_update'],
      message: json['message'],
    );
  }
}

// class AppVersionModel {
//   final String version;
//   final String apkArm64;
//   final String apkV7a;
//   final bool forceUpdate;
//   final String? message;

//   AppVersionModel({
//     required this.version,
//     required this.apkArm64,
//     required this.apkV7a,
//     required this.forceUpdate,
//     this.message,
//   });

//   factory AppVersionModel.fromJson(Map<String, dynamic> json) {
//     return AppVersionModel(
//       version: json['version'],
//       apkArm64: json['apk_arm64'],
//       apkV7a: json['apk_v7a'],
//       forceUpdate: json['force_update'],
//       message: json['message'],
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../service/update_service.dart';
import 'package:bk_absen/model/app_version_model.dart';

class UpdateDialog extends StatefulWidget {
  final String currentVersion;
  // final dynamic latest;
  final AppVersionModel latest;
  final UpdateService updateService;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latest,
    required this.updateService,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double progress = 0;
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade50,
                ),
                child: Icon(
                  isDownloading
                      ? Icons.downloading_rounded
                      : Icons.rocket_launch_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                isDownloading ? "Mengunduh Update..." : "Update Aplikasi",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              if (!isDownloading)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "v${widget.currentVersion} → v${widget.latest.version}",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              if (!isDownloading)
                Text(
                  widget.latest.message ?? "Versi terbaru aplikasi tersedia.",
                  textAlign: TextAlign.center,
                ),

              if (isDownloading) ...[
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(20),
                ),

                const SizedBox(height: 12),

                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isDownloading
                      ? null
                      : () async {
                          setState(() {
                            isDownloading = true;
                          });

                          await widget.updateService.downloadAndInstall(
                            widget.latest.apkUrl,
                            onProgress: (value) {
                              setState(() {
                                progress = value;
                              });
                            },
                          );
                          // final apkUrl = await widget.updateService
                          //     .getDownloadUrl(widget.latest);

                          // await widget.updateService.downloadAndInstall(
                          //   apkUrl,
                          //   onProgress: (value) {
                          //     setState(() {
                          //       progress = value;
                          //     });
                          //   },
                          // );
                        },
                  icon: isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: Text(
                    isDownloading ? "Mengunduh..." : "Update Sekarang",
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Update diperlukan untuk melanjutkan penggunaan aplikasi.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:bk_absen/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bk_absen/model/letter_model.dart';
import 'package:bk_absen/utils/app_colors.dart';

class LetterItem extends StatefulWidget {
  final LetterModel letter;
  final Future<String?> Function()? onRead;

  const LetterItem({super.key, required this.letter, this.onRead});

  @override
  State<LetterItem> createState() => _LetterItemState();
}

class _LetterItemState extends State<LetterItem> {
  bool _isDownloading = false;
  double _progress = 0;

  String _getDayShort(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return days[weekday - 1];
  }
  String _getMonthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[month - 1];
  }

  Color _getLetterColor(String jenisSurat) {
    switch (jenisSurat.toLowerCase()) {
      case 'sp1':
        return Colors.orange;

      case 'sp2':
        return Colors.deepOrange;

      case 'sp3':
        return Colors.red;

      case 'probation':
        return Colors.blue;

      case 'paklaring':
        return Colors.green;

      default:
        return AppColors.primary;
    }
  }

  String _getLetterTitle(String jenisSurat) {
    switch (jenisSurat.toLowerCase()) {
      case 'sp1':
        return 'Surat Peringatan 1';

      case 'sp2':
        return 'Surat Peringatan 2';

      case 'sp3':
        return 'Surat Peringatan 3';

      case 'probation':
        return 'Surat Probation';

      case 'paklaring':
        return 'Surat Paklaring';

      default:
        return jenisSurat;
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;

    final oldPdfUrl = widget.letter.pdfUrl;

    if (oldPdfUrl == null || oldPdfUrl.isEmpty) {
      ToastHelper.warning(context, message: 'PDF tidak tersedia');
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      // URL yang akan digunakan untuk download.
      // Awalnya menggunakan PDF biasa.
      String downloadUrl = oldPdfUrl;
      bool isReadPdf = widget.letter.isRead;

      if (!widget.letter.isRead) {
        final newPdfUrl = await widget.onRead?.call();

        if (newPdfUrl == null || newPdfUrl.isEmpty) {
          throw Exception('Gagal mendapatkan PDF surat yang sudah dibaca');
        }

        downloadUrl = newPdfUrl;
        isReadPdf = true;
      }

      final directory = await getApplicationDocumentsDirectory();

      final baseFileName = _generateFileName();

      // Pisahkan file lokal berdasarkan status sudah dibaca.
      final fileName = isReadPdf
          ? baseFileName.replaceFirst('.pdf', '-read.pdf')
          : baseFileName;

      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);

      // Kalau PDF versi ini sudah pernah didownload,
      // langsung buka file tersebut.
      if (await file.exists()) {
        if (!mounted) return;

        setState(() {
          _isDownloading = false;
          _progress = 1;
        });

        await OpenFilex.open(filePath);
        return;
      }

      await Dio().download(
        downloadUrl,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status != null && status >= 200 && status < 300;
          },
        ),
        onReceiveProgress: (received, total) {
          if (!mounted) return;

          if (total > 0) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _progress = 1;
      });

      ToastHelper.success(context, message: 'PDF berhasil didownload');

      await OpenFilex.open(filePath);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _progress = 0;
      });

      ToastHelper.error(context, message: 'Gagal membuka PDF');
    }
  }

  String _generateFileName() {
    var nomorSurat = widget.letter.nomorSurat
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(' ', '_');

    nomorSurat = nomorSurat.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    if (nomorSurat.isEmpty) {
      nomorSurat = 'surat_peringatan';
    }

    return '$nomorSurat.pdf';
  }

  @override
  Widget build(BuildContext context) {
    DateTime? date;

    try {
      date = DateTime.parse(widget.letter.tanggalSurat);
    } catch (_) {
      date = null;
    }

    final letterColor = _getLetterColor(widget.letter.jenisSurat);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: .15), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (date != null) ...[
                      Text(
                        _getDayShort(date.weekday),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date.day.toString(),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getMonthShort(date.month),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ] else
                      const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 30,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getLetterTitle(widget.letter.jenisSurat),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: letterColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.letter.nomorSurat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.letter.isRead
                                        ? Icons.mark_email_read
                                        : Icons.mark_email_unread,
                                    size: 16,
                                    color: widget.letter.isRead
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.letter.isRead ? 'Dibaca' : 'Baru',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: widget.letter.isRead
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Status',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Divider(),

                    const SizedBox(height: 2),

                    if (widget.letter.pdfUrl != null &&
                        widget.letter.pdfUrl!.isNotEmpty)
                      SizedBox(
                        height: 35,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _isDownloading
                              ? null
                              : () => _downloadPdf(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isDownloading)
                                SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.download_outlined,
                                  size: 17,
                                  color: AppColors.primary,
                                ),

                              const SizedBox(width: 6),

                              Text(
                                _isDownloading
                                    ? _progress > 0
                                          ? 'Downloading ${(_progress * 100).toStringAsFixed(0)}%'
                                          : 'Downloading...'
                                    : 'Lihat & Download',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox(
                        height: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'PDF tidak tersedia',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

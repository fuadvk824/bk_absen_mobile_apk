import 'dart:io';

import 'package:bk_absen/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class LetterPdf extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String nomorSurat;

  const LetterPdf({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.nomorSurat,
  });

  @override
  State<LetterPdf> createState() => _LetterPdfState();
}

class _LetterPdfState extends State<LetterPdf> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    if (_isDownloading) {
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _generateFileName();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        if (!mounted) return;

        setState(() {
          _isDownloading = false;
        });

        await OpenFilex.open(filePath);

        return;
      }

      await Dio().download(
        widget.pdfUrl,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });

      ToastHelper.success(context, message: 'PDF berhasil didownload');

      await OpenFilex.open(filePath);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });

      debugPrint('DOWNLOAD PDF ERROR: $e');
      ToastHelper.error(context, message: 'Gagal download PDF');
    }
  }

  String _generateFileName() {
    final nomorSurat = widget.nomorSurat
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(' ', '_');

    return '$nomorSurat.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _isDownloading ? null : _downloadPdf,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),

          const SizedBox(width: 4),
        ],
      ),

      body: SfPdfViewer.network(
        widget.pdfUrl,

        onDocumentLoadFailed: (details) {
          debugPrint('PDF ERROR: ${details.error}');
          debugPrint('PDF DESCRIPTION: ${details.description}');

          if (!mounted) return;

          ToastHelper.error(
            context,
            title: 'Gagal Membuka PDF',
            message: details.description,
          );
        },
      ),
    );
  }
}

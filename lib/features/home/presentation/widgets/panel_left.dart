import 'dart:io';
import 'package:flutter/material.dart';

class PanelLeft extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onOpenCamera;

  const PanelLeft({
    super.key,
    required this.imageFile,
    required this.onOpenCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade100,
            ),
            child: imageFile == null
                ? const Center(child: Text("Belum ada foto"))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile!,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onOpenCamera,
              child: const Text("Ambil Foto"),
            ),
          ),
        ],
      ),
    );
  }
}
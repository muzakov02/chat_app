import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AttachmentSheet extends StatelessWidget {
  const AttachmentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha + yopish
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attachment File',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF111111)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1-qator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _attachItem('assets/icons/document_icon.svg', 'Dakument'),
              _attachItem('assets/icons/camera_icon.svg', 'Kamera'),
              _attachItem('assets/icons/gallery_icon.svg', 'Galareya'),
            ],
          ),
          const SizedBox(height: 24),

          // 2-qator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _attachItem('assets/icons/audio_icon.svg', 'Audio'),
              _attachItem('assets/icons/location_icon.svg', 'Manzil'),
              _attachItem('assets/icons/contact_icon.svg', 'Kontakt'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _attachItem(String iconPath, String label) {
    return Column(
      children: [
        SvgPicture.asset(
          iconPath,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}
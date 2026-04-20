import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AttachmentSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onDocument;
  final VoidCallback onAudio;
  final VoidCallback onLocation;
  final VoidCallback onContact;

  const AttachmentSheet({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onDocument,
    required this.onAudio,
    required this.onLocation,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      // padding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18.0, right: 18.0,top: 8.0),
              child: Row(
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
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachItem(context, 'assets/icons/document_icon.svg', 'Dakument', onDocument),
                _attachItem(context, 'assets/icons/camera_icon.svg', 'Kamera', onCamera),
                _attachItem(context, 'assets/icons/gallery_icon.svg', 'Galareya', onGallery),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachItem(context, 'assets/icons/audio_icon.svg', 'Audio', onAudio),
                _attachItem(context, 'assets/icons/location_icon.svg', 'Manzil', onLocation),
                _attachItem(context, 'assets/icons/contact_icon.svg', 'Kontakt', onContact),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _attachItem(BuildContext context, String iconPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          SvgPicture.asset(iconPath),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF111111))),
        ],
      ),
    );
  }
}
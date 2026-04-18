import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'attachment_sheet.dart';

class ChatBarWidget extends StatefulWidget {
  final Function(String query)? onQueryChanged;
  final Function(String message)? onSendPressed;
  final String hintText;

  const ChatBarWidget({
    super.key,
    this.onQueryChanged,
    this.onSendPressed,
    this.hintText = 'Xabar yozish',
  });

  @override
  State<ChatBarWidget> createState() => _ChatBarWidgetState();
}

class _ChatBarWidgetState extends State<ChatBarWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendPressed?.call(text);
    _controller.clear();
  }
  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 310,
        width: 336,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const AttachmentSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFAEAEAE),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAttachmentSheet,
            child: SvgPicture.asset(
              'assets/icons/file_icon.svg',
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onQueryChanged,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 14,
              ),
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA4AB),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF56CB01),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/icons/send_icon.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
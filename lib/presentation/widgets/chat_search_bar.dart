import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ChatSearchBar extends StatefulWidget {
  final Function(String query)? onQueryChanged;
  final String hintText;

  const ChatSearchBar({
    super.key,
    this.onQueryChanged,
    this.hintText = 'Qidirish...',
  });

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    setState(() => _hasText = query.isNotEmpty);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      widget.onQueryChanged?.call(query);
    });
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }


  Widget _divider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFAEAEAE),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
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
          SvgPicture.asset(
            'assets/icons/search_icon.svg',
            width: 18,
            height: 18,
          ),
          const SizedBox(width: 8),

          // TextField
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
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

          if (_hasText) ...[
            GestureDetector(
              onTap: _clear,
              child: SvgPicture.asset(
                'assets/icons/close.svg',
                width: 18,
                height: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          _divider(),

          SvgPicture.asset(
            'assets/icons/filter.svg',
            width: 18,
            height: 18,
          ),
        ],
      ),
    );
  }
}
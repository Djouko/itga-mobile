import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';
import 'package:untitled/common/extensions/font_extension.dart';

class MentionOverlay extends StatefulWidget {
  final TextEditingController textController;
  final Function(User user) onMentionSelected;
  final double maxHeight;

  const MentionOverlay({
    super.key,
    required this.textController,
    required this.onMentionSelected,
    this.maxHeight = 200,
  });

  @override
  State<MentionOverlay> createState() => _MentionOverlayState();
}

class _MentionOverlayState extends State<MentionOverlay> {
  List<User> _suggestions = [];
  bool _showOverlay = false;
  Timer? _debounce;
  String _currentMentionQuery = '';

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.textController.text;
    final cursorPos = widget.textController.selection.baseOffset;

    if (cursorPos < 0 || cursorPos > text.length) {
      _hideOverlay();
      return;
    }

    final mentionQuery = _extractMentionQuery(text, cursorPos);

    if (mentionQuery != null && mentionQuery.isNotEmpty) {
      _currentMentionQuery = mentionQuery;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _searchUsers(mentionQuery);
      });
    } else {
      _hideOverlay();
    }
  }

  String? _extractMentionQuery(String text, int cursorPos) {
    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');

    if (atIndex == -1) return null;

    // '@' must be at start or preceded by a space/newline
    if (atIndex > 0) {
      final charBefore = beforeCursor[atIndex - 1];
      if (charBefore != ' ' && charBefore != '\n') return null;
    }

    final query = beforeCursor.substring(atIndex + 1);

    // If there's a space after the query started, user finished typing the mention
    if (query.contains(' ') || query.contains('\n')) return null;

    return query;
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      _hideOverlay();
      return;
    }

    await UserService.shared.searchProfile(query, 0, (users) {
      if (mounted && _currentMentionQuery == query) {
        setState(() {
          _suggestions = users.take(5).toList();
          _showOverlay = _suggestions.isNotEmpty;
        });
      }
    });

    if (mounted && _suggestions.isEmpty) {
      setState(() {
        _showOverlay = false;
      });
    }
  }

  void _hideOverlay() {
    if (_showOverlay || _suggestions.isNotEmpty) {
      setState(() {
        _showOverlay = false;
        _suggestions = [];
        _currentMentionQuery = '';
      });
    }
  }

  void _onUserSelected(User user) {
    final text = widget.textController.text;
    final cursorPos = widget.textController.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');

    if (atIndex == -1) return;

    final username = user.username ?? user.fullName ?? '';
    final newText =
        text.substring(0, atIndex) + '@$username ' + text.substring(cursorPos);

    widget.textController.text = newText;
    final newCursorPos = atIndex + username.length + 2; // +2 for @ and space
    widget.textController.selection =
        TextSelection.collapsed(offset: newCursorPos);

    widget.onMentionSelected(user);
    _hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOverlay) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: cBlackSheetBG,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: cWhite.withValues(alpha: 0.1),
          ),
          itemBuilder: (context, index) {
            final user = _suggestions[index];
            return _MentionUserTile(
              user: user,
              onTap: () => _onUserSelected(user),
            );
          },
        ),
      ),
    );
  }
}

class _MentionUserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _MentionUserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            MyCachedImage(
              imageUrl: user.profile?.addBaseURL(),
              width: 36,
              height: 36,
              cornerRadius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.fullName ?? '',
                    style: MyTextStyle.gilroySemiBold(color: cWhite, size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.username != null)
                    Text(
                      '@${user.username}',
                      style: MyTextStyle.gilroyRegular(
                          color: cLightText, size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

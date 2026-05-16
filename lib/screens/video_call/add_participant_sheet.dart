import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/api_service/user_service.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/widgets/my_cached_image.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/screens/video_call/video_call_controller.dart';
import 'package:untitled/utilities/const.dart';

/// WhatsApp-style bottom sheet to add participants to an ongoing video call.
/// Shows the user's following list with search, tap to invite.
class AddParticipantSheet extends StatefulWidget {
  final VideoCallController callController;

  const AddParticipantSheet({super.key, required this.callController});

  @override
  State<AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<AddParticipantSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filtered = [];
  bool _isLoading = true;
  final Set<int> _invitedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  void _fetchFollowing() {
    UserService.shared.fetchFollowingList(
      SessionManager.shared.getUserID(),
      0,
      (users) {
        setState(() {
          _users = users;
          _filtered = users;
          _isLoading = false;
        });
      },
    );
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _users;
      } else {
        _filtered = _users.where((u) {
          final name = (u.fullName ?? '').toLowerCase();
          final username = (u.username ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _invite(User user) {
    final uid = user.id?.toInt() ?? 0;
    if (_invitedIds.contains(uid)) return;
    widget.callController.inviteParticipant(user);
    setState(() => _invitedIds.add(uid));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: cDarkBG,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Add Participant',
                  style: MyTextStyle.gilroyBold(color: Colors.white, size: 18),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.5), size: 24),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: MyTextStyle.gilroyRegular(color: Colors.white, size: 14),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: MyTextStyle.gilroyRegular(color: Colors.white38, size: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
                cursorColor: cPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: cPrimary, strokeWidth: 2))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No contacts found',
                          style: MyTextStyle.gilroyRegular(color: Colors.white38, size: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final user = _filtered[index];
                          final uid = user.id?.toInt() ?? 0;
                          final alreadyInCall = widget.callController.remoteUsers.contains(uid);
                          final alreadyInvited = _invitedIds.contains(uid);

                          return ListTile(
                            leading: MyCachedProfileImage(
                              imageUrl: user.profile,
                              fullName: user.fullName,
                              width: 42,
                              height: 42,
                              cornerRadius: 21,
                            ),
                            title: Text(
                              user.fullName ?? '',
                              style: MyTextStyle.gilroySemiBold(color: Colors.white, size: 15),
                            ),
                            subtitle: Text(
                              '@${user.username ?? ''}',
                              style: MyTextStyle.gilroyRegular(color: Colors.white38, size: 12),
                            ),
                            trailing: alreadyInCall
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: cGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('In call', style: MyTextStyle.gilroySemiBold(color: cGreen, size: 11)),
                                  )
                                : alreadyInvited
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text('Invited', style: MyTextStyle.gilroySemiBold(color: Colors.white38, size: 11)),
                                      )
                                    : GestureDetector(
                                        onTap: () => _invite(user),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: cPrimary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: cPrimary.withValues(alpha: 0.3)),
                                          ),
                                          child: Text('Invite', style: MyTextStyle.gilroySemiBold(color: cPrimary, size: 11)),
                                        ),
                                      ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

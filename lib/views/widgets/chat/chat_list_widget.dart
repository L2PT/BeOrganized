// ChatList aggiornata con hover, focus e separatori — WhatsApp Web clone

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/message/chat_overview.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class ChatList extends StatefulWidget {
  final List<ChatOverview> chats;
  final String? activeChatId;
  final void Function(String) onChatTap;
  final bool onlyUnread;

  ChatList({
    required this.chats,
    this.activeChatId,
    required this.onChatTap,
    this.onlyUnread = false,
  });

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  String? _hovered;
  String? _focused;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Tutte le chat", style: title),
            IconButton(
              icon: Icon(
                widget.onlyUnread ? Icons.mark_chat_unread : Icons.mark_chat_unread_outlined,
                color: widget.onlyUnread ? yellow : grey,
              ),
              onPressed: () => context.read<WebCubit>().messageManagePageCubit.toggleOnlyUnread(),
              tooltip: "Filtra non letti",
            ),
          ],
        ),
        SizedBox(height: 10,),
        Container(
          decoration: BoxDecoration(
            color: black,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: TextField(
            onChanged: (s) => context.read<WebCubit>().messageManagePageCubit.updateSearchQuery(s),
            style: const TextStyle(color: white),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: white),
              hintText: "Cerca una chat",
              hintStyle: const TextStyle(color: white),
              contentPadding: const EdgeInsets.only(top: 12),
            ),
          ),
        ),
        const SizedBox(height: 10,),
        Expanded(
          child: ListView.separated(
            itemCount: widget.chats.length,
            separatorBuilder: (_, __) => Divider(height: 2, thickness: 1, indent: 15, endIndent: 15, color: grey_light),
            itemBuilder: (context, index) {
              final c = widget.chats[index];
              final isActive = c.id == widget.activeChatId;

              return FocusableActionDetector(
                mouseCursor: SystemMouseCursors.click,
                onShowFocusHighlight: (focused) => setState(() => _focused = focused ? c.id : null),
                onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered ? c.id : null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _focused == c.id
                        ? grey.withValues(alpha: 0.25)
                        : _hovered == c.id
                        ? grey.withValues(alpha: 0.15)
                        : isActive
                        ? grey.withValues(alpha: 0.25)
                        : null,
                    borderRadius: BorderRadius.circular(
                      _hovered == c.id || _focused == c.id || isActive ? 12 : 4,
                    ),
                  ),
                  child: ListTile(
                    tileColor: Colors.transparent,
                    onTap: () => widget.onChatTap(c.id),
                    leading: CircleAvatar(
                      child: Icon(Icons.person, color: yellow, size: 30),
                      radius: 22,
                      backgroundColor: black,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(c.name, style: label.copyWith(fontSize: 18))),
                        if (_hovered == c.id)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.grey.shade600, size: 20),
                            onPressed: () {
                              context.read<WebCubit>().messageManagePageCubit.deleteChat(c.id);
                            },
                            tooltip: "Elimina chat",
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          )
                        else
                          Text(_formatTime(c.lastMessageTime), style: stepper_title_nofocus.copyWith(fontSize: 12)),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.lastMessage,
                            style: label.copyWith(fontSize: 14, color: grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (t.day == now.day && t.month == now.month && t.year == now.year) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day}/${t.month}/${t.year}';
  }
}
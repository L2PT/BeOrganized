// main.dart
// Clone semplice di WhatsApp Web in Flutter — single file example
// Funzionalità incluse:
// - Layout responsive: lista chat a sinistra, chat attiva a destra (desktop)
// - Mobile: lista chat -> tap apre schermata chat
// - Lista chat con avatar, ultimo messaggio, badge non letti
// - Area chat con bolle messaggio, input per inviare messaggi
// - Dati mock per provare l'app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/cubit/web/messageManage_page/message_manage_page_cubit.dart';
import 'package:venturiautospurghi/cubit/web/web_cubit.dart';
import 'package:venturiautospurghi/models/message/chat_overview.dart';
import 'package:venturiautospurghi/models/message/message.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/screens/message_login_view.dart';
import 'package:venturiautospurghi/views/widgets/chat/chat_list_widget.dart';
import 'package:venturiautospurghi/views/widgets/chat/nochat_widget.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';

class MessageManage extends StatefulWidget {

  @override
  _MessageManageState createState() => _MessageManageState();
}

class _MessageManageState extends State<MessageManage> {

  @override
  void initState() {
    super.initState();
    if(!PlatformUtils.isMobile) {
      context.read<WebCubit>().initCubit(Constants.manageMessageRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebCubit, WebCubitState>(
        buildWhen: (previous, current) => previous.messageManagePageState != current.messageManagePageState,
        builder: (context, state) {
          if (state.messageManagePageState is LoadedMessageManage) {
            return Row(
              children: [
                Container(
                    width: 360,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      color: Colors.white,
                    ),
                    child: Padding(padding: EdgeInsets.all(10), child: ChatList(
                      chats: state.messageManagePageState.filteredChats,
                      activeChatId: state.messageManagePageState.selectedChat?.id,
                      onlyUnread: state.messageManagePageState.onlyUnread,
                      onChatTap: (id) {
                        final chat = state.messageManagePageState.chats.firstWhere((c) => c.id == id);
                        context.read<WebCubit>().messageManagePageCubit.selectChat(chat);
                      },
                    ),
                    )),
                Expanded(
                  child: Container(
                    color: grey_light2,
                    child: state.messageManagePageState.selectedChat != null
                        ? ChatScreen(
                      chat: state.messageManagePageState.selectedChat!,
                      messages: state.messageManagePageState.currentMessages,
                      onSend: (text) => context.read<WebCubit>().messageManagePageCubit.sendMessage(text),
                    )
                        : NoChat(),
                  ),
                ),
              ],
            );
          } else if(state.messageManagePageState is LoadingMessagesManage) {
            return WhatsAppLoginScreen(state.messageManagePageState.qrcode);
          } else {
            return LoadingScreen();
          }
        },
      );
  }
}


// ---------- Widgets ----------


class ChatScreen extends StatefulWidget {
  final ChatOverview chat;
  final List<Message> messages;
  final void Function(String) onSend;

  ChatScreen({required this.chat, required this.messages, required this.onSend});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    // scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: grey_light2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
        image: DecorationImage(
          image: AssetImage("assets/chat_background.png"),
          repeat: ImageRepeat.repeat,
          scale: 2.5, // Higher scale makes the image render smaller (treated as higher density)
          opacity: 0.4,
        ),
      ),
      child: Column(
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300))
          ),
          child: Row(
            children: [
              CircleAvatar(child: Icon(Icons.person, color: yellow, size: 30,), radius: 22, backgroundColor: black,),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      (widget.chat.phoneNumber != null && widget.chat.phoneNumber!.isNotEmpty)
                          ? widget.chat.phoneNumber!
                          : widget.chat.realPhoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade600),
                onPressed: () {
                  context.read<WebCubit>().messageManagePageCubit.deleteChat(widget.chat.id);
                },
                tooltip: "Elimina chat",
              )
            ],
          ),
        ),

        // MESSAGGI
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView.builder(
              reverse: true,
              controller: _scroll,
              itemCount: widget.messages.length,
              itemBuilder: (context, i) {
                final m = widget.messages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Align(
                    alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: m.isMe ? Color(0xFF1E1E1E) : Colors.white, // Dark vs Beige
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(m.isMe ? 16 : 0),
                            bottomRight: Radius.circular(m.isMe ? 0 : 16),
                          ),
                          // boxShadow: [ BoxShadow(...) ] // Remove shadow for cleaner look or keep minimal
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.text,
                                style: TextStyle(
                                  color: m.isMe ? white : black,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _shortTime(m.timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: m.isMe
                                          ? white
                                          : grey,
                                    ),
                                  ),
                                  if (m.eventoId.isNotEmpty) ...[
                                    const SizedBox(width: 15),
                                    TextButton(
                                      onPressed: () => context.read<WebCubit>().messageManagePageCubit.goToEventDetails(context, m.eventoId),
                                      style: TextButton.styleFrom(
                                        backgroundColor: yellow,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        minimumSize: const Size(0, 24),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Vedi Incarico', style: TextStyle(color: white, fontSize: 12)),
                                    ),
                                  ],
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                  ),),
                );
              },
            ),
          ),
        ),

        // INPUT BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              // Text Field Pill
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): _send,
                    },
                    child: TextFormField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 5,
                      cursorColor: black,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Scrivi un messaggio...',
                        hintStyle: subtitle,
                        border: InputBorder.none,
                      ),
                      validator:(value) => string.isNullOrEmpty(value)?null:null,
                      onSaved: (value) => value??"",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send Button
              GestureDetector(
                onTap: _send,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send, color: white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }


  String _shortTime(DateTime t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

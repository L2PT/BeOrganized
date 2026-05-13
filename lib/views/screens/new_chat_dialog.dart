import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:venturiautospurghi/cubit/web/new_chat_dialog/new_chat_dialog_cubit.dart';
import 'package:venturiautospurghi/cubit/web/new_chat_dialog/new_chat_dialog_state.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/filter/filter_contacts_message_widget.dart';
import 'package:venturiautospurghi/views/widgets/stepper_widget.dart';

class NewChatDialog extends StatelessWidget {
  final int currentStep;
  static const iconWidth = 30.0;
  final CloudFirestoreService? repository;
  final String qrCode;


  NewChatDialog(this.qrCode, { this.currentStep = 0, this.repository, super.key});

  @override
  Widget build(BuildContext context) {
    CloudFirestoreService repo = repository ?? context.read<CloudFirestoreService>();
    return new BlocProvider(
        create: (_) => NewChatDialogCubit(repo),
        child:  _chatWidget(qrCode)
    );
  }
}

class _chatWidget extends StatelessWidget {
  final String qrCode;

  _chatWidget(this.qrCode);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        appBar: new AppBar(
          leading: new BackButton(
              onPressed: () => PlatformUtils.backNavigator(context)
          ),
          title: new Text('NUOVA CHAT', style: title_rev,
          ),
        ),
        body: BlocBuilder<NewChatDialogCubit, NewChatDialogState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
                if (state is NewChatDialogLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (state is NewChatDialogDisconnected) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(24),
                      width: 360,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2, size: 80, color: green),
                          SizedBox(height: 16),

                          Text(
                            "Sessione WhatsApp non attiva",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),

                          SizedBox(height: 10),
                          Text(
                            "Scansiona il QR code con WhatsApp\nper attivare la sessione.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 24),

                          if (this.qrCode == "")
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("QR non ancora pronto...",
                                  style: TextStyle(color: Colors.grey)),
                            )
                          else
                            QrImageView(
                              data: qrCode,
                              version: QrVersions.auto,
                              size: 240,
                            ),
                          SizedBox(height: 20),
                          Text(
                            "In attesa di connessione...",
                            style: TextStyle(color: Colors.grey.shade600),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (state is! NewChatDialogData) return SizedBox.shrink();

                return _ChatStepper(context);
            })
    );
  }
}

class _ChatStepper extends StatelessWidget{
  final BuildContext context;

  void _onSavePressed() async {
    if (await context.read<NewChatDialogCubit>().sendMessage())
      if( !(await SuccessAlert(context, text: "Messaggio inviato!").show())){
        PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : Event.empty(), 'res': true});
      }
  }

  _ChatStepper(this.context);

  @override
  Widget build(BuildContext context) {
    int currentStep = context.read<NewChatDialogCubit>().getCurrentStep();
    List<StepIcon> getChatSteps() => [
      StepIcon(
        state: currentStep == 0 ? StepState.editing : StepState.complete,
        isActive: currentStep >= 0,
        icon: Icons.contact_phone,
        title: Text('Contatto'),
        content: _contactsChat(),
      ),
      StepIcon(
        state: currentStep == 1 ? StepState.editing : StepState.indexed,
        isActive: currentStep >= 1,
        icon: Icons.message,
        title: Text('Messaggio'),
        content: _messageChat(),
      )
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && scrollInfo.metrics.maxScrollExtent > 0) {
           context.read<NewChatDialogCubit>().loadMoreContacts();
        }
        return false;
      },
      child: Theme(
        data: ThemeData(
            primarySwatch: Colors.grey,
            textTheme: Theme.of(context).textTheme.copyWith(bodySmall: stepper_title_nofocus),
            colorScheme: ColorScheme.light(
              primary: black,
            )
        ),
        child: StepperIcon(
          elevation: 0.5,
          type: StepperType.horizontal,
          steps: getChatSteps(),
          currentStep: context.read<NewChatDialogCubit>().getCurrentStep(),
          onStepCancel: () => context.read<NewChatDialogCubit>().backToSearch(),
          onStepContinue: () {
            // Placeholder: currently no specific step continue logic
          },
          controlsBuilder: (BuildContext context, ControlsDetails controls) {
            return Center(
                child:Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (controls.currentStep != 0)
                      TextButton(
                        child: new Text('Torna indietro', style: label),
                        onPressed: controls.onStepCancel,
                      ),
                    SizedBox(
                      width: 15,
                    ),
                    if (controls.currentStep == 1)
                      ElevatedButton(
                          style: raisedButtonStyle,
                          child: new Text('Invia', style: button_card),
                          onPressed: (){
                            if(!Utils.isDoubleClick(context.read<NewChatDialogCubit>().firstClick, _.DateUtils.now())){_onSavePressed();}}),
                  ],
                ));
          },
        )
      )
    );

  }
}

class _contactsChat extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var state = context.watch<NewChatDialogCubit>().state as NewChatDialogData;
    Widget buildContactsChatsList() => state.searchResults.isNotEmpty?
    ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (_, __) => Divider(height: 2, thickness: 1, indent: 15, endIndent: 15, color: grey_light),
          physics: NeverScrollableScrollPhysics(),
          padding: new EdgeInsets.symmetric(vertical: 0.0),
          itemCount: state.searchResults.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.searchResults.length) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator(color: yellow,)),
              );
            }
            var contact = state.searchResults[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: black, child: Icon(Icons.person, color: yellow)),
              title: Text(contact.name.isNotEmpty ? contact.name : (contact.pushname ?? ''), style: title.copyWith(fontSize: 16)),
              subtitle: Text(StringUtils.formatPhoneNumber(contact.phoneNumber), style: subtitle),
              onTap: () => context.read<NewChatDialogCubit>().selectContact(contact),
            );
          }
      )
    : Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Nessun contatto da mostrare", style: title),
          ],
        ),
      ),
    );


    return Container(
      constraints: BoxConstraints(minHeight: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ContactsMessageFilterWidget(
              paddingTop: 0,
              paddingHorizontal: 0,
              filtersBoxVisibile: false,
              isExpandable: false,
              hintTextSearch: "Cerca un contatto",
              onSearchFieldChanged: (val) => context.read<NewChatDialogCubit>().searchContacts(val["name"]?.fieldValue as String? ?? ""),
              onFiltersChanged: (val) {}),
          SizedBox(height: 5),
          buildContactsChatsList(),
        ],
      ),
    );
  }
}

class _messageChat extends StatelessWidget {
  final TextEditingController messageController = TextEditingController();

  Widget _buildStep1(BuildContext context, NewChatDialogData state) {
    messageController.text = state.messageText;
    messageController.selection = TextSelection.fromPosition(TextPosition(offset: messageController.text.length));

    if (state.selectedContact == null) return SizedBox.shrink();

    var contact = state.selectedContact!;

    return Container(
      constraints: BoxConstraints(minHeight: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: black, child: Icon(Icons.person, color: yellow)),
            title: Text(contact.name.isNotEmpty ? contact.name : (contact.pushname ?? ''), style: title.copyWith(fontSize: 18)),
            subtitle: Text(StringUtils.formatPhoneNumber(contact.phoneNumber), style: subtitle),
          ),
          SizedBox(height: 15),
          TextField(
            controller: messageController,
            maxLines: 5,
            onChanged: (val) => context.read<NewChatDialogCubit>().updateMessage(val),
            decoration: InputDecoration(
              hintText: 'Scrivi un messaggio...',
              hintStyle: subtitle,
              errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1.0)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: grey_light, width: 1.0)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: grey_light, width: 1.0)),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1.0),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<NewChatDialogCubit>().state;
    if (state is NewChatDialogData) {
      return _buildStep1(context, state);
    }
    return SizedBox.shrink();
  }
}
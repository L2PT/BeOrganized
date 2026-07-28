import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/animation/fade_animation.dart';
import 'package:venturiautospurghi/cubit/create_referrals/create_referrals_cubit.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/web/create_event_web_widgets.dart';

class CreateReferrals extends StatelessWidget {
  final Event? _event;
  TypeStatus type ;
  late CloudFirestoreService? repository;
  final bool isSlidePanel;
  final Function? onConfirm;
  final VoidCallback? onClose;

  CreateReferrals( [this._event, this.type = TypeStatus.create, this.repository ])
      : isSlidePanel = false,
        onConfirm = null,
        onClose = null;

  CreateReferrals.slidePanel({
    super.key,
    required Event event,
    required this.type,
    required this.onConfirm,
    required this.onClose,
    this.repository,
  }) : _event = event, isSlidePanel = true;

  @override
  Widget build(BuildContext context) {
    if(this.repository == null) this.repository = context.read<CloudFirestoreService>();
    return new BlocProvider(
        create: (_) => CreateReferralsCubit(repository!,this._event, this.type),
        child:  _formReferralsWidget(isSlidePanel: isSlidePanel, onConfirm: onConfirm, onClose: onClose));
  }
}

class _formReferralsWidget extends StatelessWidget {
  final bool isSlidePanel;
  final Function? onConfirm;
  final VoidCallback? onClose;

  static const iconWidth = 30.0; //HANDLE

  _formReferralsWidget({this.isSlidePanel = false, this.onConfirm, this.onClose});

  Widget _sectionLabel(String text, {bool required = false}) => Row(children: [
    Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
        color: Color(0xFF374151))),
    if (required) const Text(' *', style: TextStyle(color: red, fontWeight: FontWeight.bold)),
  ]);

  Widget _lField({required String label, required Widget child,
      bool req = false, bool hasError = false, String? errTxt}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(label, required: req),
        const SizedBox(height: 4),
        child,
        if (hasError && errTxt != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(errTxt, style: const TextStyle(
                color: red, fontSize: 9.5, fontWeight: FontWeight.w500)),
          ),
      ]);

  InputDecoration _ideco({String? hint, bool err = false}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12.5, color: grey_dark),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: err ? red : grey_light)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: err ? red : grey_light)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: err ? red : yellow)),
    fillColor: err ? const Color(0xFFFEF2F2) : Colors.white,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    isDense: true,
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateReferralsCubit>();

    if (isSlidePanel) {
      return PanelLayout(
        width: 360,
        icon: Icons.person,
        title: cubit.isNew() ? 'NUOVO REFERENTE' : 'MODIFICA REFERENTE',
        onClose: onClose!,
        onCancel: onClose!,
        onConfirm: () {
          if (cubit.validateAndSave()) {
            onConfirm!(cubit.state.customer.referral);
          }
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: black,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cubit.isNew() ? 'NUOVO REFERENTE' : 'MODIFICA REFERENTE',
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: white,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 18, color: white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: cubit.formKeyReferralsInfo,
                  child: Column(
                    children: [
                      _lField(
                        label: 'Nome Referente',
                        req: true,
                        child: TextFormField(
                          initialValue: cubit.state.customer.referral.name,
                          style: const TextStyle(fontSize: 12.5, color: black),
                          decoration: _ideco(hint: "Inserisci il nome del referente..."),
                          validator: (value) =>
                              string.isNullOrEmpty(value) ? 'Inserisci un valore valido' : null,
                          onSaved: (value) => cubit.state.customer.referral.name = value ?? "",
                        ),
                      ),
                      const SizedBox(height: 14),
                      _lField(
                        label: 'Telefono Referente',
                        req: true,
                        child: TextFormField(
                          initialValue: cubit.state.customer.referral.phone,
                          style: const TextStyle(fontSize: 12.5, color: black),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _ideco(hint: "Inserisci il telefono..."),
                          validator: (value) =>
                              string.isNullOrEmpty(value) || !string.isPhoneNumber(value!) ? 'Inserisci un numero valido' : null,
                          onSaved: (value) => cubit.state.customer.referral.phone = value ?? "",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    void onExit(bool result,{ dynamic event }) {
      PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : event, 'res': result});
    }

    return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: white,
        appBar: AppBar(
          title: Text(cubit.isNew()? 'NUOVO REFERENTE' : 'MODIFICA REFERENTE',style: title_rev,),
          leading: new BackButton(
              onPressed: () => onExit(false,event: cubit.state.event)
          ),
          actions: [
            Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(15.0),
                child: ElevatedButton(
                  child: new Text('CONFERMA', style: subtitle_rev),
                  style: raisedButtonStyle.copyWith(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))),
                  ),
                  onPressed: (){
                    if(cubit.validateAndSave()){
                      onExit(true,event: cubit.state.event);
                    }
                  },
                )),
          ],
        ),
        body: BlocBuilder<CreateReferralsCubit, CreateReferralsState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FadeAnimation(
                          1.2, Text(
                            'Inserisci le informazioni del referente.',
                            style: title.copyWith(fontSize: 16)
                        ),
                        ), SizedBox(height: 10,),
                        FadeAnimation(1.2, SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: FadeAnimation(
                                1.2, new Form(
                                key: cubit
                                    .formKeyReferralsInfo,
                                child: new Column(children: <Widget>[
                                  Row(children: <Widget>[
                                    Container(
                                      width: iconWidth,
                                      margin: EdgeInsets.only(right: 20.0),
                                      child: Icon(Customer.getIconTypology(Customer.REFERENTE).icon, color: black, size: iconWidth),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        maxLines: 1,
                                        cursorColor: black,
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: 'Aggiungi nome del referente',
                                          hintStyle: subtitle,
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(width: 2.0,
                                              style: BorderStyle.solid,),),),
                                        initialValue: cubit.state.customer.referral.name,
                                        validator: (value) =>
                                        string.isNullOrEmpty(value) ? 'Inserisci un valore valido' : null,
                                        onSaved: (value) => cubit.state.customer.referral.name = value ?? "",
                                      ),
                                    ),
                                  ]),
                                  Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
                                  Row(children: <Widget>[
                                    Container(
                                      width: iconWidth,
                                      margin: EdgeInsets.only(right: 20.0),
                                      child: Icon(Icons.phone, color: black, size: iconWidth),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        maxLines: 1,
                                        cursorColor: black,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          hintText: 'Aggiungi telefono del referente',
                                          hintStyle: subtitle,
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(width: 2.0,
                                              style: BorderStyle.solid,),),),
                                        initialValue: cubit.state.customer.referral.phone,
                                        validator: (value) =>
                                        !string.isNullOrEmpty(value) && !string.isPhoneNumber(value!) ? 'Inserisci un valore valido' : null,
                                        onSaved: (value) => cubit.state.customer.referral.phone = value ?? "",
                                      ),
                                    ),
                                  ]),
                                ])
                            )
                            ))
                        )
                      ]));
            })
    );
  }
}
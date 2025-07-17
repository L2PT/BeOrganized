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

class CreateReferrals extends StatelessWidget {
  final Event? _event;
  TypeStatus type ;
  late CloudFirestoreService? repository;

  CreateReferrals( [this._event, this.type = TypeStatus.create, this.repository ]);

  @override
  Widget build(BuildContext context) {
    if(this.repository == null) this.repository = context.read<CloudFirestoreService>();
    return new BlocProvider(
        create: (_) => CreateReferralsCubit(repository!,this._event, this.type),
        child:  _formReferralsWidget());
  }
}

class _formReferralsWidget extends StatelessWidget {

  static const iconWidth = 30.0; //HANDLE



  @override
  Widget build(BuildContext context) {

    void onExit(bool result,{ dynamic event }) {
      PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : event, 'res': result});
    }

    return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: white,
        appBar: AppBar(
          title: Text(context.read<CreateReferralsCubit>().isNew()? 'NUOVO REFERENTE' : 'MODIFICA REFERENTE',style: title_rev,),
          leading: new BackButton(
              onPressed: () => onExit(false,event: context.read<CreateReferralsCubit>().state.event)
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
                    if(context.read<CreateReferralsCubit>().validateAndSave()){
                      onExit(true,event: context.read<CreateReferralsCubit>().state.event);
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
                                key: context
                                    .read<CreateReferralsCubit>()
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
                                        initialValue: context.read<CreateReferralsCubit>().state.customer.referral.name,
                                        validator: (value) =>
                                        string.isNullOrEmpty(value) ? 'Inserisci un valore valido' : null,
                                        onSaved: (value) => context.read<CreateReferralsCubit>().state.customer.referral.name = value ?? "",
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
                                        initialValue: context.read<CreateReferralsCubit>().state.customer.referral.phone,
                                        validator: (value) =>
                                        !string.isNullOrEmpty(value) && !string.isPhoneNumber(value!) ? 'Inserisci un valore valido' : null,
                                        onSaved: (value) => context.read<CreateReferralsCubit>().state.customer.referral.phone = value ?? "",
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
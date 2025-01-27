import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/animation/fade_animation.dart';
import 'package:venturiautospurghi/cubit/create_address/create_address_cubit.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class CreateAddress extends StatelessWidget {
  final Event? _event;
  TypeStatus type ;
  late CloudFirestoreService? repository;

  CreateAddress( [this._event, this.type = TypeStatus.create, this.repository ]);

  @override
  Widget build(BuildContext context) {
    if(this.repository == null) this.repository = context.read<CloudFirestoreService>();
    return new BlocProvider(
        create: (_) => CreateAddressCubit(repository!,this._event, this.type),
        child:  _formAddressWidget());
  }
}

class _formAddressWidget extends StatelessWidget {

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
          title: Text(context.read<CreateAddressCubit>().isNew()? 'NUOVO INDIRIZZO' : 'MODIFICA INDIRIZZO',style: title_rev,),
          leading: new BackButton(
              onPressed: () => onExit(false,event: context.read<CreateAddressCubit>().state.event)
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
                    if(context.read<CreateAddressCubit>().validateAndSave()){
                      onExit(true,event: context.read<CreateAddressCubit>().state.event);
                    }
                  },
                )),
          ],
        ),
        body: BlocBuilder<CreateAddressCubit, CreateAddressState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FadeAnimation(
                          1.2, Text(
                            'Inserisci le informazioni del indirizzo.',
                            style: title.copyWith(fontSize: 16)
                        ),
                        ), SizedBox(height: 10,),
                        FadeAnimation(1.2, SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: FadeAnimation(
                                1.2, new Form(
                                key: context
                                    .read<CreateAddressCubit>()
                                    .formKeyAddressInfo,
                                child: new Column(children: <Widget>[
                                  Row(children: <Widget>[
                                    Container(
                                      width: iconWidth,
                                      margin: EdgeInsets.only(right: 20.0),
                                      child: Icon(Icons.contact_phone, color: black, size: iconWidth),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        maxLines: 1,
                                        cursorColor: black,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: InputDecoration(
                                          hintText: 'Aggiungi telefono del cliente',
                                          hintStyle: subtitle,
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(width: 2.0,
                                              style: BorderStyle.solid,),),),
                                        initialValue: context.read<CreateAddressCubit>().state.customer.address.phone,
                                        validator: (value) =>
                                        !string.isNullOrEmpty(value) && !string.isPhoneNumber(value!) ? 'Inserisci un valore valido' : null,
                                        onSaved: (value) => context.read<CreateAddressCubit>().state.customer.address.phone = value ?? "",
                                      ),
                                    ),
                                  ]),
                                  Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
                                  Row(children: <Widget>[
                                    Container(
                                      width: iconWidth,
                                      margin: EdgeInsets.only(right: 20.0),
                                      child: Icon(Icons.map, color: black, size: iconWidth,),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          onChanged: (text) => context.read<CreateAddressCubit>().getLocations(text),
                                          keyboardType: TextInputType.multiline,
                                          maxLines: null,
                                          cursorColor: black,
                                          controller: context.read<CreateAddressCubit>().addressController,
                                          autofillHints: [AutofillHints.addressCity],
                                          validator: (value) => string.isNullOrEmpty(value)? 'Inserisci un valore valido' : null,
                                          onSaved: (value) => context.read<CreateAddressCubit>().state.customer.address.address = value ?? "",
                                          decoration: InputDecoration(
                                            hintText: 'Aggiungi posizione',
                                            hintStyle: subtitle,
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 2.0,
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                          ),
                                        )),
                                  ]),
                                  _geoLocationOptionsList(),
                                ])
                            )
                            ))
                        )
                      ]));
            })
    );
  }

}

class _geoLocationOptionsList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    List<Widget> buildAutocompleteList() =>
        context.read<CreateAddressCubit>().state.locations.map((location) {
          return GestureDetector(
              onTap: () => context.read<CreateAddressCubit>().setAddress(location),
              child: Container(
                  margin: EdgeInsets.only(bottom: 10, top: 10, left: 30),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 15),
                        child: Icon(
                          Icons.place,
                          color: grey_dark,
                          size: 25,
                        ),
                      ),
                      Expanded(child: Text(location, style: label.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      )
                    ],
                  )));
        }).toList();

    return BlocBuilder<CreateAddressCubit, CreateAddressState>(
      buildWhen: (previous, current) => previous.locations != current.locations,
      builder: (context, state) {
        return (context.read<CreateAddressCubit>().state.locations) != List<String>.empty() ?
        Row(
          children: <Widget>[
            Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 15),
                  child: Column(
                    children: buildAutocompleteList(),
                  ),
                ))
          ],
        ) : Container();
      },
    );
  }
}
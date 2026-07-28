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
import 'package:venturiautospurghi/views/widgets/web/create_event_web_widgets.dart';

class CreateAddress extends StatelessWidget {
  final Event? _event;
  TypeStatus type ;
  late CloudFirestoreService? repository;
  final bool isSlidePanel;
  final Function? onConfirm;
  final VoidCallback? onClose;

  CreateAddress( [this._event, this.type = TypeStatus.create, this.repository ])
      : isSlidePanel = false,
        onConfirm = null,
        onClose = null;

  CreateAddress.slidePanel({
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
        create: (_) => CreateAddressCubit(repository!,this._event, this.type),
        child:  _formAddressWidget(isSlidePanel: isSlidePanel, onConfirm: onConfirm, onClose: onClose));
  }
}

class _formAddressWidget extends StatelessWidget {
  final bool isSlidePanel;
  final Function? onConfirm;
  final VoidCallback? onClose;

  static const iconWidth = 30.0; //HANDLE

  _formAddressWidget({this.isSlidePanel = false, this.onConfirm, this.onClose});

  Widget _sectionLabel(String text, {bool required = false}) => Row(children: [
    Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
        color: black)),
    if (required) const Text(' *', style: TextStyle(color: red, fontWeight: FontWeight.bold)),
  ]);

  Widget _lField({required String label, required Widget child,
      String? description,
      bool req = false, bool hasError = false, String? errTxt}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(label, required: req),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 10, color: black, fontWeight: FontWeight.normal)),
        ],
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
    final cubit = context.read<CreateAddressCubit>();

    Widget addressListElement(String address){
      return Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 10.0),
              padding: EdgeInsets.all(3.0),
              child: Icon(Icons.place, color: white,),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                color: black,
              ),
            ),
            Expanded( // Usa Expanded per occupare lo spazio rimanente
              child: Text(
                address,
                maxLines: 2, // Limita a 2 righe
                overflow: TextOverflow.ellipsis, // Aggiungi "..." se il testo è troppo lungo
                style: subtitle.copyWith(fontSize: 13, color: grey_dark),
              ),
            ),
            IconButton(
                icon: Icon(Icons.delete, color: black, size: 25),
                onPressed: () => cubit.removeAddressOnCustomer(address)
            )
          ],
        ),
      );
    }

    void onExit(bool result,{ dynamic event }) {
      PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : event, 'res': result});
    }

    if (isSlidePanel) {
      return PanelLayout(
        width: 360,
        icon: Icons.place,
        title: cubit.isNew() ? 'NUOVO INDIRIZZO' : 'MODIFICA INDIRIZZO',
        onClose: onClose!,
        onCancel: onClose!,
        onConfirm: () {
          if (cubit.validateAndSave()) {
            onConfirm!(cubit.state.customer.address);
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
                    cubit.isNew() ? 'NUOVO INDIRIZZO' : 'MODIFICA INDIRIZZO',
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
                  key: cubit.formKeyAddressInfo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lField(
                        label: 'Telefono di Riferimento',
                        child: TextFormField(
                          initialValue: cubit.state.customer.address.phone,
                          style: const TextStyle(fontSize: 12.5, color: black),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _ideco(hint: "Inserisci telefono..."),
                          validator: (value) =>
                              !string.isNullOrEmpty(value) && !string.isPhoneNumber(value!) ? 'Inserisci un valore valido' : null,
                          onSaved: (value) => cubit.state.customer.address.phone = value ?? "",
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<CreateAddressCubit, CreateAddressState>(
                        builder: (context, state) {
                          final addresses = state.customer.address.address;
                          if (addresses.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Indirizzi'),
                              const SizedBox(height: 8),
                              ...addresses.map((addr) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: black,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.place, color: yellow, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        addr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: black,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete, color: black, size: 18),
                                      onPressed: () => cubit.removeAddressOnCustomer(addr),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      BlocBuilder<CreateAddressCubit, CreateAddressState>(
                        builder: (context, state) {
                          final hasNoAddress = state.customer.address.address.isEmpty;
                          return _lField(
                            label: 'Aggiungi Posizione',
                            req: hasNoAddress,
                            description: hasNoAddress ? 'Inserisci almeno un indirizzo' : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: cubit.addressController,
                                    style: const TextStyle(fontSize: 12.5, color: black),
                                    decoration: _ideco(hint: "Cerca posizione..."),
                                    onChanged: (text) => cubit.getLocations(text),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: cubit.addAddressOnCustomer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    elevation: 0,
                                  ),
                                  child: const Icon(Icons.add, size: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      BlocBuilder<CreateAddressCubit, CreateAddressState>(
                        buildWhen: (previous, current) => previous.locations != current.locations,
                        builder: (context, state) {
                          if (state.locations.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 150),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: state.locations.length,
                                itemBuilder: (context, index) {
                                  final loc = state.locations[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(loc, style: const TextStyle(fontSize: 11.5, color: black)),
                                    onTap: () => cubit.setAddress(loc),
                                  );
                                },
                              ),
                            ),
                          );
                        },
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
                                  context.read<CreateAddressCubit>().state.customer.address.address.isNotEmpty?Align(
                                    alignment: Alignment.centerLeft,  // Allinea a sinistra
                                    child: Text("Indirizzi", style: title.copyWith(color: black, fontSize: 16),),
                                  ):Container(),
                                  BlocBuilder<CreateAddressCubit, CreateAddressState>(
                                      buildWhen: (previous, current) => previous.customer.toString() != current.customer.toString(),
                                      builder: (context, state) {
                                        return Column(children: <Widget>[...(context.read<CreateAddressCubit>().state.customer.address.address).asMap()
                                            .map((i, address) =>
                                            MapEntry(i,addressListElement(address))).values.toList()]);
                                      }),
                                  Row(children: <Widget>[
                                    Container(
                                      width: iconWidth,
                                      margin: EdgeInsets.only(right: 20.0),
                                      child: Icon(Icons.place, color: black, size: iconWidth,),
                                    ),
                                    Expanded(
                                        child: TextFormField(
                                          onChanged: (text) => context.read<CreateAddressCubit>().getLocations(text),
                                          keyboardType: TextInputType.multiline,
                                          maxLines: null,
                                          cursorColor: black,
                                          controller: context.read<CreateAddressCubit>().addressController,
                                          autofillHints: [AutofillHints.addressCity],
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
                                    IconButton(
                                        icon: Icon(Icons.add, color: black),
                                        onPressed: context.read<CreateAddressCubit>().addAddressOnCustomer
                                    )
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
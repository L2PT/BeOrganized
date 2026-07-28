import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/animation/fade_animation.dart';
import 'package:venturiautospurghi/cubit/create_customer/create_customer_cubit.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/card_address_widget.dart';
import 'package:venturiautospurghi/views/widgets/card_referral_widget.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';
import 'package:venturiautospurghi/views/widgets/stepper_widget.dart';

import '../../utils/extensions.dart';
import 'create_address_view.dart';
import 'create_customer_web.dart';
import 'create_referrals_view.dart';

class CreateCustomer extends StatelessWidget {
  final Event? event;
  int currentStep;
  TypeStatus type ;
  static const iconWidth = 30.0;
  late CloudFirestoreService? repository;


  CreateCustomer({this.event, this.currentStep = 0, this.type = TypeStatus.create, this.repository});

  @override
  Widget build(BuildContext context) {
    if(this.repository == null) this.repository = context.read<CloudFirestoreService>();
    return new BlocProvider(
        create: (_) => CreateCustomerCubit(repository!,event, currentStep, type ),
        child:  _formCustomerWidget(this.type)
    );
  }
}
class _formCustomerWidget extends StatelessWidget {

  TypeStatus type ;

  _formCustomerWidget(this.type);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateCustomerCubit>();
    return new Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        appBar: new AppBar(
          leading: new BackButton(
              onPressed: () => PlatformUtils.backNavigator(context,
                  <String,dynamic>{'objectParameter' : context.read<CreateCustomerCubit>().getEvent(), 'res': false})
          ),
          title: new Text(
            this.type == TypeStatus.create ? 'NUOVO CLIENTE' : this.type == TypeStatus.copy?'COPIA CLIENTE' : 'MODIFICA CLIENTE',
            style: title_rev,
          ),
          actions: !PlatformUtils.isMobile ? [
            BlocBuilder<CreateCustomerCubit, CreateCustomerState>(
              builder: (context, state) {
                final hasAddresses = state.customer.addresses.isNotEmpty;
                return ElevatedButton(
                  onPressed: hasAddresses ? () async {
                    final cubit = context.read<CreateCustomerCubit>();
                    if (await cubit.saveCustomer()) {
                      if( !(await SuccessAlert(context, text: "Cliente salvato!").show())){
                        cubit.state.event.customer = cubit.state.customer;
                        PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : cubit.getEvent(), 'res': true});
                      }
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: black,
                    backgroundColor: yellow, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Salva Cliente', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: white)),
                );
              }
            ),
            const SizedBox(width: 16),
          ] : null,
        ),
        body: BlocBuilder<CreateCustomerCubit, CreateCustomerState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return context.select((CreateCustomerCubit cubit) => cubit.state.isLoading())?
              LoadingScreen() : 
              PlatformUtils.isMobile 
                  ? _CustomerStepper(context)
                  : const CreateCustomerWeb();
            })
    );
  }


}

class _CustomerStepper extends StatelessWidget{

  final BuildContext context;

  void _onSavePressed() async {
    if (await context.read<CreateCustomerCubit>().saveCustomer())
      if( !(await SuccessAlert(context, text: "Cliente salvato!").show())){
        context.read<CreateCustomerCubit>().state.event.customer = context.read<CreateCustomerCubit>().state.customer;
        PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : context.read<CreateCustomerCubit>().getEvent(), 'res': true});
      }
  }

  _CustomerStepper(this.context);

  @override
  Widget build(BuildContext context) {
    int currentStep = context.read<CreateCustomerCubit>().state.currentStep;
    List<StepIcon> getEventSteps() => [
      StepIcon(
        state: currentStep==0?StepState.editing:StepState.complete,
        isActive: currentStep >= 0,
        icon: Icons.person,
        title: Text('Tipologia'),
        content:  ConstrainedBox(
            constraints: new BoxConstraints(
              minHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 230:450,
            ),
            child: _tipologyCustomer()),
      ),
      StepIcon(
          state: currentStep==1?StepState.editing:currentStep<1?StepState.indexed:StepState.complete,
          isActive: currentStep >= 1,
          icon: Icons.assignment,
          title: Text('Informazioni base'),
          content: Theme(
            data: ThemeData(
                colorScheme: Theme.of(context).colorScheme,
                textTheme: Theme.of(context).textTheme
            ), child: ConstrainedBox(
              constraints: new BoxConstraints(
                minHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 230:450,
              ),
              child: _formBasiclyInfo()),
          )),
      StepIcon(
          state: currentStep==2?StepState.editing:currentStep<2?StepState.indexed:StepState.complete,
          isActive: currentStep >= 2,
          icon: Icons.place,
          title: Text('Indirizzo'),
          content: Theme(
            data: ThemeData(
                colorScheme: Theme.of(context).colorScheme,
                textTheme: Theme.of(context).textTheme
            ), child: ConstrainedBox(
              constraints: new BoxConstraints(
                minHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 230:450,
              ),
              child: _formAddressInfo()),
          )),
    ];

    int numSteps = getEventSteps().length;
    return Theme(
        data: ThemeData(
            primarySwatch: Colors.grey,
            textTheme: Theme.of(context).textTheme.copyWith(bodySmall: stepper_title_nofocus),
            colorScheme: ColorScheme.light(
              primary: Colors.black,
            )
        ),
        child: StepperIcon(
          elevation: 0.5,
          type: StepperType.horizontal,
          steps: getEventSteps(),
          currentStep: context.read<CreateCustomerCubit>().state.currentStep,
          onStepCancel: context.read<CreateCustomerCubit>().onStepCancel,
          onStepContinue: () => context.read<CreateCustomerCubit>().onStepContinue(numSteps),
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
                    if (controls.currentStep != numSteps-1)
                      ElevatedButton(
                        child: new Text('Continua', style: button_card),
                        style: raisedButtonStyle,
                        onPressed:
                            () {
                          DateTime currentTime = _.DateUtils.now().toLocal();
                          if(!Utils.isDoubleClick(context.read<CreateCustomerCubit>().firstClick, currentTime)){
                            context.read<CreateCustomerCubit>().setFirstClick(currentTime);
                            FocusScope.of(context).unfocus();
                            controls.onStepContinue!();
                          }
                        },
                      ),
                    if (controls.currentStep > 1)
                      ElevatedButton(
                          style: raisedButtonStyle,
                          child: new Text('Salva', style: button_card),
                          onPressed: context.read<CreateCustomerCubit>().state.customer.addresses.isNotEmpty?(){
                            if(!Utils.isDoubleClick(context.read<CreateCustomerCubit>().firstClick, _.DateUtils.now())){_onSavePressed();}}:null),
                  ],
                ));
          },
        ));


  }


}
class _tipologyCustomer extends StatelessWidget{

  @override
  Widget build(BuildContext context) {

    Widget sigleTypeWidget(String key, String value){
      return MouseRegion(
          cursor: SystemMouseCursors.click,
          child:GestureDetector(
            onTap: () => context.read<CreateCustomerCubit>().onSelectedType(key),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: context.read<CreateCustomerCubit>().state.customer.typology == key ? Colors.grey.shade900 : Colors.grey.shade100,
                border: Border.all(
                  color: context.read<CreateCustomerCubit>().state.customer.typology == key ? yellow : yellow.withValues(alpha:0),
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset((PlatformUtils.isMobile?'assets/':'/typologyCustomer/')+value, height: 100),
                    SizedBox(height: 5,),
                    Text(key, style: title.copyWith(fontSize: 18, color: context.read<CreateCustomerCubit>().state.customer.typology == key ? white: black),)
                  ]
              ),
            ),
          )
      );
    }

    return
      Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FadeAnimation(
              1.2,  Text(
                'Seleziona la tipologia di cliente che vuoi creare.',
                style: title.copyWith(fontSize: 16)
            ),
            ),
            ConstrainedBox(
              constraints: new BoxConstraints(
                minHeight: 200,
                maxHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 280:420,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                    ),
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: context.read<CreateCustomerCubit>().types.length,
                    itemBuilder: (BuildContext context, int index) {
                      return FadeAnimation((1.0 + index) / 4,
                          sigleTypeWidget(context.read<CreateCustomerCubit>().types.keys.elementAt(index),
                              context.read<CreateCustomerCubit>().types.values.elementAt(index)));
                    }
                ),
              ),
            ),
          ]
      );
  }
}

class _formBasiclyInfo extends StatelessWidget{
  double iconWidth = CreateCustomer.iconWidth;
  @override
  Widget build(BuildContext context) {
    Customer customer = context.read<CreateCustomerCubit>().state.customer;

    Widget companyWidgets(){
      return Wrap(
          children: <Widget>[
            Row(children: <Widget>[
              Container(
                width: iconWidth,
                margin: EdgeInsets.only(right: 20.0),
                child: Icon(Icons.account_box, color: black, size: iconWidth),
              ),
              Expanded(
                child: TextFormField(
                  maxLines: 1,
                  cursorColor: black,
                  decoration: InputDecoration(
                    hintText: 'Inserisci il nome del cliente',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                  initialValue: customer.name,
                  validator: (value) =>  string.isNullOrEmpty(value)? 'Inserisci un valore valido': null,
                  onSaved: (value) => customer.name = value??"",
                ),
              ),
            ]),
            Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
            Row(children: <Widget>[
              Container(
                width: iconWidth,
                margin: EdgeInsets.only(right: 20.0),
                child: Icon(FontAwesomeIcons.solidAddressCard, color: black, size: iconWidth),
              ),
              Expanded(
                child:
                TextFormField(
                  maxLines: 1,
                  cursorColor: black,
                  decoration: InputDecoration(
                    hintText: 'Inserisci la partitva Iva del cliente',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                  initialValue: customer.partitaIva,
                  onSaved: (value) => customer.partitaIva = value??"",
                ),
              ),
            ])
          ]);
    }

    Widget personWidgets(){
        return Wrap(
            children: <Widget>[
              Row(children: <Widget>[
                Container(
                  width: iconWidth,
                  margin: EdgeInsets.only(right: 20.0),
                  child: Icon(Icons.account_box, color: black, size: iconWidth),
                ),
                Expanded(
                  child: TextFormField(
                    maxLines: 1,
                    cursorColor: black,
                    decoration: InputDecoration(
                      hintText: 'Inserisci il nome del cliente',
                      hintStyle: subtitle,
                      border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                    initialValue: customer.name,
                    validator: (value) =>  string.isNullOrEmpty(value)? 'Inserisci un valore valido': null,
                    onSaved: (value) => customer.name = value??"",
                  ),
                ),
              ]),
              Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
              Row(children: <Widget>[
                Container(
                  width: iconWidth,
                  margin: EdgeInsets.only(right: 20.0),
                  child: Icon(Icons.account_box, color: black, size: iconWidth),
                ),
                Expanded(
                  child: TextFormField(
                    maxLines: 1,
                    cursorColor: black,
                    decoration: InputDecoration(
                      hintText: 'Inserisci il cognome del cliente',
                      hintStyle: subtitle,
                      border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                    initialValue: customer.surname,
                    onSaved: (value) => customer.surname = value??"",
                  ),
                ),
              ]),
              Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
              Row(children: <Widget>[
                Container(
                  width: iconWidth,
                  margin: EdgeInsets.only(right: 20.0),
                  child: Icon(FontAwesomeIcons.solidAddressCard, color: black, size: iconWidth),
                ),
                Expanded(
                  child:
                  TextFormField(
                    maxLines: 1,
                    cursorColor: black,
                    decoration: InputDecoration(
                      hintText: 'Inserisci il codicefiscale del cliente',
                      hintStyle: subtitle,
                      border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                    initialValue: customer.codFiscale,
                    validator: (value) => !string.isNullOrEmpty(value) && value!.length != 16?
                    'Il campo \'Codice Fiscale\' non è corretto' : null,
                    onSaved: (value) => customer.codFiscale = value??"",
                  ),
                ),
              ]),
            ]);
    }


    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FadeAnimation(
            1.2,  Text(
              'Inserisci le informazioni base del ' + context.read<CreateCustomerCubit>().state.customer.typology.toLowerCase() +'.',
              style: title.copyWith(fontSize: 16)
          ),
          ), SizedBox(height: 10,),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: FadeAnimation(
                  1.2,  new Form(
                  key: context.read<CreateCustomerCubit>().formKeyBasiclyInfo,
                  child: new Column(children: <Widget>[
                    customer.isCompany()? companyWidgets(): personWidgets(),
                    Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
                    Row(children: <Widget>[
                      Container(
                        width: iconWidth,
                        margin: EdgeInsets.only(right: 20.0),
                        child: Icon(Icons.mail, color: black, size: iconWidth),
                      ),
                      Expanded(
                        child: TextFormField(
                          maxLines: 1,
                          cursorColor: black,
                          decoration: InputDecoration(
                            hintText: 'Inserisci la mail del cliente',
                            hintStyle: subtitle,
                            border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                          initialValue: customer.email,
                          validator: (value) =>  !string.isNullOrEmpty(value) && !string.isEmail(value!)? 'Inserisci un valore valido': null,
                          onSaved: (value) => customer.email = value??"",
                        ),
                      ),
                    ]),
                  ])
              )
              ))
        ]);

  }

}

class _formAddressInfo extends StatelessWidget{
  double iconWidth = CreateCustomer.iconWidth;

  void _showAddressDialog(BuildContext context, CreateCustomerCubit cubit, {Address? address}) {
    final isModify = address != null;
    final event = isModify ? cubit.getEventCustomer(address) : cubit.getEvent();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: whitebackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            child: CreateAddress.slidePanel(
              event: event,
              type: isModify ? TypeStatus.modify : TypeStatus.create,
              repository: context.read<CloudFirestoreService>(),
              onConfirm: (newAddress) {
                cubit.addAddress(newAddress, toReplace: address);
                Navigator.pop(dialogContext);
                cubit.forceRefresh();
              },
              onClose: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }

  void _showReferralDialog(BuildContext context, CreateCustomerCubit cubit, {Referrals? referral}) {
    final isModify = referral != null;
    final event = isModify ? cubit.getEventReferrals(referral) : cubit.getEvent();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: whitebackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            child: CreateReferrals.slidePanel(
              event: event,
              type: isModify ? TypeStatus.modify : TypeStatus.create,
              repository: context.read<CloudFirestoreService>(),
              onConfirm: (newReferral) {
                cubit.addReferral(newReferral, toReplace: referral);
                Navigator.pop(dialogContext);
                cubit.forceRefresh();
              },
              onClose: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateCustomerCubit>();

    Widget phoneListElement(String phone){
      return Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 10.0),
              padding: EdgeInsets.all(3.0),
              child: Icon(Icons.phone, color: white,),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                color: black,
              ),
            ),
            Text(phone, style: title.copyWith(color: black, fontSize: 16)),
            Expanded(child: Container(),),
            IconButton(
                icon: Icon(Icons.delete, color: black, size: 25),
                onPressed: () => context.read<CreateCustomerCubit>().removePhoneOnCustomer(phone)
            )
          ],
        ),
      );
    }

    Widget addressListElement(Address address){
      final cubit = context.read<CreateCustomerCubit>();
      return Container(
        margin: EdgeInsets.only(top: 10, left: PlatformUtils.isMobile?5:20, right: PlatformUtils.isMobile?5:20),
        child: CardAddress(address: address,
          onclickMode: cubit.onClickModeAddress(),
          selectItem: cubit.onSelectItemAddress(address),
          actionButton: true,
          onTapAction: () => cubit.selectAddressOnCustomer(address),
          onDeleteAction: () => cubit.removeAddressOnCustomer(address),
          onEditAction: () {
            if (PlatformUtils.isMobile) {
              PlatformUtils.navigator(context, Constants.createAddressViewRoute, <String, dynamic>{
                'objectParameter' : cubit.getEventCustomer(address),
                'currentStep': cubit.state.currentStep,
                'typeStatus' : TypeStatus.modify, 'context' : context,
                'callback' : cubit.forceRefresh });
            } else {
              _showAddressDialog(context, cubit, address: address);
            }
          },
        )
      );
    }

    Widget referralListElement(Referrals referral){
      final cubit = context.read<CreateCustomerCubit>();
      return Container(
        margin: EdgeInsets.only(top: 10, left: PlatformUtils.isMobile?5:20, right: PlatformUtils.isMobile?5:20),
        child: CardReferrals(referral: referral,
          onclickMode: cubit.onClickModeReferral(),
          selectItem: cubit.onSelectItemReferral(referral),
          actionButton: true,
          onTapAction: () => cubit.selectReferralsOnCustomer(referral),
          onDeleteAction: () => cubit.removeReferralOnCustomer(referral),
          onEditAction: () {
            if (PlatformUtils.isMobile) {
              PlatformUtils.navigator(context, Constants.createReferralsViewRoute, <String, dynamic>{
                'objectParameter' : cubit.getEventReferrals(referral),
                'currentStep': cubit.state.currentStep,
                'typeStatus' : TypeStatus.modify, 'context' : context,
                'callback' : cubit.forceRefresh });
            } else {
              _showReferralDialog(context, cubit, referral: referral);
            }
          },
        )
      );
    }

    Widget phoneList(){
      return Column(children: [
        Row(children: <Widget>[
          Container(
            width: iconWidth,
            margin: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.phone,
                color: black, size: iconWidth),
          ),
          Expanded(
            child: TextFormField(
              key: context.read<CreateCustomerCubit>().formFieldPhoneKey,
              maxLines: 1,
              cursorColor: black,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Aggiungi i telefoni del cliente',
                hintStyle: subtitle,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    width: 2.0,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              validator: (value) => !string.isNullOrEmpty(value) && !string.isPhoneNumber(value!)
                  ? 'Inserisci un valore valido'
                  : null,
            ),
          ),
          IconButton(
              icon: Icon(Icons.add, color: black),
              onPressed: context.read<CreateCustomerCubit>().addPhoneOnCustomer
          )
        ]),
        BlocBuilder<CreateCustomerCubit, CreateCustomerState>(
            buildWhen: (previous, current) => previous.customer.toString() != current.customer.toString(),
            builder: (context, state) {
              return Column(children: <Widget>[...(context.read<CreateCustomerCubit>().state.customer.phones).asMap()
                  .map((i, phone) =>
                  MapEntry(i,phoneListElement(phone))).values.toList()]);
            }),
      ],);
    }

    Widget referralsList(){
      return Column(children: [
        Row(children: <Widget>[
          Container(
            width: iconWidth,
            margin: EdgeInsets.only(right: 20.0),
            child: Icon(Customer.getIconTypology(Customer.REFERENTE).icon, color: black, size: iconWidth),
          ),
          Expanded(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0),
                child: Text("Aggiungi un referente", style: label)),
          ),
          IconButton(
              icon: Icon(Icons.add, color: black),
              onPressed: () {
                if (PlatformUtils.isMobile) {
                  cubit.addReferralsOnCustomer(context);
                } else {
                  _showReferralDialog(context, cubit);
                }
              })
        ]),
        BlocBuilder<CreateCustomerCubit, CreateCustomerState>(
            buildWhen: (previous, current) => previous.status != current.status || previous.customer.toString() != current.customer.toString() || previous.event.customer.toString() != current.event.customer.toString() ,
            builder: (context, state) {
              return Column(children: <Widget>[...(context.read<CreateCustomerCubit>().state.customer.referrals).asMap()
                  .map((i, referral) =>
                  MapEntry(i,referralListElement(referral))).values.toList()]);
            }),
      ],);
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FadeAnimation(
            1.2,  Text(
              'Inserisci l\' indirizzo del ' + context.read<CreateCustomerCubit>().state.customer.typology.toLowerCase() +'.',
              style: title.copyWith(fontSize: 16)
          ),
          ), SizedBox(height: 10,),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: FadeAnimation(
                  1.2,  new Form(
                  key: context.read<CreateCustomerCubit>().formKeyAddressInfo,
                  child: new Column(children: <Widget>[
                    context.read<CreateCustomerCubit>().state.customer.isAdministrator()?referralsList():phoneList(),
                    Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
                    Row(children: <Widget>[
                      Container(
                        width: iconWidth,
                        margin: EdgeInsets.only(right: 20.0),
                        child: Icon(Icons.place, color: black, size: iconWidth),
                      ),
                      Expanded(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                            child: Text("Aggiungi indirizzo", style: label)),
                      ),
                      IconButton(
                          icon: Icon(Icons.add, color: black),
                          onPressed: () {
                            if (PlatformUtils.isMobile) {
                              cubit.addAddressOnCustomer(context);
                            } else {
                              _showAddressDialog(context, cubit);
                            }
                          })
                    ]),
                    BlocBuilder<CreateCustomerCubit, CreateCustomerState>(
                        buildWhen: (previous, current) => previous.status != current.status || previous.customer.toString() != current.customer.toString() || previous.event.customer.toString() != current.event.customer.toString() ,
                        builder: (context, state) {
                          return Column(children: <Widget>[...(context.read<CreateCustomerCubit>().state.customer.addresses).asMap()
                              .map((i, address) =>
                              MapEntry(i,addressListElement(address))).values.toList()]);
                        }),
                    SizedBox(height: 10,)
                  ])
              )
              ))
        ]);

  }

}

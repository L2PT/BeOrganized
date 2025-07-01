import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/animation/fade_animation.dart';
import 'package:venturiautospurghi/cubit/create_user/create_user_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_auth_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';
import 'package:venturiautospurghi/views/widgets/stepper_widget.dart';

import '../../utils/extensions.dart';

class CreateUser extends StatelessWidget {
  final Event? event;
  int currentStep;
  TypeStatus type ;
  static const iconWidth = 30.0;
  late CloudFirestoreService? repository;
  late FirebaseAuthService? authService;


  CreateUser({this.event, this.currentStep = 0, this.type = TypeStatus.create, this.repository, this.authService});

  @override
  Widget build(BuildContext context) {
    if(this.repository == null) this.repository = context.read<CloudFirestoreService>();
    if(this.authService == null) this.authService = context.read<FirebaseAuthService>();
    return new BlocProvider(
        create: (_) => CreateUserCubit(repository!, authService!, event, currentStep, type ),
        child:  _formUserWidget(this.type)
    );
  }
}
class _formUserWidget extends StatelessWidget {

  TypeStatus type ;

  _formUserWidget(this.type);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        appBar: new AppBar(
          leading: new BackButton(
              onPressed: () => PlatformUtils.backNavigator(context)
          ),
          title: new Text(
            this.type == TypeStatus.create ? 'NUOVO UTENTE' : this.type == TypeStatus.copy?'COPIA UTENTE' : 'MODIFICA UTENTE',
            style: title_rev,
          ),
        ),
        body: BlocBuilder<CreateUserCubit, CreateUserState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return context.select((CreateUserCubit cubit) => cubit.state.isLoading())?
              LoadingScreen() : _UserStepper(context);
            })
    );
  }


}

class _UserStepper extends StatelessWidget{

  final BuildContext context;

  void _onSavePressed() async {
    if (await context.read<CreateUserCubit>().saveUser())
      if( !(await SuccessAlert(context, text: "Utente salvato!").show())){
        context.read<CreateUserCubit>().state.event.operator = context.read<CreateUserCubit>().state.user;
        PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : context.read<CreateUserCubit>().getEvent(), 'res': true});
      }
  }

  _UserStepper(this.context);

  @override
  Widget build(BuildContext context) {
    int currentStep = context.read<CreateUserCubit>().state.currentStep;
    List<StepIcon> getUserSteps() => [
      StepIcon(
        state: currentStep==0?StepState.editing:StepState.complete,
        isActive: currentStep >= 0,
        icon: Icons.person,
        title: Text('Tipologia'),
        content:  ConstrainedBox(
            constraints: new BoxConstraints(
              minHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 230:450,
            ),
            child: _tipologyUser()),
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
    ];

    int numSteps = getUserSteps().length;
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
          steps: getUserSteps(),
          currentStep: context.read<CreateUserCubit>().state.currentStep,
          onStepCancel: context.read<CreateUserCubit>().onStepCancel,
          onStepContinue: () => context.read<CreateUserCubit>().onStepContinue(numSteps),
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
                          DateTime currentTime = DateTime.now().toLocal();
                          if(!Utils.isDoubleClick(context.read<CreateUserCubit>().firstClick, currentTime)){
                            context.read<CreateUserCubit>().setFirstClick(currentTime);
                            FocusScope.of(context).unfocus();
                            controls.onStepContinue!();
                          }
                        },
                      ),
                    if (controls.currentStep > 0)
                      ElevatedButton(
                          style: raisedButtonStyle,
                          child: new Text('Salva', style: button_card),
                          onPressed: (){
                            if(!Utils.isDoubleClick(context.read<CreateUserCubit>().firstClick, DateTime.now())){_onSavePressed();}}),
                  ],
                ));
          },
        ));


  }


}
class _tipologyUser extends StatelessWidget{

  @override
  Widget build(BuildContext context) {

    Widget sigleTypeWidget(String key, String value){
      return MouseRegion(
          cursor: SystemMouseCursors.click,
          child:GestureDetector(
            onTap: () => context.read<CreateUserCubit>().onSelectedType(key),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: context.read<CreateUserCubit>().state.user.typology == key ? Colors.grey.shade900 : Colors.grey.shade100,
                border: Border.all(
                  color: context.read<CreateUserCubit>().state.user.typology == key ? yellow : yellow.withValues(alpha:0),
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset((PlatformUtils.isMobile?'assets/':'/typologyUser/')+value, height: 100),
                    SizedBox(height: 5,),
                    Text(key, style: title.copyWith(fontSize: 18, color: context.read<CreateUserCubit>().state.user.typology == key ? white: black),)
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
                'Seleziona la tipologia di utente che vuoi creare.',
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
                    itemCount: context.read<CreateUserCubit>().types.length,
                    itemBuilder: (BuildContext context, int index) {
                      return FadeAnimation((1.0 + index) / 4,
                          sigleTypeWidget(context.read<CreateUserCubit>().types.keys.elementAt(index),
                              context.read<CreateUserCubit>().types.values.elementAt(index)));
                    }
                ),
              ),
            ),
          ]
      );
  }
}

class _formBasiclyInfo extends StatelessWidget{
  double iconWidth = CreateUser.iconWidth;
  @override
  Widget build(BuildContext context) {
    Account user = context.read<CreateUserCubit>().state.user;

    Widget vehicleWidgets(){
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
                    hintText: 'Inserisci il nome del veicolo',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                  initialValue: user.surname,
                  validator: (value) =>  string.isNullOrEmpty(value)? 'Inserisci un valore valido': null,
                  onSaved: (value) => user.surname = value??"",
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
                    hintText: 'Inserisci la targa del veicolo',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                  initialValue: user.targa,
                  onSaved: (value) => user.targa = value??"",
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
                    hintText: 'Inserisci il nome del utente',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                  initialValue: user.name,
                  validator: (value) =>  string.isNullOrEmpty(value)? 'Inserisci un valore valido': null,
                  onSaved: (value) => user.name = value??"",
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
                    hintText: 'Inserisci il cognome del utente',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                  initialValue: user.surname,
                  onSaved: (value) => user.surname = value??"",
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
                    hintText: 'Inserisci il codicefiscale del utente',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                  initialValue: user.codFiscale,
                  validator: (value) => !string.isNullOrEmpty(value) && value!.length != 16?
                  'Il campo \'Codice Fiscale\' non è corretto' : null,
                  onSaved: (value) => user.codFiscale = value??"",
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
              'Inserisci le informazioni base del ' + context.read<CreateUserCubit>().state.user.typology.toLowerCase() +'.',
              style: title.copyWith(fontSize: 16)
          ),
          ), SizedBox(height: 10,),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: FadeAnimation(
                  1.2,  new Form(
                  key: context.read<CreateUserCubit>().formKeyBasiclyInfo,
                  child: new Column(children: <Widget>[
                    user.isVehicle()? vehicleWidgets(): personWidgets(),
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
                            hintText: 'Inserisci la mail del ${user.isVehicle() ? 'veicolo' : 'utente'}',
                            hintStyle: subtitle,
                            border: UnderlineInputBorder(borderSide: BorderSide(width: 2.0, style: BorderStyle.solid,),),),
                          initialValue: user.email,
                          validator: (value) =>  string.isNullOrEmpty(value) && !string.isEmail(value!)? 'Inserisci un valore valido': null,
                          onSaved: (value) => user.email = value??"",
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: 'Inserisci la mail del ${user.isVehicle() ? 'veicolo' : 'utente'}',
                            hintStyle: subtitle,
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                width: 2.0,
                                style: BorderStyle.solid,
                              ),
                            ),
                          ),
                          initialValue: user.phone,
                          onSaved: (value) => user.phone = value??"",
                          validator: (value) => !string.isNullOrEmpty(value) && !string.isPhoneNumber(value!)
                              ? 'Inserisci un valore valido'
                              : null,
                        ),
                      ),
                    ]),
                  ])
              )
              ))
        ]);

  }

}

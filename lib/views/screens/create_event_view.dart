import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/animation/fade_animation.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/create_event/create_event_cubit.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/colors.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/card_customer_widget.dart';
import 'package:venturiautospurghi/views/widgets/list_tile_operator.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';
import 'package:venturiautospurghi/views/widgets/platform_datepicker.dart';
import 'package:venturiautospurghi/views/widgets/stepper_widget.dart';

class CreateEvent extends StatelessWidget {
  final Event? _event;
  int currentStep;
  DateTime? dateSelect;
  TypeStatus type;
  static const iconWidth = 30.0; //HANDLE

  CreateEvent([this._event, this.currentStep = 0, this.dateSelect, this.type = TypeStatus.create ]);

  @override
  Widget build(BuildContext context) {
    var repository = context.read<CloudFirestoreService>();
    var account = context.select((AuthenticationBloc bloc)=>bloc.account!);
    print("create event: " + this._event.toString());
    return new BlocProvider(
        create: (_) => CreateEventCubit(repository, account, _event, currentStep, dateSelect, type: type),
        child: PopScope(
            onPopInvoked: (bool)=>PlatformUtils.backNavigator(context),
            child: new Scaffold(
                extendBody: true,
                resizeToAvoidBottomInset: false,
                appBar: new AppBar(
                  leading: new BackButton(
                    onPressed: () => PlatformUtils.backNavigator(context)
                  ),
                  title: new Text(
                    this.type == TypeStatus.create? 'NUOVO INTERVENTO' : this.type == TypeStatus.copy?'COPIA INTERVENTO' : 'MODIFICA INTERVENTO',
                    style: title_rev,
                  ),
                ),
                body: BlocBuilder<CreateEventCubit, CreateEventState>(
                    buildWhen: (previous, current) => previous != current,
                    builder: (context, state) {
                      return context.select((CreateEventCubit cubit) => cubit.state.isLoading())?
                      LoadingScreen() : _EventStepper(context);
                    })
        ))
    );
  }
}


class _EventStepper extends StatelessWidget{

  final BuildContext context;

  void _onSavePressed() async {
    if (await context.read<CreateEventCubit>().saveEvent())
      if( !(await SuccessAlert(context, text: "Incarico salvato e inviato!").show()))
        PlatformUtils.backNavigator(context, <String,dynamic>{'objectParameter' : context.read<CreateEventCubit>().state.event, 'res': true});
  }

  _EventStepper(this.context);

  @override
  Widget build(BuildContext context) {
    int currentStep = context.read<CreateEventCubit>().state.currentStep;
    List<StepIcon> getEventSteps() => [
      StepIcon(
        state: currentStep==0?StepState.editing:StepState.complete,
        isActive: currentStep >= 0,
        icon: FontAwesomeIcons.helmetSafety,
        title: Text('Categoria'),
        content:  ConstrainedBox(
            constraints: new BoxConstraints(
              minHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 230:450,
            ),
            child: _tipologyEvent()),
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
          icon: Icons.person,
          title: Text('Cliente'),
          content: Theme(
              data: ThemeData(
                  colorScheme: Theme.of(context).colorScheme,
                  textTheme: Theme.of(context).textTheme
              ), child: ConstrainedBox(
              constraints: new BoxConstraints(
                minHeight:PlatformUtils.isMobile?MediaQuery.of(context).size.height - 230:450,
              ),
              child: _formClientInfo())
          )
      ),
      StepIcon(
          state: currentStep==3?StepState.editing:currentStep<3?StepState.indexed:StepState.complete,
          isActive: currentStep >= 3,
          icon: FontAwesomeIcons.helmetSafety,
          title: Text('Assegnazione'),
          content: Theme(
              data: ThemeData(
              colorScheme: Theme.of(context).colorScheme, textTheme: Theme.of(context).textTheme
            ), child: ConstrainedBox(
              constraints: new BoxConstraints(
                minHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 230:450,
              ),
              child:_formAssignedList())
          )
      ),
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
        currentStep: context.read<CreateEventCubit>().state.currentStep,
        onStepCancel: context.read<CreateEventCubit>().onStepCancel,
        onStepContinue: () => context.read<CreateEventCubit>().onStepContinue(numSteps),
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
                onPressed: (controls.currentStep > 0 && context.read<CreateEventCubit>().state.event.category.isEmpty)?null:
                    () {
                      DateTime currentTime = DateTime.now().toLocal();
                    if(!Utils.isDoubleClick(context.read<CreateEventCubit>().firstClick, currentTime)){
                        context.read<CreateEventCubit>().setFirstClick(currentTime);
                        FocusScope.of(context).unfocus();
                        controls.onStepContinue!();
                    }
                },
              ),
              if (controls.currentStep > 2)
                ElevatedButton(
                  style: raisedButtonStyle,
                  child: new Text(context.read<CreateEventCubit>().state.event.operator != null && context.read<CreateEventCubit>().state.event.operator!.id.isNotEmpty? 'Salva': 'Salva in bozza', style: button_card),
                  onPressed: (){
                    if(!Utils.isDoubleClick(context.read<CreateEventCubit>().firstClick, DateTime.now())){_onSavePressed();}}),
            ],
          ));
        },
    ));


  }


}
class _tipologyEvent extends StatelessWidget{

  @override
  Widget build(BuildContext context) {

    Widget contentVerticalTypeWidget(String text, String key, String value){
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset((PlatformUtils.isMobile?'assets/':'/tipology/')+value, height: 100),
            SizedBox(height: 5,),
            Text(text, style: title.copyWith(color: context.read<CreateEventCubit>().state.event.typology == key ? white: black),)
          ]
      );
    }

    Widget contentHorizontalTypeWidget(String text, String key, String value){
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset((PlatformUtils.isMobile?'assets/':'/tipology/')+value, height: 100),
            SizedBox(height: 5,),
            Text(text, style: title.copyWith(color: context.read<CreateEventCubit>().state.event.typology == key ||
                (context.read<CreateEventCubit>().state.event.withCartel && key == "contratto-cartello") ? white: black),)
          ]
      );
    }

    Widget sigleTypeWidget(String key, String value, String text, bool isVertical){
      return MouseRegion(
          cursor: SystemMouseCursors.click,
          child:GestureDetector(
            onTap: () => context.read<CreateEventCubit>().onSelectedType(key),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: context.read<CreateEventCubit>().state.event.typology == key ||
                    (context.read<CreateEventCubit>().state.event.withCartel && key == "contratto-cartello") ? Colors.grey.shade900 : Colors.grey.shade100,
                border: Border.all(
                  color: context.read<CreateEventCubit>().state.event.typology == key ||
                      (context.read<CreateEventCubit>().state.event.withCartel && key == "contratto-cartello") ? yellow : yellow.withOpacity(0),
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: isVertical?contentVerticalTypeWidget(text,key,value):contentHorizontalTypeWidget(text, key, value),
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
                'Seleziona la tipologia di incarico che vuoi creare.',
                style: title.copyWith(fontSize: 16)
            ),
            ),
            ConstrainedBox(
              constraints: new BoxConstraints(
                minHeight: 200,
                maxHeight: PlatformUtils.isMobile?MediaQuery.of(context).size.height - 280:250,
              ),
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 20.0,
                        mainAxisSpacing: 20.0,
                      ),
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: context.read<CreateEventCubit>().types.length,
                      itemBuilder: (BuildContext context, int index) {
                        return FadeAnimation((1.0 + index) / 4,
                            sigleTypeWidget(context.read<CreateEventCubit>().types.keys.elementAt(index),
                                context.read<CreateEventCubit>().types.values.elementAt(index),
                                context.read<CreateEventCubit>().types.keys.elementAt(index) ,true),);
                      }
                  ),
                ),
            ),
            Visibility(
              visible: context.read<CreateEventCubit>().state.event.typology == "Contratto",
              child: Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child:FadeAnimation(1.0 / 4,
                    sigleTypeWidget("contratto-cartello","contratto-cartello.png", "Con cartello", false))
              )
            )
          ]
      );
  }
}

class _formBasiclyInfo extends StatelessWidget{
  double iconWidth = CreateEvent.iconWidth;
  @override
  Widget build(BuildContext context) {
    Event event = context.read<CreateEventCubit>().state.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
      FadeAnimation(
      1.2,  Text(
          'Inserisci le informazioni base del ' + context.read<CreateEventCubit>().state.event.typology.toLowerCase() +'.',
          style: title.copyWith(fontSize: 16)
        ),
      ), SizedBox(height: 10,),
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: FadeAnimation(
          1.2,  new Form(
            key: context.read<CreateEventCubit>().formKeyBasiclyInfo,
            child: new Column(children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: TextFormField(
                  cursorColor: black,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Titolo',
                    hintStyle: subtitle,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.0,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  initialValue: event.title,
                  validator:(value) => string.isNullOrEmpty(value)?
                  'Il campo \'Titolo\' è obbligatorio' : null,
                  onSaved: (value) => event.title = value??"",
                ),
              ),
              Divider(height: 40, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
              Row(children: <Widget>[
                Container(
                  width: iconWidth,
                  margin: EdgeInsets.only(right: 20.0),
                  child: Icon(Icons.assignment, color: black, size: iconWidth),
                ),
                Expanded(
                  child: TextFormField(
                    maxLines: null,
                    cursorColor: black,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                        hintText: 'Aggiungi note',
                        hintStyle: subtitle,
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            width: 2.0,
                            style: BorderStyle.solid,
                          ),)),
                    initialValue: event.description,
                    validator: (value) => null,
                    onSaved: (value) => event.description = value??"",
                  ),
                ),
              ]),
              Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
              Row(children: <Widget>[
                Container(
                  width: iconWidth,
                  margin: EdgeInsets.only(right: 20.0),
                  child: Icon(
                    Icons.file_upload,
                    color: black,
                    size: iconWidth,
                  ),
                ),
                Expanded(
                  child: Text("Aggiungi documenti", style: label,),
                ),
                IconButton(
                    icon: Icon(Icons.add, color: black),
                    onPressed: () => context.read<CreateEventCubit>().openFileExplorer()
                ),
              ]),
              _fileStorageList(),
              Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
              _categoriesList(),
            ])
          )
        ))
    ]);

  }

}

class _formClientInfo extends StatelessWidget{
  double iconWidth = CreateEvent.iconWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FadeAnimation(
            1.2,  Text(
              'Inserisci le informazioni sul cliente del ' + context.read<CreateEventCubit>().state.event.typology.toLowerCase() +'.',
              style: title.copyWith(fontSize: 16)
          ),
          ), SizedBox(height: 10,),
          BlocBuilder<CreateEventCubit, CreateEventState>(
          buildWhen: (previous, current) => previous.event.toString() != current.event.toString(),
          builder: (context, state) {
          return context.read<CreateEventCubit>().state.event.customer.name.isNotEmpty?
          FadeAnimation( 1.2, SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: FadeAnimation(
                  1.2, CardCustomer(customer: context.read<CreateEventCubit>().state.event.customer,
                onEditAction: () => PlatformUtils.navigator(context, Constants.createCustomerViewRoute, <String, dynamic>{
                      'objectParameter' : context.read<CreateEventCubit>().state.event,
                      'currentStep': context.read<CreateEventCubit>().state.currentStep,
                      'nextStep': 0,
                      'typeStatus' : TypeStatus.modify}),
                onDeleteAction: () => context.read<CreateEventCubit>().removeCustomer(),
              )
              ))
          ):Row(children: <Widget>[
            Container(
              width: iconWidth,
              margin: EdgeInsets.only(right: 20.0),
              child: Icon(Icons.person, color: black, size: iconWidth),
            ),
            Expanded(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                  child: Text("Aggiungi cliente",
                      style: label)),
            ),
            context.read<CreateEventCubit>().canModify ? IconButton(
                icon: Icon(Icons.add, color: black),
                onPressed: () => context.read<CreateEventCubit>().addCustomerDialog(context)
            ) : Container()
          ]);}),
        ]);
  }
  
}

class _formAssignedList extends StatelessWidget{
  double iconWidth = CreateEvent.iconWidth;

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
      FadeAnimation(
      1.2,  Text(
        'Calendarizza e assegna il ' + context.read<CreateEventCubit>().state.event.typology.toLowerCase() +' agli operatori.',
        style: title.copyWith(fontSize: 16)
    ),
    ), SizedBox(height: 10,),
    FadeAnimation( 1.2,SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: FadeAnimation(
        1.2,  new Form(
          key: context.read<CreateEventCubit>().formKeyAssignedInfo,
          child: new Column(children: <Widget>[
            _timeControls(),
            Divider(height: 20, indent: 20, endIndent: 20, thickness: 2, color: grey_light2),
            Row(children: <Widget>[
              Container(
                width: iconWidth,
                margin: EdgeInsets.only(right: 20.0),
                child: Icon(FontAwesomeIcons.helmetSafety, color: black, size: iconWidth),
              ),
              Expanded(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.0),
                    child: Text(context.read<CreateEventCubit>().canModify ? "Aggiungi operatore" : "Operatori",
                        style: label)),
              ),
              context.read<CreateEventCubit>().canModify ? IconButton(
                  icon: Icon(Icons.add, color: black),
                  onPressed: () => context.read<CreateEventCubit>().addOperatorDialog(context)
              ) : Container()
            ]),
            BlocBuilder<CreateEventCubit, CreateEventState>(
              buildWhen: (previous, current) => previous.event.toString() != current.event.toString(),
              builder: (context, state) {
                return Column(children: <Widget>[...(context.read<CreateEventCubit>().state.event.operator != null &&
                    context.read<CreateEventCubit>().state.event.operator!.id.isNotEmpty?
                  [context.read<CreateEventCubit>().state.event.operator!, ...context.read<CreateEventCubit>().state.event.suboperators] :
                  context.read<CreateEventCubit>().state.event.suboperators).asMap().map((i, operator) =>
                  MapEntry(i,ListTileOperator(
                    operator,
                    detailMode: true,
                    position: i,
                    onRemove: context.read<CreateEventCubit>().removeSuboperatorFromEventList,
                    darkStyle: false,
                  ))).values.toList()]);
            }),
          ]))),
    ))]);

  }
}

class _geoLocationOptionsList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    
    List<Widget> buildAutocompleteList() =>
    context.read<CreateEventCubit>().state.locations.map((location) {
      return GestureDetector(
          onTap: () => context.read<CreateEventCubit>().setAddress(location),
          child: Container(
              margin: EdgeInsets.only(bottom: 10, top: 10, left: 45),
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
                  Expanded(child: Text(location, style: label.copyWith(fontWeight: FontWeight.bold),
                  ),
                  )
                ],
              )));
    }).toList();

    return BlocBuilder<CreateEventCubit, CreateEventState>(
      buildWhen: (previous, current) => previous.locations != current.locations,
      builder: (context, state) {
        return (context.read<CreateEventCubit>().state.locations) != List<String>.empty() ?
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

class _fileStorageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    ListView buildFilesList() => ListView.separated(
      separatorBuilder: (context, index) => new Divider(),
      physics: BouncingScrollPhysics(),
      itemCount: context.read<CreateEventCubit>().state.documents.keys.length,
      itemBuilder: (context, index) =>
          ListTile(
            leading: IconButton(icon: Icon(Icons.insert_drive_file, color: black,), onPressed: null,),
            title: new Text(context.read<CreateEventCubit>().state.documents.keys.elementAt(index), style: label,),
            subtitle: new Text(context.read<CreateEventCubit>().state.documents.values.elementAt(index) == null?"Già caricato":"Nuovo", style: subtitle,),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: black,),
              onPressed: () => context.read<CreateEventCubit>().removeDocument(context.read<CreateEventCubit>().state.documents.keys.elementAt(index)),
            ),
          )
    );

    return BlocBuilder<CreateEventCubit, CreateEventState>(
      buildWhen: (previous, current) => previous.documents != current.documents,
      builder: (context, state) {
        return context.read<CreateEventCubit>().state.documents.keys.length > 0? new ConstrainedBox(
              constraints: new BoxConstraints(
                minHeight: 80,
                maxHeight: context.read<CreateEventCubit>().state.documents.keys.length*80,
              ),child: buildFilesList()
        ): Container();
      },
    );
  }
}

class _timeControls extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    Event event = context.watch<CreateEventCubit>().state.event;
    double iconWidth = CreateEvent.iconWidth;

    Widget dateTimeStartPicker() => Row(children: <Widget>[
      Container(
        width: iconWidth,
        margin: EdgeInsets.only(right: 20.0),
      ),
      Expanded(
        child: GestureDetector(
          child: Text( event.start.toString().split(' ').first,
            style: context.read<CreateEventCubit>().canModify ? title.copyWith(fontSize: 16) : subtitle.copyWith(fontSize: 14)),
          onTap: () => context.read<CreateEventCubit>().canModify ?
          PlatformDatePicker.selectDate(context,
            maxTime: DateTime(3000),
            currentTime: event.start,
            onConfirm: (date) => context.read<CreateEventCubit>().state.isAllDay?
              context.read<CreateEventCubit>().setAllDayDate(date):context.read<CreateEventCubit>().setStartDate(date),
          ) : null,
        ),
      ),
      context.read<CreateEventCubit>().state.isAllDay ? Container()
          : Expanded(
        child: GestureDetector(
          child: Text( event.start.toString().split(' ').last.split('.').first.substring(0,5),
            style: context.read<CreateEventCubit>().canModify ? title.copyWith(fontSize: 16) : subtitle.copyWith(fontSize: 14)),
          onTap: () => context.read<CreateEventCubit>().canModify ?
          PlatformDatePicker.selectTime(context,
            minTime: TimeUtils.truncateDate(event.start, "day").add(new Duration(hours: Constants.MIN_WORKTIME)),
            maxTime: TimeUtils.truncateDate(event.start, "day").add(new Duration(hours: Constants.MAX_WORKTIME)).subtract(new Duration(minutes: Constants.WORKTIME_SPAN)),
            currentTime: event.start,
            onConfirm: (time) => {context.read<CreateEventCubit>().setStartTime(time)},
          ) : null,
        ),
      ),
    ]);
    
    Widget dateTimeEndPicker() => context.read<CreateEventCubit>().state.isAllDay ? Container()
        : Row(
      children: <Widget>[
        Container(
          width: iconWidth,
          margin: EdgeInsets.only(right: 20.0),
        ),
        Expanded(
          child: GestureDetector(
            child: Text(event.end.toString().split(' ').first,
              style: context.read<CreateEventCubit>().canModify ? title.copyWith(fontSize: 16) : subtitle.copyWith(fontSize: 14)),
            onTap: () => context.read<CreateEventCubit>().canModify ?
            PlatformDatePicker.selectDate(context,
              minTime: TimeUtils.truncateDate(event.start, "day"),
              maxTime: DateTime(3000),
              currentTime: event.end,
              onConfirm: (date) => context.read<CreateEventCubit>().setEndDate(date),
            ) : null,
          ),
        ),
        Expanded(
          child: GestureDetector(
            child: Text(event.end.toString().split(' ').last.split('.').first.substring(0,5),
              style: context.read<CreateEventCubit>().canModify ? title.copyWith(fontSize: 16) : subtitle.copyWith(fontSize: 14),
            ),
            onTap: () => context.read<CreateEventCubit>().canModify ?
              PlatformDatePicker.selectTime(context,
                minTime: event.start.add(new Duration(minutes: Constants.WORKTIME_SPAN)),
                maxTime: TimeUtils.truncateDate(event.end, "day").add(new Duration(hours: Constants.MAX_WORKTIME)),
                currentTime: event.end,
                onConfirm: (time) => context.read<CreateEventCubit>().setEndTime(time),
              ) : null,
          ),
        )
      ],
    );

    Widget allDayFlag() => Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: iconWidth,
              margin: EdgeInsets.only(right: 20.0),
              child: Icon(Icons.access_time, color: black, size: iconWidth),
            ),
            Expanded(
              child: Text(context
                  .read<CreateEventCubit>()
                  .canModify ? "Tutto il giorno" : "Orario", style: label),
            ),
            context.read<CreateEventCubit>().canModify ?
              Container(
                height: 30,
                alignment: Alignment.centerRight,
                child: FittedBox(
                    fit: BoxFit.fill,
                    child:Switch(
                      inactiveTrackColor: grey_light,
                      value: context.read<CreateEventCubit>().state.isAllDay,
                      activeTrackColor: black,
                      activeColor: yellow,
                      onChanged: context.read<CreateEventCubit>().setAlldayLong
                      )
                )) : Container()
          ],));


    Widget eventScheduled() => Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: iconWidth,
            margin: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.date_range_rounded, color: black, size: iconWidth),
          ),
          Expanded(
              child: Text("Incarico programmato", style: label,),
          ),
          Container(
            height: 30,
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.fill,
              child:Switch(
                inactiveTrackColor: grey_light,
                value: context.read<CreateEventCubit>().state.isScheduled,
                activeTrackColor: black,
                activeColor: yellow,
                onChanged: context.read<CreateEventCubit>().setIsScheduled,
              ),
            ),
          )
        ],
      ),
    );

    return new Form(
      key: context.read<CreateEventCubit>().formTimeControlsKey,
      child: Container(child:
          Column(children: <Widget>[
            context.read<CreateEventCubit>().canModify? eventScheduled() : Container(),
            allDayFlag(),
            dateTimeStartPicker(),
            dateTimeEndPicker(),
          ])
      ) 
    );
  }
}

class _categoriesList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    Widget sigleCategoryWidget(String key, String value){
      return MouseRegion(
          cursor: SystemMouseCursors.click,

        child: GestureDetector(
          onTap: () => context.read<CreateEventCubit>().onSelectedCategory(key),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: context.read<CreateEventCubit>().state.event.category == key ? Colors.grey.shade900 : Colors.grey.shade100,
              border: Border.all(
                color: context.read<CreateEventCubit>().state.event.category == key ? yellow : yellow.withOpacity(0),
                width: 4.0,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5.0)), color: HexColor(value)),
                  ),
                  SizedBox(height: 5,),
                  Text(key,textAlign: TextAlign.center, style: subtitle.copyWith(color: context.read<CreateEventCubit>().state.event.category == key ? white: black,
                      fontWeight: context.read<CreateEventCubit>().state.event.category == key ? FontWeight.bold: FontWeight.normal),)
                ]
            ),
          ),
        )
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FadeAnimation(
            1.0,  Text(
              'Tipologia',
              style: title
          ),
          ),
          Container(
            height:PlatformUtils.isMobile?MediaQuery.of(context).size.height - 650:150,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                  ),
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: context.read<CreateEventCubit>().categories.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FadeAnimation((1.0 + index) / 4,
                        sigleCategoryWidget(context.read<CreateEventCubit>().categories.keys.elementAt(index),
                            context.read<CreateEventCubit>().categories.values.elementAt(index)));
                  }
              ),
            ),
          )
        ]
    );

  }
}
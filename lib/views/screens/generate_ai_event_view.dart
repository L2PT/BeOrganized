import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/animation/fade_animation.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/generate_ai_event/generate_ai_event_cubit.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_success.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';

class GenerateAiEvent extends StatelessWidget {

  DateTime? dateSelect;

  GenerateAiEvent({this.dateSelect});

  @override
  Widget build(BuildContext context) {
    var repository = context.read<CloudFirestoreService>();
    var account = context.select((AuthenticationBloc bloc)=>bloc.account!);
    return new BlocProvider(
        create: (_) => GenerateAiEventCubit(repository, account, dateSelect),
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
                    'GENERA INTERVENTO',
                    style: title_rev,
                  ),
                ),
                body: BlocBuilder<GenerateAiEventCubit, GenerateAiEventState>(
                    buildWhen: (previous, current) => previous != current,
                    builder: (context, state) {
                      return context.select((GenerateAiEventCubit cubit) => cubit.state.isLoading())?
                      LoadingScreen() : _AutomaticEvent(context);
                    })
            ))
    );
  }

}

class _AutomaticEvent extends StatelessWidget{

  final BuildContext context;

  void _onGeneratePressed() async {
    if (await context.read<GenerateAiEventCubit>().generateEvent())
      await SuccessAlert(context, text: "Incarico generato!").show();
    PlatformUtils.backNavigator(context);
    PlatformUtils.navigator(context, Constants.createEventViewRoute, <String, dynamic>{'objectParameter' : context.read<GenerateAiEventCubit>().state.event});
  }

  _AutomaticEvent(this.context);

  @override
  Widget build(BuildContext context) {
    return FadeAnimation(
      1.2,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Form(
          key: context.read<GenerateAiEventCubit>().formKeyBasiclyInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FadeAnimation(
                1.2,
                Text(
                  'Inserisci la descrizione l\'incarico',
                  style: title.copyWith(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                maxLines: 18,
                validator: (value) => string.isNullOrEmpty(value) ? 'Il campo è obbligatorio' : null,
                onSaved: (value) => context.read<GenerateAiEventCubit>().text = value ?? "",
                cursorColor: Colors.black,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Descrizione incarico...',
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
              Spacer(),
              Center(
                child: ElevatedButton(
                  style: raisedButtonStyle,
                  onPressed: _onGeneratePressed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.brain, size: 18, color: white),
                      SizedBox(width: 8),
                      Text('Genera', style: button_card),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );


  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/create_event/create_event_cubit.dart';
import 'package:venturiautospurghi/cubit/generate_ai_event/generate_ai_event_cubit.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/loading_screen.dart';

import 'create_event_mobile.dart';
import 'create_event_web.dart';
class CreateEvent extends StatefulWidget {
  final Event? event;
  final int currentStep;
  final DateTime? dateSelect;
  final TypeStatus type;
  static const iconWidth = 30.0;

  CreateEvent({this.event, this.currentStep = 0, this.dateSelect, this.type = TypeStatus.create });

  @override
  _CreateEventState createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  @override
  Widget build(BuildContext context) {
    var repository = context.read<CloudFirestoreService>();
    var account = context.select((AuthenticationBloc bloc)=>bloc.account!);
    
    return MultiBlocProvider(
      providers: [
        BlocProvider<CreateEventCubit>(
          create: (_) => CreateEventCubit(repository, account, widget.event, widget.currentStep, widget.dateSelect, type: widget.type),
        ),
        BlocProvider<GenerateAiEventCubit>(
          create: (_) => GenerateAiEventCubit(repository, account, widget.dateSelect),
        ),
      ],
      child: PopScope(
        onPopInvoked: (bool)=>PlatformUtils.backNavigator(context),
        child: Builder(
          builder: (innerContext) {
            return Scaffold(
              extendBody: true,
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => PlatformUtils.backNavigator(innerContext)
                ),
                title: Text(
                  widget.type == TypeStatus.create? 'NUOVO INTERVENTO' : widget.type == TypeStatus.copy?'COPIA INTERVENTO' : 'MODIFICA INTERVENTO',
                  style: title_rev,
                ),
                actions: !PlatformUtils.isMobile ? [
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(innerContext).showSnackBar(SnackBar(
                        content: const Text('Bozza salvata!'),
                        backgroundColor: grey_light,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: black, side: const BorderSide(color: grey_light),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Salva Bozza', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: grey_light),),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final cubit = innerContext.read<CreateEventCubit>();
                      if (await cubit.saveEvent(false)) {
                         PlatformUtils.backNavigator(innerContext, <String,dynamic>{'objectParameter' : cubit.state.event, 'res': true});
                      } else {
                         ScaffoldMessenger.of(innerContext).showSnackBar(SnackBar(
                           content: const Text('Errore durante il salvataggio o campi mancanti.', style: label_rev,),
                           backgroundColor: red,
                           behavior: SnackBarBehavior.floating,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: black,
                      backgroundColor: yellow, elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Crea Incarico', style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: white)),
                  ),
                  const SizedBox(width: 16),
                ] : null,
              ),
              body: BlocBuilder<CreateEventCubit, CreateEventState>(
                buildWhen: (previous, current) => previous.isLoading() != current.isLoading(),
                builder: (context, state) {
                  return state.isLoading()
                      ? LoadingScreen() 
                      : PlatformUtils.isMobile
                          ? CreateEventMobile(innerContext)
                          : const CreateEventWeb();
                }
              ),
            );
          }
        ),
      ),
    );
  }
}


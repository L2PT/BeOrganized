import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/mobile_bloc/mobile_bloc.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

part 'persistent_notification_state.dart';

class PersistentNotificationCubit extends Cubit<PersistentNotificationState> {
  final BuildContext context;
  final CloudFirestoreService _databaseRepository;
  final Account _account;
  late Timer safeChecker;
  StreamSubscription<List<Event>>? _eventsSub;

  // these RestoreEvent aren't so clean but i'll accept it
  
  PersistentNotificationCubit(this.context, CloudFirestoreService databaseRepository, Account account, List<Event>? events) :
        _databaseRepository = databaseRepository, _account = account,
        super(PersistentNotificationState(events??[])) {
    _eventsSub?.cancel();
    _eventsSub = _databaseRepository.subscribeEventsByOperatorWaiting(_account.id).listen((waitingEventsList) {
      safeChecker.cancel();
      if(waitingEventsList.length == 0) context.read<MobileBloc>().add(RestoreEvent());
      emit(PersistentNotificationState(waitingEventsList));
    });
    safeChecker = new Timer(new Duration(seconds: 5), (){
      if(context.read<MobileBloc>().state is NotificationWaitingState && state.waitingEventsList.length == 0)
        context.read<MobileBloc>().add(RestoreEvent());
    });
  }

  void cardActionConfirm(Event event) {
    _databaseRepository.updateEventField(event.id, Constants.tabellaEventi_stato, EventStatus.Accepted);
    FirebaseMessagingService.sendNotifications(_databaseRepository.updateToken, tokens: event.supervisor!.tokens,
        accountId: event.supervisor!.id,
        style: Constants.notificationSuccessTheme, type: Constants.feedNotification,
        title: "${_account.surname} ${_account.name} ha accettato il lavoro \"${event.title}\"",
        eventId: event.id
    );
    context.read<MobileBloc>().add(RestoreEvent());
  }

  void cardActionRefuse(Event event, String justification) {
    event.motivazione = justification;
    _databaseRepository.refuseEvent(event);
    FirebaseMessagingService.sendNotifications(_databaseRepository.updateToken, tokens: event.supervisor!.tokens,
        accountId: event.supervisor!.id,
        style: Constants.notificationErrorTheme, type: Constants.feedNotification,
        title: "${_account.surname} ${_account.name} ha rifiutato il lavoro \"${event.title}\"",
        eventId: event.id
    );
    context.read<MobileBloc>().add(RestoreEvent());
  }

  @override
  Future<void> close() {
    _eventsSub?.cancel();
    return super.close();
  }

}

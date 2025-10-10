import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

part 'waiting_event_list_state.dart';

class WaitingEventListCubit extends Cubit<WaitingEventListState> {
  final CloudFirestoreService _databaseRepository;
  final Account _account;
  StreamSubscription<List<Event>>? _eventsSub;

  WaitingEventListCubit( CloudFirestoreService databaseRepository, Account account) :
        _databaseRepository = databaseRepository, _account = account,
        super(LoadingEvents()) {
    _eventsSub?.cancel();
    _eventsSub = databaseRepository.subscribeEventsByOperatorWaiting(account.id).listen((waitingEventsList) {
      waitingEventsList.sort((a, b) => a.start.compareTo(b.start));
      emit(ReadyEvents(waitingEventsList));
    });
    Future.delayed(
      Duration(seconds: 2), (){if(state is LoadingEvents) emit(ReadyEvents([]));},
    );
  }

  void cardActionConfirm(Event event) {
    event.status = EventStatus.Accepted;
    _databaseRepository.updateEventField(event.id, Constants.tabellaEventi_stato, EventStatus.Accepted);
    FirebaseMessagingService.sendNotifications(_databaseRepository.updateToken, tokens: event.supervisor!.tokens,
        accountId: event.supervisor!.id,
        style: Constants.notificationSuccessTheme, type: Constants.feedNotification,
        title: "${_account.surname} ${_account.name} ha accettato il lavoro \"${event.title}\"",
        eventId: event.id
    );
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
  }

  @override
  Future<void> close() {
    _eventsSub?.cancel();
    return super.close();
  }

}

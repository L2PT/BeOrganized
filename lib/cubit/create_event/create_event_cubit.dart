import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_messaging_service.dart';
import 'package:venturiautospurghi/repositories/firebase_storage_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/file_utils.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'create_event_state.dart';

class CreateEventCubit extends Cubit<CreateEventState> with CreateEntityUtils {
  final CloudFirestoreService _databaseRepository;
  final Account _account;

  // Form keys
  final GlobalKey<FormState> formKeyAssignedInfo = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyBasiclyInfo = GlobalKey<FormState>();
  final GlobalKey<FormState> formTimeControlsKey = GlobalKey<FormState>();

  // Controllers e configurazioni
  late final TextEditingController addressController;
  late final bool canModify;
  late final Map<String, dynamic> categories;
  late final Map<String, dynamic> types;
  late final Map<int, GlobalKey<FormState>> forms;

  DateTime? firstClick;

  CreateEventCubit(
      this._databaseRepository,
      this._account,
      Event? event,
      int currentStep,
      DateTime? dateSelect, {
        TypeStatus type = TypeStatus.create,
      }) : super(CreateEventState(event, dateSelect: dateSelect)) {
    _initializeCubit(event, currentStep, type);
  }

  // ========================================
  // INIZIALIZZAZIONE
  // ========================================

  void _initializeCubit(Event? event, int currentStep, TypeStatus type) {
    state.currentStep = currentStep;
    fillMapForms();
    setType(type);

    if (event == null) {
      state.event.supervisor = _account;
    }

    canModify = _calculateCanModify();
    categories = _databaseRepository.categories;
    types = _databaseRepository.typesEvent;

    addressController = TextEditingController(
      text: event?.address ?? '',
    );

    if (event?.documentsMap.isNotEmpty ?? false) {
      state.documents = event!.documentsMap;
    }
  }

  bool _calculateCanModify() {
    if (isNew()) return true;

    final start = state.event.start;
    final now = _.DateUtils.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

    return !(_.DateUtils.isAfter(start, now) && _.DateUtils.isBefore(start,fiveMinutesAgo));
  }

  // ========================================
  // SALVATAGGIO EVENTO
  // ========================================

  Future<bool> saveEvent(bool allSeries) async {
    if (state.isLoading()) return false;
    if (!_validateEventTiming()) return false;
    if (!_validateForms()) return false;

    _saveFormData();
    emit(state.assign(status: _formStatus.loading));

    try {
      await _handleEventSave(allSeries);
      await _handleDocuments();
      _sendNotificationIfNeeded();

      _logDebug("Save completed successfully");
      return true;
    } catch (e) {
      _handleSaveError(e);
      return false;
    }
  }

  bool _validateEventTiming() {
    if (_.DateUtils.isBefore(state.event.end,state.event.start)) {
      PlatformUtils.notifyErrorMessage(
          "Seleziona un'orario di fine incarico valido"
      );
      return false;
    }
    return true;
  }

  bool _validateForms() {
    final isTimeValid = formTimeControlsKey.currentState!.validate() || !canModify;
    final isInfoValid = formKeyAssignedInfo.currentState!.validate();
    return isTimeValid && isInfoValid;
  }

  void _saveFormData() {
    formTimeControlsKey.currentState!.save();
    formKeyAssignedInfo.currentState!.save();
  }

  Future<void> _handleEventSave(bool allSeries) async {
    _logDebug("Firebase save ${state.event.start} : ${state.event.end}");

    await _prepareEvent();
    _updateEventStatus();

    if (_isCreatingNewEvent()) {
      await _createEvent();
    } else {
      await _updateEvent(allSeries);
    }

    _logDebug("Firebase save complete");
  }

  Future<void> _prepareEvent() async {
    final event = state.event;

    if (event.customer.id.isEmpty) {
      await _databaseRepository.addCustomer(event.customer);
    }

    event.supervisor = _account;
    event.color = categories[event.category];

    if (event.typology == 'Contratto' && !event.title.contains('Contratto')) {
      event.title = "${event.typology} - ${event.title}";
    }
  }

  void _updateEventStatus() {
    final event = state.event;

    if (event.operator.id.isEmpty) {
      event.status = EventStatus.Bozza;
    } else if (state.isScheduled || state.isRepeat) {
      event.status = EventStatus.Accepted;
    } else if (_isEventInFuture()) {
      event.status = EventStatus.New;
    }
  }

  bool _isCreatingNewEvent() => isNew() || isCopy();

  Future<void> _createEvent() async {
    state.event.id = await _saveEventToRepository(state.event);
  }

  Future<void> _updateEvent(bool allSeries) async  {
    if (state.isRepeat && state.event.recurrenceId.isNotEmpty) {
      await _handleRecurringEvent(allSeries);
    }

    if (state.event.id.isNotEmpty) {
      _updateEventToRepository(state.event);
    } else if (!allSeries) {
      state.event.id = await _saveEventToRepository(state.event);
    }
  }

  // ========================================
  // EVENTI RICORRENTI
  // ========================================

  Future<void> _handleRecurringEvent(bool allSeries) async {
    final eventMaster = await _databaseRepository.getEvent(
        state.event.recurrenceId
    );

    if (eventMaster == null) return;

    if (allSeries) {
      _updateEntireSeries(eventMaster);
    } else {
      _updateSingleOccurrence(eventMaster);
    }
  }

  void _updateEntireSeries(Event eventMaster)  {
    eventMaster.update(state.event);
    eventMaster.start = state.event.recurrenceStart;
    eventMaster.end = state.event.recurrenceEnd;
    _databaseRepository.updateEvent(eventMaster.id, eventMaster);
  }

  void _updateSingleOccurrence(Event eventMaster) {
    if (_hasRecurrenceRulesChanged(eventMaster)) {
      _updateRecurrenceRules(eventMaster);
    }
    state.event.isExcepeted = true;
  }

  bool _hasRecurrenceRulesChanged(Event master) {
    final current = state.event;
    return master.recurrenceDayOfMonth != current.recurrenceDayOfMonth ||
        master.recurrenceIntervalInMonths != current.recurrenceIntervalInMonths ||
        master.start != current.recurrenceStart ||
        master.end != current.recurrenceEnd;
  }

  void _updateRecurrenceRules(Event master) {
    final current = state.event;
    master
      ..start = current.recurrenceStart
      ..end = current.recurrenceEnd
      ..recurrenceDayOfMonth = current.recurrenceDayOfMonth
      ..recurrenceIntervalInMonths = current.recurrenceIntervalInMonths;

    _databaseRepository.updateEvent(master.id, master);
  }

  // ========================================
  // GESTIONE DOCUMENTI
  // ========================================

  Future<void> _handleDocuments() async {
    _logDebug("FireStorage upload");

    final cloudFiles = await _getCloudFiles();
    await _processLocalDocuments(cloudFiles);
    await _deleteOrphanedCloudFiles(cloudFiles);

    _logDebug("FireStorage upload complete");
  }

  Future<List<String>> _getCloudFiles() async {
    final folderId = (state.event.id.isNotEmpty)
        ? state.event.id
        : state.event.recurrenceId;

    final cloudResults = await FirebaseStorageService.listFiles("$folderId/");

    return cloudResults.items.map((file) => file.name).toList();
  }


  Future<void> _processLocalDocuments(List<String> cloudFiles) async {
    for (final entry in state.documents.entries) {
      final name = entry.key;
      final file = entry.value;

      if (file != null) {
        await _uploadDocument(name, file, cloudFiles);
      }
      cloudFiles.remove(name);
    }
  }

  Future<void> _uploadDocument(
      String name,
      dynamic file,
      List<String> cloudFiles,
      ) async {
    final path = "${state.event.id}/$name";

    if (cloudFiles.contains(name)) {
      await FirebaseStorageService.deleteFile(path);
    }

    await FirebaseStorageService.uploadFile(file, path);
  }

  Future<void> _deleteOrphanedCloudFiles(List<String> cloudFiles) async {
    for (final name in cloudFiles) {
      await FirebaseStorageService.deleteFile("${state.event.id}/$name");
    }
  }

  void removeDocument(String name) {
    final newDocs = Map<String, dynamic>.from(state.documents)..remove(name);
    state.event.documentsMap = newDocs;
    state.event.documents = newDocs.keys.toList();
    emit(state.assign(documents: newDocs));
  }

  Future<void> openFileExplorer() async {
    final newDocs = await FileUtils.openFileExplorer(state.documents);
    state.event.documentsMap = newDocs;
    state.event.documents = newDocs.keys.toList();
    emit(state.assign(documents: newDocs));
  }

  // ========================================
  // NOTIFICHE
  // ========================================

  void _sendNotificationIfNeeded() {
    if (!_shouldSendNotification()) return;

    FirebaseMessagingService.sendNotifications(_databaseRepository.updateToken,
      tokens: state.event.operator.tokens,
      accountId: state.event.operator.id,
      title: "Nuovo incarico assegnato",
      eventId: state.event.id,
    );

    _logDebug("FireMessaging notified");
  }

  bool _shouldSendNotification() {
    final event = state.event;

    return event.operator.id.isNotEmpty &&
        !state.isScheduled &&
        !state.isRepeat &&
        _isEventInFuture();
  }

  // ========================================
  // GESTIONE DATE E ORARI
  // ========================================

  void setAlldayLong(bool value) {
    final event = _cloneEvent();

    if (value) {
      final dayStart = TimeUtils.truncateDate(event.start, "day");
      event.start = dayStart.add(Duration(hours: Constants.MIN_WORKTIME));
      event.end = dayStart.add(Duration(hours: Constants.MAX_WORKTIME));
    } else {
      event.end = TimeUtils.addWorkTime(
        event.start,
        const Duration(minutes: Constants.WORKTIME_SPAN),
      );
    }

    _removeAllOperators(event);
    emit(state.assign(event: event, allDayFlag: value));
  }

  void setAllDayDate(DateTime date) {
    final event = _cloneEvent();
    final dayStart = TimeUtils.truncateDate(date, "day");
    event.start = dayStart.add(Duration(hours: Constants.MIN_WORKTIME));
    event.end = dayStart.add(Duration(hours: Constants.MAX_WORKTIME));

    _removeAllOperators(event);
    emit(state.assign(event: event));
  }

  void setStartDate(DateTime date) {
    final event = _cloneEvent();
    event.start = TimeUtils.getStartWorkTimeSpan(from: date);
    event.end = TimeUtils.getStartWorkTimeSpan(from: event.start)
        .olderBetween(event.end);

    _removeAllOperators(event);
    emit(state.assign(event: event));
  }

  void setStartTime(dynamic time) {
    final event = _cloneEvent();
    final dateTime = _convertToDateTime(time, event.start);

    event.start = dateTime;
    event.end = _calculateEndTime(event);

    _removeAllOperators(event);
    emit(state.assign(event: event));
  }

  void setEndDate(DateTime date) {
    final event = _cloneEvent();
    event.end = TimeUtils.truncateDate(date, "day").add(
      Duration(hours: event.end.hour, minutes: event.end.minute),
    );

    _removeAllOperators(event);
    emit(state.assign(event: event));
  }

  void setEndTime(dynamic time) {
    final event = _cloneEvent();
    event.end = _convertToDateTime(time, event.end);

    _removeAllOperators(event);
    emit(state.assign(event: event));
  }

  void setStartRepeatedDate(DateTime date) {
    final event = _cloneEvent();
    final dayStart = TimeUtils.truncateDate(date, "day");

    event.recurrenceStart = dayStart.add(
      Duration(hours: event.start.hour, minutes: event.start.minute),
    );
    event.recurrenceEnd = dayStart.add(
      Duration(hours: event.end.hour, minutes: event.end.minute),
    );

    emit(state.assign(event: event));
  }

  void setEndRepeatedDate(DateTime date) {
    final event = _cloneEvent();
    event.recurrenceEnd = TimeUtils.truncateDate(date, "day").add(
      Duration(hours: event.end.hour, minutes: event.end.minute),
    );

    emit(state.assign(event: event));
  }

  DateTime _convertToDateTime(dynamic time, DateTime baseDate) {
    if (time is TimeOfDay) {
      final converted = DateTimeField.convert(time)!;
      return TimeUtils.truncateDate(baseDate, "day").add(
        Duration(hours: converted.hour, minutes: converted.minute),
      );
    }
    return time as DateTime;
  }

  DateTime _calculateEndTime(Event event) {
    final calculatedEnd = TimeUtils.getStartWorkTimeSpan(from: event.start)
        .olderBetween(event.end);

    return TimeUtils.truncateDate(event.end, "day").add(
      Duration(hours: calculatedEnd.hour, minutes: calculatedEnd.minute),
    );
  }

  // ========================================
  // GESTIONE OPERATORI E CLIENTI
  // ========================================

  void removeSuboperatorFromEventList(Account suboperator) {
    final event = _cloneEvent();
    final subOps = List<Account>.from(event.suboperators);

    if (event.operator.id == suboperator.id) {
      event.operator = Account.empty();
      event.suboperators = [];
    } else if (subOps.isNotEmpty) {
      subOps.removeWhere((element) => element.id == suboperator.id);
      event.suboperators = subOps;
    }

    emit(state.assign(event: event));
  }

  bool checkModifyOperator(Account operator) {
    return operator != state.event.operator && canModify;
  }

  void addOperatorDialog(BuildContext context) {
    if (!_isValidWorkTime(state.event.start.hour, isStart: true)) {
      return PlatformUtils.notifyErrorMessage(
          "Inserisci un'orario iniziale valido"
      );
    }

    if (!_isValidWorkTime(state.event.end.hour, isStart: false)) {
      return PlatformUtils.notifyErrorMessage(
          "Inserisci un'orario finale valido"
      );
    }

    if (formTimeControlsKey.currentState!.validate()) {
      formTimeControlsKey.currentState!.save();
    }

    PlatformUtils.navigator(
      context,
      Constants.operatorListRoute,
      <String, dynamic>{
        'objectParameter': state.event,
        'currentStep': state.currentStep,
        'requirePrimaryOperator': true,
        'context': context,
        'callback': PlatformUtils.isMobile ? forceRefresh : null,
      },
    );
  }

  bool _isValidWorkTime(int hour, {required bool isStart}) {
    if (hour < Constants.MIN_WORKTIME) return false;

    if (isStart) {
      return hour < Constants.MAX_WORKTIME;
    } else {
      return hour <= Constants.MAX_WORKTIME || state.event.isAllDayLong();
    }
  }

  void addCustomerDialog(BuildContext context) {
    PlatformUtils.navigator(
      context,
      Constants.customerListRoute,
      <String, dynamic>{
        'objectParameter': state.event,
        'currentStep': state.currentStep,
        'context': context,
        'callback': PlatformUtils.isMobile
            ? forceRefresh
            : null,
      },
    );
  }

  void removeCustomer() {
    final event = _cloneEvent();
    event.customer = Customer.empty();
    emit(state.assign(event: event));
  }

  void _removeAllOperators(Event event) {
    if (!state.isRepeat) {
      event.operator = Account.empty();
      event.suboperators = [];
    }
  }

  // ========================================
  // GESTIONE FLAGS
  // ========================================

  void setIsScheduled(bool value) {
    state.event.isScheduled = value;
    emit(state.assign(isScheduled: value));
  }

  void setIsRepeated(bool value) {
    state.event.isRepeated = value;
    emit(state.assign(isRepeat: value));
  }

  void setRecurrenceType(String? value) {
    final event = _cloneEvent();
    event.recurrenceType = value ?? Event.RECURRENCE_MENSILE;
    emit(state.assign(event: event));
  }

  // ========================================
  // GESTIONE STEPPER
  // ========================================

  void onStepContinue(int numberStep) {
    if (state.currentStep == numberStep - 1) return;

    final form = forms[state.currentStep];

    if (form != null) {
      if (form.currentState!.validate()) {
        form.currentState!.save();
        _moveToNextStep();
      }
    } else {
      _handleSpecialStepValidation();
    }
  }

  void _handleSpecialStepValidation() {
    if (state.currentStep == 2) {
      if (state.event.customer.name.isEmpty) {
        PlatformUtils.notifyErrorMessage(
            "Nessun cliente selezionato, selezionane uno prima di proseguire"
        );
      } else {
        _moveToNextStep();
      }
    } else {
      _moveToNextStep();
    }
  }

  void _moveToNextStep() {
    emit(state.assign(currentStep: state.currentStep + 1));
  }

  void onStepCancel() {
    if (state.currentStep > 0) {
      emit(state.assign(currentStep: state.currentStep - 1));
    }
  }

  void onStepTapped(int step) {
    emit(state.assign(currentStep: step));
  }

  // ========================================
  // GESTIONE TIPO E CATEGORIA
  // ========================================

  void onSelectedType(String key) {
    final event = _cloneEvent();

    if (key == "contratto-cartello") {
      event.withCartel = !state.event.withCartel;
    } else {
      event.withCartel = false;
      event.typology = key;
    }

    emit(state.assign(event: event));
  }

  void onSelectedCategory(String key) {
    state.event.category = key;
    emit(state.assign(category: key));
  }

  // ========================================
  // HELPERS
  // ========================================

  Event _cloneEvent() {
    return Event.fromMap(
      "",
      "",
      state.event.toMap(),
    );
  }

  Future<String> _saveEventToRepository(Event event) async {
    if (_isEventInFuture()) {
      return await _databaseRepository.addEvent(event);
    } else {
      return await _databaseRepository.addEventPast(event);
    }
  }

  void _updateEventToRepository(Event event) {
    if (_isEventInFuture()) {
      return _databaseRepository.updateEvent(event.id,event);
    } else {
      return _databaseRepository.updateEventPast(event.id,event);
    }
  }

  bool _isEventInFuture() => !_.DateUtils.isBefore(state.event.end,_.DateUtils.now());

  void _handleSaveError(Object error) {
    emit(state.assign(status: _formStatus.normal));
    print(error);
    PlatformUtils.notifyErrorMessage("Errore nella creazione dell'evento.");
  }

  void _logDebug(String message) {
    if (Constants.debug) print(message);
  }

  void forceRefresh() {
    emit(state.assign(status: _formStatus.loading));
    emit(state.assign(status: _formStatus.normal));
  }

  void fillMapForms() {
    forms = {1: formKeyBasiclyInfo};
  }

  void setFirstClick(DateTime date) {
    firstClick = date;
  }
}
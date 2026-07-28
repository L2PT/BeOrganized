import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';

part 'filter_events_state.dart';

class EventsFilterCubit extends Cubit<EventsFilterState> {
  final CloudFirestoreService _databaseRepository;
  final Function callbackFiltersChanged;
  final Function callbackSearchFieldChanged;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late Map<String,dynamic> categories;
  late TextEditingController titleController;
  late TextEditingController addressController;
  late TextEditingController customerController;

  EventsFilterCubit(this._databaseRepository, this.callbackSearchFieldChanged, this.callbackFiltersChanged) : super(EventsFilterState()) {
    titleController = new TextEditingController();
    addressController = new TextEditingController();
    customerController = new TextEditingController();
    initFilters();
  }

  void initFilters(){
    titleController.text = '';
    addressController.text= '';
    customerController.text= '';
    Map<String, FilterWrapper> filters = Map.from(EventsFilterState().filters);
    filters["categories"]!.fieldValue = getCategories();
    emit(state.assign(filters: filters));
  }

  Map<String,bool> getCategories() {
    categories = _databaseRepository.categories;
    Map<String,bool> categoriesSelected = {};
    categories.keys.forEach((category) { categoriesSelected[category] = false; });
    return categoriesSelected;
  }

  void showFiltersBox() {
    emit(state.assign(filtersBoxVisibile:!state.filtersBoxVisibile));
  }

  void addOperatorDialog(BuildContext context) async {
    if(formKey.currentState!.validate()){
      formKey.currentState!.save();
      Event ev = Event.empty();
      ev.suboperators = state.filters["suboperators"]!.fieldValue;
      PlatformUtils.navigator(context, Constants.operatorListRoute, <String,dynamic>{'objectParameter' : ev, 'requirePrimaryOperator' : false, 'context' : context, 'callback' : forceRefresh});
    }
  }

  void removeOperatorFromFilter(Account operator) {
    Map<String, FilterWrapper> filters = Map.from(state.filters);
    List<Account> suboperators = new List.from(state.filters["suboperators"]!.fieldValue);
    suboperators.removeWhere((element) => element.id == operator.id);
    filters["suboperators"] = new FilterWrapper("suboperators", suboperators, state.filters["suboperators"]!.filterFunction);
    emit(state.assign(filters: filters));
  }

  void onSearchFieldTextChanged(String text){
    state.filters["title"]!.fieldValue = text;
    callbackSearchFieldChanged(state.filters);
  }

  setStartDate(DateTime date) {
    state.filters["startDate"]!.fieldValue = TimeUtils.truncateDate(date, "day");
    forceRefresh();
  }

  clearStartDate(){
    state.filters["startDate"]!.fieldValue = null;
    forceRefresh();
  }

  setEndDate(DateTime date) {
    state.filters["endDate"]!.fieldValue = TimeUtils.truncateDate(date, "day");
    forceRefresh();
  }

  clearEndDate(){
    state.filters["endDate"]!.fieldValue = null;
    forceRefresh();
  }

  selectCategory(String name, bool? value){
    if(state.filters["categories"]!.fieldValue.containsKey(name)) {
      state.filters["categories"]!.fieldValue[name] = value ?? false;
    }
    forceRefresh();
  }

  bool getCategorySelected(String categoryName){
    return state.filters["categories"]!.fieldValue[categoryName] ?? false;
  }

  void forceRefresh() {
    if (!isClosed) {
      emit(state.assign(status: _filterStatus.loading));
      emit(state.assign(status: _filterStatus.normal));
    }
  }

  void clearFilters(){
    initFilters();
    notifyFiltersChanged(false);
  }

  void notifyFiltersChanged([bool filtersBoxSave = false]){
    if(filtersBoxSave && formKey.currentState!.validate()){
      formKey.currentState!.save();
      emit(state.assign(filtersBoxVisibile: false));
    }
    callbackFiltersChanged(state.filters);
  }

}
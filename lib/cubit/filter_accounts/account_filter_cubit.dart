import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';

part 'account_filter_state.dart';

class AccountFilterCubit extends Cubit<AccountsFilterState> {
  final Function callbackFiltersChanged;
  final Function callbackSearchFieldChanged;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController codicefiscaleController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  AccountFilterCubit(this.callbackSearchFieldChanged, this.callbackFiltersChanged, Map<String, FilterWrapper> filtersInput) : super(AccountsFilterState()) {
    titleController = new TextEditingController();
    phoneController = new TextEditingController();
    emailController = new TextEditingController();
    codicefiscaleController = new TextEditingController();
    initFilters(filtersInput);
  }

  void initFilters(Map<String, FilterWrapper>? filtersInput){
    titleController.text = '';
    phoneController.text= '';
    // Inizializza i filtri di base
    Map<String, FilterWrapper> filters = Map.from(AccountsFilterState().filters);
    // Sovrascrive le entry con quelle di filtersInput (se presenti)
    if (filtersInput != null) {
      filters.addAll(filtersInput); // Aggiunge e sovrascrive le chiavi esistenti
    }
    emit(state.assign(filters: filters));
  }

  void showFiltersBox() {
    emit(state.assign(filtersBoxVisibile:!state.filtersBoxVisibile));
  }

  void onSearchFieldTextChanged(String text){
    state.filters["searchQuery"]!.fieldValue = text;
    callbackSearchFieldChanged(state.filters);
  }

  void forceRefresh() {
    if (!isClosed) {
      emit(state.assign(status: _filterStatus.loading));
      emit(state.assign(status: _filterStatus.normal));
    }
  }

  void clearFilters(Map<String, FilterWrapper> filtersInput){
    filtersInput.addAll(FilterWrapper.initFilterAccount());
    initFilters(filtersInput);
    if(filtersInput.toString() == state.filters.toString()) showFiltersBox();
    notifyFiltersChanged(filtersInput, false);
  }

  void notifyFiltersChanged(Map<String, FilterWrapper> filtersInput, [bool filtersBoxSave = false] ){
    if(filtersBoxSave && formKey.currentState!.validate()){
      formKey.currentState!.save();
      emit(state.assign(filtersBoxVisibile: false));
    }
    Map<String, FilterWrapper> filters = Map.from(state.filters);
    filters.addAll(filtersInput);
    callbackFiltersChanged(filters);
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:venturiautospurghi/models/filter_wrapper.dart';

part 'customer_filter_state.dart';

class CustomerFilterCubit extends Cubit<CustomersFilterState> {
  final Function callbackFiltersChanged;
  final Function callbackSearchFieldChanged;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController addressController;
  late TextEditingController paritaivaController;
  late TextEditingController codicefiscaleController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  CustomerFilterCubit(this.callbackSearchFieldChanged, this.callbackFiltersChanged, Map<String, FilterWrapper> filtersInput) : super(CustomersFilterState()) {
    titleController = new TextEditingController();
    addressController = new TextEditingController();
    phoneController = new TextEditingController();
    emailController = new TextEditingController();
    paritaivaController = new TextEditingController();
    codicefiscaleController = new TextEditingController();
    initFilters(filtersInput);
  }

  void initFilters(Map<String, FilterWrapper>? filtersInput){
    titleController.text = '';
    addressController.text= '';
    phoneController.text= '';
    // Inizializza i filtri di base
    Map<String, FilterWrapper> filters = Map.from(CustomersFilterState().filters);
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
    emit(state.assign(status: _filterStatus.loading));
    emit(state.assign(status: _filterStatus.normal));
  }

  void clearFilters(Map<String, FilterWrapper> filtersInput){
    filtersInput.addAll(FilterWrapper.initFilterCustomer());
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

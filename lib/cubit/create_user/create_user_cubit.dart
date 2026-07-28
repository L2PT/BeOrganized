import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/repositories/firebase_auth_service.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

part 'create_user_state.dart';

class CreateUserCubit extends Cubit<CreateUserState> with CreateEntityUtils{
  final CloudFirestoreService _databaseRepository;
  final FirebaseAuthService _authService;
  final GlobalKey<FormState> formKeyBasiclyInfo = GlobalKey<FormState>();
  late Map<String,dynamic> types;
  DateTime? firstClick;

  CreateUserCubit(this._databaseRepository, this._authService, Event? event, int currentStep, TypeStatus type)
      : super(CreateUserState(event)) {
    state.currentStep = currentStep;
    setType(type);
    types = _databaseRepository.typesUser;
  }

  void setFirstClick(DateTime date){
    firstClick = date;
  }

  Future<bool> saveUser() async {
    if(state.isLoading()) return Future<bool>(()=>false);
    else if(this.formKeyBasiclyInfo.currentState!.validate()) {
      formKeyBasiclyInfo.currentState!.save();
      emit(state.assign(status: _formStatus.loading));
      try {
        if(this.isNew() || this.isCopy()) {
          return register();
        } else {
          _databaseRepository.updateUser(state.user.id, state.user);
          return true;
        }
      } catch (e) {
        emit(state.assign(status: _formStatus.normal));
        print(e);
        PlatformUtils.notifyErrorMessage("Errore nella creazione del utente.");
      }
    }
    return false;
  }

  Future<bool> register() async{
    return _authService.createAccount(state.user.email, Constants.passwordNewUsers,).then((userFirebase) {
      Account newlyCreated = Account(userFirebase.user!.uid, state.user.name.capitalize(), state.user.surname.capitalize(),
          state.user.email.toLowerCase(), state.user.phone, state.user.codFiscale.toUpperCase(), state.user.targa.toUpperCase(),
          [], [], state.user.typology == Account.RESPONSABILE, state.user.typology);
      _databaseRepository.addOperator(newlyCreated);
      _authService.sendPasswordReset(state.user.email.toLowerCase());
      if(Constants.debug) print("Firebase save complete");
      return true;
    }).catchError((e) {
      PlatformUtils.notifyErrorMessage(e.code == 'email-already-in-use'?"Esiste già un account associato a questa mail.":e.toString());
      return false;
    }).timeout(Duration(seconds: 10), onTimeout: (){
      PlatformUtils.notifyErrorMessage("Creazione account fallita");
      return false;
    });
  }

  /* STEPPER CONTROLLER */
  void onStepContinue(int numberStep){
    if(state.currentStep != numberStep-1){
      GlobalKey<FormState>? form = formKeyBasiclyInfo;
      if(state.currentStep > 0){
        if(form.currentState!.validate()){
          form.currentState!.save();
          emit(state.assign(currentStep: state.currentStep+1));
        }
      }else{
        emit(state.assign(currentStep: state.currentStep+1));
      }
    }
  }

  void onStepCancel(){
    if(state.currentStep != 0){
      formKeyBasiclyInfo.currentState?.reset();
      emit(state.assign(currentStep: state.currentStep-1));
    }
  }

  void onSelectedType(String key){
    state.user.typology = key;
    emit(state.assign(typeSelected: key));
  }

  Event getEvent() => this.state.event;

  void forceRefresh() {
    if (!isClosed) {
      emit(state.assign(status: _formStatus.loading));
      emit(state.assign(status: _formStatus.normal));
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
// import 'package:sms_autofill/sms_autofill.dart';
import 'package:venturiautospurghi/models/auth/email.dart';
import 'package:venturiautospurghi/models/auth/password.dart';
import 'package:venturiautospurghi/models/auth/phone.dart';
import 'package:venturiautospurghi/repositories/firebase_auth_service.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/views/screen_pages/otp_code_view.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authenticationRepository, this._context, this.animationController) : 
        super(const LoginState()){
    animationController.animateBack(1);
  }

  final FirebaseAuthService _authenticationRepository;
  final BuildContext _context;
  final AnimationController animationController;

  void emailChanged(String value) {
    final email = Email(value);
    emit(state.assign(
      email: email
    ));
  }

  void passwordChanged(String value) {
    final password = Password(value);
    emit(state.assign(
        password: password
    ));
  }

  phoneChanged(String value) {
    final phone = Phone("+39"+value);
    emit(state.assign(
        phone: phone
    ));
  }

  Future<void> logIn() async {
    if (state.isInvalid()) return;
    var stateToRestore = state;
    emit(state.assign(status: _formStatus.loading));
    if(stateToRestore.isValid()) {
      try {
        Future<dynamic> loginCallback;
        if(state.isEmailLoginView()) {
          loginCallback = _authenticationRepository.signInWithEmailAndPassword(
            state.email.value,
            state.password.value,
          );
        } else {
 //TODO
          // await SmsAutoFill().listenForCode;
          List<Future<dynamic>> completers = await _authenticationRepository.signInWithPhoneNumber(
            state.phone.value
          );
          completers[0].then((verifier) => 
              Navigator.of(_context).push(MaterialPageRoute(builder: (_) => OtpCode(verifier)))
          );//TODO test without sending a code so adding testcode in console.firebase
          loginCallback = completers[1];
        //TODO throw an error
        }
        loginCallback
            .whenComplete(() => emit(state.assign(status: _formStatus.success)))
            .catchError((error) => emit(state.assign(status: _formStatus.failure)));
      } on Exception {
        emit(state.assign(status: _formStatus.failure));
      }
    } else{
      emit(state.assign(status: stateToRestore.status));
    }
  }

  void switchLoginView() {
    emit(state.assign(loginView: state.isEmailLoginView()?_loginView.phone:_loginView.email));
    animationController.reset();
    animationController.forward();
  }

}
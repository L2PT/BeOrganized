import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth/authuser.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  String? _verificationId;

  FirebaseAuthService([FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignin])
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignin ?? GoogleSignIn();

  AuthUser? _userFromFirebase(User? user) {
    return user != null? 
      AuthUser(
        user.uid,
        user.email??"",
        user.displayName??"",
        user.photoURL??"",
        []) : null;
  }

  Stream<AuthUser?> get onAuthStateChanged {
    return _firebaseAuth.idTokenChanges().map(_userFromFirebase);
  }

  Future<AuthUser> signInWithEmailAndPassword(String email, String password) async { //intentionally unsafe to catch and handle the error in UI
    final authResult = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password).catchError((error){
      throw error;}); //TODO handle login error buuut it doesn't pass up the error
    return _userFromFirebase(authResult.user)!;
  }

  Future<AuthUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth?.idToken,
      accessToken: googleAuth?.accessToken,
    );
    final authResult = await _firebaseAuth.signInWithCredential(credential);
    return _userFromFirebase(authResult.user)!;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }


  /// Create a procedure of login with phone number.
  /// 
  /// @Return Two callbacks:
  ///   * When the [sender] callback is completed the caller can indifferently:
  ///     `- use the argument as a function.`
  ///     `- call [verifyOtp(smsCode)] directly.`
  ///   * The [completer] callback can be completed successfully with the [AuthUser] or with an error.
  List<Future<dynamic>> signInWithPhoneNumber(String phoneNumber) {
    var sender = Completer<Function>();
    var completer = Completer<AuthUser>();
  
    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        print(credential);
        final authResult = await _firebaseAuth.signInWithCredential(credential);
        completer.complete(_userFromFirebase(authResult.user));
      },
      verificationFailed: (FirebaseAuthException error) {
        print(error);
        _verificationId = null;
        completer.completeError(error);
      },
      codeSent: (verificationId, forceResendingToken) async {
        // print(verificationId);
        // _verificationId = verificationId;
        // sender.complete(verifyOtp);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print(verificationId);
    }).catchError((error) {
      print(error);
      _verificationId = null;
      completer.completeError(error);
    });
    return [sender.future, completer.future];
  }

  Future<void> signInWithPhoneNumberWeb(String phoneNumber, Stream<String> codeStream) async {
    ConfirmationResult confirmationResult = await _firebaseAuth.signInWithPhoneNumber(phoneNumber);
    codeStream.listen((code) async {
      UserCredential credential = await confirmationResult.confirm(code);
      // await _firebaseAuth.signInWithCredential(credential); //TO/DO more action needed?
    });
  }

  verifyOtp(String smsCode) async {
    AuthCredential authCred = PhoneAuthProvider.credential( verificationId: _verificationId!, smsCode: smsCode);
    var result = await _firebaseAuth.signInWithCredential(authCred);//TO/DO to remove and use verificationCompleted callback?
  }
  
  Future<AuthUser?> currentUser() async {
    final user = _firebaseAuth.currentUser;
    return _userFromFirebase(user);
  }

  void sendPasswordReset(String email) {
    _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  void sendPhoneVerificationCode(String email) {
    _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> createAccount(String email, String passwordNewUsers) async {
    FirebaseApp app = Firebase.apps.where((element) => element.name == 'Registration').isNotEmpty? Firebase.apps.where((element) => element.name == 'Registration').first: await Firebase.initializeApp(name: 'Registration',options: Firebase.app().options);
    return FirebaseAuth.instanceFor(app: app).createUserWithEmailAndPassword(email: email, password: passwordNewUsers);
  }

  void signInWithToken( token) {
    _firebaseAuth.signInWithCustomToken(token);
  }
}

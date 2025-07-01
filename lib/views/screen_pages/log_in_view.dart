import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:venturiautospurghi/bloc/authentication_bloc/authentication_bloc.dart';
import 'package:venturiautospurghi/cubit/login/login_cubit.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/repositories/firebase_auth_service.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_base.dart';
import 'package:venturiautospurghi/views/widgets/responsive_widget.dart';

class LogIn extends StatefulWidget{

  const LogIn({Key? key}) : super(key: key);

  @override
  _LogInState createState() => _LogInState();
}

class _LogInState extends State<LogIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var authenticationRepository = RepositoryProvider.of<FirebaseAuthService>(context);
    
    Widget content() => Padding(
      padding: EdgeInsets.only(left: 24.0, right: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          logo,
          _messageLogin(),
          _inputFields(),
          SizedBox(height: 8.0),
          _errorText(),
          SizedBox(height: 8.0),
          _loginButton(),
          SizedBox(height: 30.0),
          _LoginPhone(),
        ],
      ),
    );

    Widget loginPage() => Container(
      child: Column(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height / 8,
            width: double.infinity,
            color: black,
            child: CustomPaint(
                painter: PathPainter(),
                child: Container()
            ),
          ), SizedBox(height: 10.0,), ResponsiveWidget(
              largeScreen: Align(alignment: Alignment.topCenter,
                child: Container(
                  width: 1000,
                  child: content(),
                ),),
              smallScreen: content()
          )
        ],
      ),
    );

    return new Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: white,
      body: new BlocProvider(
          create: (_) => LoginCubit(authenticationRepository, context, _controller),
          child: loginPage()
      ),
    );
  }
}

class _inputFields extends StatelessWidget {
  late Animation<Offset> _offScreenAnimation;
  late Animation<Offset> _onScreenAnimation;

  @override
  Widget build(BuildContext context) {

    _onScreenAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: context.read<LoginCubit>().animationController,
      curve: Curves.elasticOut,
    ));
    _offScreenAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: context.read<LoginCubit>().animationController,
      curve: Curves.elasticOut,
    ));
    
    void _move(DragUpdateDetails details) {
      switch (Directionality.of(context)) {
        case TextDirection.rtl:
          context.read<LoginCubit>().animationController.reset();
          context.read<LoginCubit>().animationController.reverse();

          break;
        case TextDirection.ltr:
          break;
      }
    }
    
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.loginView != current.loginView,
      builder: (context, state) {
        return GestureDetector(
          onHorizontalDragUpdate: _move,
          child: Stack(
            children: [
              Container(height: 100, width: 1000,),
              SlideTransition(
                position: context.read<LoginCubit>().state.isEmailLoginView()?_onScreenAnimation:_offScreenAnimation,
                child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _emailInput(),
                      SizedBox(height: 8.0),
                      _passwordInput(),
                      Container(
                        margin: EdgeInsets.only(right: 20.0, top: 5.0),
                        child: _resetPasswordText(),
                      ),

                    ]),
              ),
              SlideTransition(
                position: context.read<LoginCubit>().state.isPhoneLoginView()?_onScreenAnimation:_offScreenAnimation,
                child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                  _phoneInput(),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _emailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withValues(alpha:0.5),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(20.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Row(
        children: <Widget>[
          new Padding(
            padding:
            EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Icon(
              Icons.person_outline,
              color: Colors.grey,
            ),
          ),
          Container(
            height: 30.0,
            width: 1.0,
            color: Colors.grey.withValues(alpha:0.5),
            margin: const EdgeInsets.only(left: 00.0, right: 10.0),
          ),
          new Expanded(
            child: TextField(
              cursorColor: black,
              textInputAction: TextInputAction.next,
              onChanged: (email) => context.read<LoginCubit>().emailChanged(email),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Inserisci l\'indirizzo email',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _passwordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withValues(alpha:0.5),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(20.0),
      ),
      margin:
      const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Row(
        children: <Widget>[
          new Padding(
            padding:
            EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Icon(
              Icons.lock_open,
              color: Colors.grey,
            ),
          ),
          Container(
            height: 30.0,
            width: 1.0,
            color: Colors.grey.withValues(alpha:0.5),
            margin: const EdgeInsets.only(left: 00.0, right: 10.0),
          ),
          new Expanded(
            child: TextField(
              cursorColor: black,
              textInputAction: TextInputAction.done,
              onChanged: (password) => context.read<LoginCubit>().passwordChanged(password),
              obscureText: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Inserisci la password',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _phoneInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withValues(alpha:0.5),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(20.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Row(
        children: <Widget>[
          new Padding(
            padding:
            EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Icon(
              Icons.phone,
              color: Colors.grey,
            ),
          ),
          Text("+39 "),
          Container(
            height: 30.0,
            width: 1.0,
            color: Colors.grey.withValues(alpha:0.5),
            margin: const EdgeInsets.only(left: 00.0, right: 10.0),
          ),
          new Expanded(
            child: TextField(
              cursorColor: black,
              textInputAction: TextInputAction.next,
              onChanged: (phone) => context.read<LoginCubit>().phoneChanged(phone),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Inserisci il numero di telefono',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _messageLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.isLoading(),
      builder: (context, state) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new Container (
                margin: const EdgeInsets.only(top: 10.0),
                child: new Row (
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Benvenuto", style: title_big,),
                  ],
                ),
              ),
              new Container (
              margin: const EdgeInsets.only(top: 5.0, bottom: 20.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Accedi al tuo Account", style: subtitle,)
                ],
              )
              )
            ]
        );
      },
    );  
  }
}

class _errorText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.isLoading(),
      builder: (context, state) {
        if(state.isEmailInvalid()) return Text("L'email inserita non è valida", style: error,);
        if(state.isPasswordInvalid()) return Text("La password inserita non è valida", style: error,);
        if(state.isPhoneInvalid()) return Text("Il n° di telefono inserito non è valido", style: error,);
        if(state.isSuccess()) return Text("Accesso effettuato. Attendere reindirizzamento...", style: subtitle2,);
        if(state.isFailure()) return Text("Le credenziali inserite non sono valide", style: error,);
        return Text("");
      },
    );
  }
}

class _loginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return state.isLoading()
            ? loadingSpinner :
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(top: 20.0),
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: ElevatedButton(
                      style: raisedButtonStyle.copyWith(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0))),
                        backgroundColor: WidgetStateProperty.all<Color>(Constants.debug?Colors.red:black)
                      ),
                      child: new Row(
                        children: <Widget>[
                          new Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Text(
                              "ACCEDI",
                              style: TextStyle(color: white),
                            ),
                          ),
                          new Expanded(
                            child: Container(),
                          ),
                          new Transform.translate(
                            offset: Offset(10.0, 0.0),
                            child: new Container(
                              padding: PlatformUtils.isMobile? EdgeInsets.all(5.0) : EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                              child: TextButton(
                                style: raisedButtonStyle.copyWith(
                                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: new BorderRadius.circular(45.0))),
                                    backgroundColor: WidgetStateProperty.all<Color>(white)
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: black,
                                ),
                                onPressed: (){FocusScope.of(context).unfocus();context.read<LoginCubit>().logIn();}
                              ),
                            ),
                          )
                        ],
                      ),
                        onPressed: (){FocusScope.of(context).unfocus();context.read<LoginCubit>().logIn();}
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  final loadingSpinner = new Center(
    heightFactor: null,
    widthFactor: null,
    child: new CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(yellow),),
  );

}

class _LoginPhone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  new Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(children: <Widget>[
            Expanded(
              child: new Container(
                  margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                  child: Divider(
                    color: grey_light,
                    indent: 15,
                    thickness: 1.5,
                    height: 36,
                  )),
            ),
            Text("oppure",style: subtitle,),
            Expanded(
              child: new Container(
                  margin: const EdgeInsets.only(left: 20.0, right: 10.0),
                  child: Divider(
                    color: grey_light,
                    endIndent: 15,
                    thickness: 1.5,
                    height: 36,
                  )),
            ),
          ]),
          Container(
            margin: const EdgeInsets.only(top: 20.0),
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: ElevatedButton(
                      style: raisedButtonStyle.copyWith(
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: new BorderRadius.circular(25.0))),
                          backgroundColor: WidgetStateProperty.all<Color>(grey_dark)
                      ),
                      onPressed: () {
                        context.read<LoginCubit>().switchLoginView();
                      },
                      child: new Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: new Row(
                          children: [
                            Icon(Icons.phone,color: white,),
                            SizedBox(width: 15,),
                            Text("Collegati con il telefono", style: label_rev,)
                          ],
                        ))
                 )
               )
              ]
          ),
        )
        ]
      );
  }
}

class _resetPasswordText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return new Alert(
                title: "RESET PASSWORD",
                content: new Text("Sicuro di voler procedere con il reset della password?", style: label,),
                actions: <Widget>[
                      TextButton(
                        child: new Text('Annulla', style: label),
                        onPressed: () {
                          PlatformUtils.backNavigator(context);
                        },
                      ),
                      SizedBox(width: 15,),
                      ElevatedButton(
                        child: new Text('CONFERMA', style: button_card),
                        onPressed: () {
                            context.read<AuthenticationBloc>().add(ResetAction(
                                context.select((LoginCubit cubit) => cubit.state.email.value),
                                context.select((LoginCubit cubit) => cubit.state.phone.value)));
                            PlatformUtils.backNavigator(context);
                        }
                      ),
                    ],
              );
            }
        );
      },
      child: new Text("Password dimenticata?", style: subtitle2.copyWith(fontSize: 14),),
    );
  }
}

class PathPainter extends CustomPainter {
  int span = -1;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = white
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, size.height - span);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height - span);
    canvas.drawPath(path, paint);
    if (span > 0) canvas.drawRect(Rect.fromLTRB(0, size.height - span, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
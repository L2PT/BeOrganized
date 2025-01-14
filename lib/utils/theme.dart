import 'package:flutter/material.dart';

final logo = new Image.asset('assets/logo.png', height: 128.0);
final logo_web = new Image.asset('logo.png', height: 128.0);
final logo_icon = new Image.asset('assets/favicon.png', height: 150.0);
final no_events_image = new Image.asset('assets/no-events-image.png', width: 200,);
final ThemeData customLightTheme = _buildTheme();
final TextStyle title = TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: black, );
final TextStyle title_big = TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: black, );
final TextStyle subtitle = TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: grey_dark);
const TextStyle title_rev = TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: white, );
const TextStyle title_rev_menu = TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: white, );
const TextStyle title_rev_web = TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: white, );
const TextStyle title_rev_big = TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: white, );
final TextStyle subtitle_rev = TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: grey_light2);
final TextStyle subtitle_accent = TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: yellow);
final TextStyle error = TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: red);
final TextStyle label = TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: black);
const TextStyle label_rev = TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: white);
final TextStyle time_card = TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: white, );
final TextStyle button_card = TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: white, );
final TextStyle title2 = TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: black );
final TextStyle subtitle2 = TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: grey );
final TextStyle white_default = TextStyle(fontWeight: FontWeight.normal, fontSize: 12, color: white );
final TextStyle stepper_title_nofocus = TextStyle(fontWeight: FontWeight.normal, fontSize: 10, color: grey);

ThemeData _buildTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    primaryColor: black,
    scaffoldBackgroundColor: whitebackground, //ok
    cardColor: Color(0x00000000),
    textSelectionTheme:  TextSelectionThemeData(
      cursorColor: yellow,
      selectionHandleColor: yellow,
      selectionColor: yellow.withOpacity(0.7),
    ),
    disabledColor: grey,
    buttonTheme: ButtonThemeData(
      buttonColor: black,
      textTheme: ButtonTextTheme.accent
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: white,
      headerBackgroundColor: black,
      surfaceTintColor:  Colors.transparent,
      todayBorder: BorderSide(color: black),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return white;
        }
        return black;
      }),
      headerForegroundColor: grey_light,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return white;
        }
        return black;
      }),
    ),
    appBarTheme: AppBarTheme(color: black, surfaceTintColor: black),
    textButtonTheme: TextButtonThemeData(style: flatButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: raisedButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButtonStyle),
    colorScheme: ColorScheme.dark().copyWith(secondary: black, primary: yellow, surface: black, error: red),
    buttonBarTheme: ButtonBarThemeData(buttonTextTheme: ButtonTextTheme.accent,),
    hintColor: grey_light2,
    inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50.0))),
        fillColor: black,
    ),
    textTheme: _buildShrineTextTheme(base.textTheme,black), //ok
    primaryTextTheme: _buildShrineTextTheme(base.primaryTextTheme,Color(0xFFFFFFFF)), //Colore secondario <-- da sistemare quando compare
    iconTheme: IconThemeData(color: Color(0xFFF4F4F4)), //dunno
    primaryIconTheme: IconThemeData(color: Color(0xFFFFFFFF)) //icon
  );
}

TextTheme _buildShrineTextTheme(TextTheme base, Color c) {
  return base.copyWith(
    headlineSmall: base.headlineSmall!.copyWith(
      fontWeight: FontWeight.w500,
    ),
    titleLarge: base.titleLarge!.copyWith(
        fontSize: 18.0
    ),
    bodySmall: base.bodySmall!.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 14.0,
    ),
    bodyLarge: base.bodyLarge!.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 16.0,
    ),
  ).apply(
    fontFamily: 'Roboto',
    displayColor: black, //dunno
    bodyColor: c, //text
  );
}


final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: black,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10.0)),
  ),
);

final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: black,
  surfaceTintColor: black,
  shadowColor: Colors.black,
  foregroundColor: black,
  elevation: 4.0,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(5)),
  ),
);

/// The OutlineButton style for OutlinedButton is a little more complicated because the outline’s color changes to the primary color when the button is pressed.
/// The outline’s appearance is defined by a BorderSide and we’ll use a MaterialStateProperty to define the pressed outline color
final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: black,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
).copyWith(
  side: WidgetStateProperty.resolveWith<BorderSide?>(
        (Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed))
        return BorderSide(
          color: black,
          width: 1,
        );
      return null;
    },
  ),
);

const black_dark = const Color(0xFF000000);
const black = const Color(0xFF333333);
const black_light = const Color(0xFF4b4b4b);
const grey_dark = const Color(0xFFA8A8A8);
const grey = const Color(0xFFA3A3A3);
const grey_light = const Color(0xFFDDDDDD);
const grey_light2 = const Color(0xFFF4F4F4);
const white = const Color(0xFFFFFFFF);
const whitebackground = const Color(0xFFFFFFFF); //background
const whiteoverlapbackground = const Color(0x99FFFFFF); //overlap background
const red = const Color(0xFFC5032B);
const darkred = const Color(0xFF600101);
const yellow = const Color(0xFFF8AD09);
const darkyellow = const Color(0xFFFFC107);
const yellow_light = const Color(0xFFF8D009);
const blue = const Color(0xFF119DD1);
const azure = const Color(0xFF9FE3FD);
const darkblue = const Color(0xFF023146);
const green = const Color(0xFF00664D);
const green_success = const Color(0xFF1A7C4F);
const colorDeleted = const Color(0xFFC34638);
const colorRefused = const Color(0xFFC34638);
const colorWaiting = const Color(0xFFF8D009);
const colorAccepted = const Color(0xFF419D33);
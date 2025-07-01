// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:sms_autofill/sms_autofill.dart';
// import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
// import 'package:venturiautospurghi/utils/theme.dart';
// import 'package:flutter/src/material/time_picker.dart' as time_picker;
//
// class PlatformOtpInputField {
//  
//   ///
//   /// Display date picker bottom sheet.
//   ///
//   static Widget show({
//         required TextEditingController controller
//       }) {
//     if (PlatformUtils.isMobile) {
//       return PinFieldAutoFill(
//         controller: controller,
//         decoration: UnderlineDecoration(
//           textStyle: TextStyle(fontSize: 20, color: Colors.black),
//           colorBuilder: FixedColorBuilder(Colors.black.withValues(alpha:0.3)),
//         ),
//         // currentCode: "",
//         // onCodeSubmitted: (code) {},
//         // onCodeChanged: (code) {
//         //   if (code.length == 6) {
//         //     FocusScope.of(context).requestFocus(FocusNode());
//         //   }
//         // },
//       );
//     } else {
//       return PinInputTextField(
//         pinLength: 6,
//         decoration: UnderlineDecoration(
//           textStyle: TextStyle(fontSize: 20, color: Colors.black),
//           colorBuilder: FixedColorBuilder(Colors.black.withValues(alpha:0.3)),
//         ),
//         controller: controller,
//         textInputAction: TextInputAction.go,
//         enabled: true,
//         keyboardType: TextInputType.number,
//         textCapitalization: TextCapitalization.characters,
//       );
//     }
//   }
// }
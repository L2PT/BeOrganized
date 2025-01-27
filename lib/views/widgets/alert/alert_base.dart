import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class Alert extends StatelessWidget {
  final Widget content;
  final String title;
  final List<Widget> actions;

  Alert({required this.content, required this.title, required this.actions, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: whitebackground,
      titlePadding: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      title: (!string.isNullOrEmpty(title))? Container(
        height: 50,
        decoration: BoxDecoration(
          color: black,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0)),
          border: Border.all(color: black),
        ),
        child: Center(
          child: Text(
            title,
            style: title_rev,
          ),
        ),
      ):Container(),
      content: content,
      actions: actions,
    );
  }
}

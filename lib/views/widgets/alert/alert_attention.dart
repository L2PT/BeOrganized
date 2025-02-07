import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/alert/alert_base.dart';
import 'package:venturiautospurghi/views/widgets/list_tile_operator.dart';

class AttectionAlert {
  final BuildContext context;
  final String title;
  final String text;
  final bool showDetailsContent;
  final bool showDetailsContentDate;
  final Account operator;
  final DateTime start;
  final DateTime end ;
  final IconData icon;
  late final Widget _content;


  AttectionAlert(this.context, {required this.title, required this.text, DateTime? start , DateTime? end, this.showDetailsContent = false, this.showDetailsContentDate = false, Account? operator,
          this.icon =  Icons.warning_rounded,}):
        this.operator = operator??Account.empty(),
        this.start = start??DateTime.now(),
        this.end = end??DateTime.now()
  {
    _content = SingleChildScrollView(
        child: ListBody(children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                this.icon, color: yellow,
                size: 80,
              ),
              SizedBox(height: 15,),
              Text( text, style: label),
              showDetailsContent?
              Center(child: ListTileOperator(
                this.operator,
                detailMode: false,
                darkStyle: false,
              )):Container(),
              showDetailsContentDate?
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Stai cambiando l'orario del'incarico:", style: label),
                  SizedBox(height: 15,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.watch_later,
                        size: 30,
                        color: black,
                      ),
                      SizedBox(width: 15,),
                      Text((this.start.day!=this.end.day?DateFormat("(MMM dd) HH:mm",'it_IT'):DateFormat.Hm()).format(this.start) + " - " +
                          (this.start.day!=this.end.day?DateFormat("(MMM dd) HH:mm",'it_IT'):DateFormat.Hm()).format(this.end), style: label)
                    ],
                  ),
                ],
              ):Container()
            ],
          ),
        ])
    );
  }

  Future<bool> show() async => await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Alert(
          actions: <Widget>[
            TextButton(
              child: new Text('Annulla', style: label),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            SizedBox(
              width: 15,
            ),
            ElevatedButton(
              child: new Text('CONFERMA', style: button_card),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
          content: _content,
          title: title,
        );
      });

}





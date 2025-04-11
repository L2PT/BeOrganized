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
  bool duplicateMode;
  final Account operator;
  final DateTime start;
  final DateTime end ;
  final IconData icon;
  late final Widget _content;


  AttectionAlert(this.context, {required this.title, required this.text, DateTime? start , DateTime? end, this.showDetailsContent = false, this.showDetailsContentDate = false, this.duplicateMode = false, Account? operator,
          this.icon =  Icons.warning_rounded,}):
        this.operator = operator??Account.empty(),
        this.start = start??DateTime.now(),
        this.end = end??DateTime.now();

  Future<List<bool>> show() async => await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        bool duplicateMode = false;
        return StatefulBuilder(
        builder: (context, setState) {
          return Alert(
            actions: <Widget>[
              TextButton(
                child: new Text('Annulla', style: label),
                onPressed: () {
                  Navigator.pop(context, [false, false]);
                },
              ),
              SizedBox(
                width: 15,
              ),
              ElevatedButton(
                child: new Text('CONFERMA', style: button_card),
                onPressed: () {
                  Navigator.pop(context, [true, duplicateMode]);
                },
              ),
            ],
            content: SingleChildScrollView(
                child: ListBody(children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        this.icon, color: yellow,
                        size: 80,
                      ),
                      SizedBox(height: 15,),
                      showDetailsContent? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text( text, style: label),
                            Center(child: ListTileOperator(
                              this.operator,
                              detailMode: false,
                              darkStyle: false,
                            ))]):Container(),
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
                      ):Container(),
                      showDetailsContent?
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 15,),
                            Row(
                                children: [
                                  Container(
                                    width: 30,
                                    margin: EdgeInsets.only(right: 20.0),
                                    child: Icon(Icons.file_copy_rounded, color: black, size: 30),
                                  ),
                                  Expanded(
                                    child: Text("Duplica Incarico", style: label,),
                                  ),
                                  Container(
                                    height: 30,
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.fill,
                                      child:Switch(
                                          inactiveTrackColor: grey_light,
                                          value: duplicateMode,
                                          activeTrackColor: black,
                                          activeColor: yellow,
                                          onChanged: (value) => setState((){ duplicateMode = value; })
                                      ),
                                    ),
                                  )
                                ])
                          ]):Container(),
                    ],
                  ),
                ])
            ),
            title: title,
          );
      });
    });

}





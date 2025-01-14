import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class HeaderMenuLayerWeb extends StatelessWidget {

  bool showBoxCalendar;
  Account account;
  DateTime calendarDate;

  void Function()? logOut;
  void Function()? today;
  void Function(bool hasNext)? nextPrevDay;


  HeaderMenuLayerWeb(this.showBoxCalendar, this.calendarDate, this.account, this.logOut, this.today, this.nextPrevDay);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
          Container(
            height: 75,
            child:
            Row(
              children: [
                logo_web,
                showBoxCalendar?
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical:8.0, horizontal:16.0),
                      child: ElevatedButton(
                          style: raisedButtonStyle.copyWith(padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                              shape:  WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), ),)),
                          onPressed: this.today,
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.today, color: white,),
                              SizedBox(width:5),
                              Text("Oggi", style: subtitle_rev,),
                            ],
                          )
                      ),
                    ),
                    IconButton(padding: EdgeInsets.all(0),onPressed: () => this.nextPrevDay!(false), icon: Icon(Icons.navigate_before, color: grey, size: 40,)),
                    IconButton(padding: EdgeInsets.all(0),onPressed: () => this.nextPrevDay!(true), icon: Icon(Icons.navigate_next, color: grey, size: 40,)),
                    SizedBox(width: 20,),
                    Text(DateFormat('MMMM yyyy - EE dd', Localizations.localeOf(context).languageCode).format(calendarDate).toUpperCase(), style: title)
                  ],
                ): Container(),
                Expanded(child: Container(),),
                Container(
                  alignment: Alignment.centerRight,
                  child: Row(children: <Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical:8.0, horizontal:16.0),
                      child: ElevatedButton(
                          style: raisedButtonStyle.copyWith(padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(horizontal: 25, vertical: 15)),
                              shape:  WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), ),)),
                          onPressed: (){
                            context.go(Constants.filterEventListRoute);
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.search, color: white,),
                              SizedBox(width:5),
                              Text("Cerca interventi", style: subtitle_rev,),
                            ],
                          )
                      ),
                    ),
                    FaIcon(FontAwesomeIcons.userTie, color: black),
                    SizedBox(width: 10,),
                    Text( account.surname.capitalize(), textAlign: TextAlign.right,style: title),
                    SizedBox(width: 5,),
                    Text( account.name.capitalize(), textAlign: TextAlign.right,style: title),
                    SizedBox(width: 30),
                    IconButton(
                      icon: Icon(FontAwesomeIcons.doorOpen, color: black),
                      onPressed: this.logOut,
                    ),
                    SizedBox(width: 30),
                  ],
                  ),
                ),
              ],
      ))
    ]);
  }

}
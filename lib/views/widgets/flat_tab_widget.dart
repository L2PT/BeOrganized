import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class FlatFab extends StatelessWidget {

  int selectedStatus;
  MapEntry<Tab,int> tabsHeader;
  void Function(int)? onStatusTabSelected;
  int count;


  FlatFab( this.tabsHeader, {this.selectedStatus = 0, this.onStatusTabSelected, this.count = 0});

  @override
  Widget build(BuildContext context) {
    int status = tabsHeader.value;
    bool selected = status==selectedStatus;
    return Container(
            height: 50,
            child: TextButton(
              style: flatButtonStyle.copyWith(
                  backgroundColor: WidgetStateProperty.all<Color>(selected?black:whitebackground),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                      side: BorderSide(color: selected?white:grey_light2, width: selected?0:1.0),
                      borderRadius: BorderRadius.all(Radius.circular(15.0))),)
              ),
              child: Row(
                children: <Widget>[
                  Icon((tabsHeader.key.icon as Icon).icon, color:selected?yellow:grey_dark, size: 25,),
                  SizedBox(width: 10),
                  Text(tabsHeader.key.text.toString().toLowerCase().capitalize(), style: selected?button_card:subtitle),
                  Expanded(child: Container()),
                  Container(margin: EdgeInsets.only(right: 10), child: Text(count.toString().formatNumber(short: false), style: selected?button_card:subtitle),)
                ],
              ),
              onPressed: (){ this.onStatusTabSelected!(tabsHeader.value);},
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/switch_widget.dart';

class ListTileOperator extends StatelessWidget {
  final Account operator;
  final int checkbox;
  final int isChecked;
  final int position;
  final double padding;
  final dynamic onTap;
  final dynamic onRemove;
  bool darkStyle;
  bool detailMode;
  double iconSize;


  ListTileOperator(this.operator, {this.detailMode = false, this.position = 0,this.darkStyle = false, this.checkbox = 0, this.isChecked = 0, this.onTap, this.onRemove, this.padding = 20, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? ()=>onTap?.call(operator):null,
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 10.0),
              padding: EdgeInsets.only(top: 5, left: 5, right: 8, bottom: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                color: black,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 25, // 👈 massimo consentito per l’icona
                  maxHeight: 25,
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    Account.getIconTypology(operator.typology).icon,
                    color: yellow,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                !PlatformUtils.isMobile && checkbox == 0 && darkStyle?
                Wrap(
                  direction: Axis.vertical,
                  children: [
                    Text(operator.surname.toUpperCase() + " ", style: title.copyWith(color: darkStyle? grey_light:black, fontSize: 13)),
                    Text(operator.name, overflow: TextOverflow.ellipsis,style: subtitle.copyWith(fontSize: 12)),
                  ],
                ):
                Row(
                  children: [
                    Text(operator.surname.toUpperCase() + " ", style: title.copyWith(color: darkStyle? grey_light:black)),
                    Text(operator.name, overflow: TextOverflow.ellipsis,style: subtitle),
                  ],
                ),
                detailMode?
                Text(position == 0?"Operatore principale":"Operatore", style: subtitle.copyWith(fontSize: 12),): Container()
              ],
            ),
            Expanded(child: Container(),),
            checkbox>=2?CheckboxTriState(onChanged: (v)=>onTap?.call(operator),
              value: isChecked>0?true:false, activeColor: black, checkColor: isChecked>=2?yellow:white, superColor: yellow,):
            checkbox>=1? Theme(data: ThemeData(
              unselectedWidgetColor: grey_light, // Your color
            ),child: Checkbox(onChanged: (v)=>onTap?.call(operator),
              value: isChecked>0?true:false, activeColor: black, checkColor: white, )):
            onRemove != null?IconButton(
                icon: Icon(Icons.delete, color: darkStyle?grey_dark:black, size: iconSize),
                onPressed: () => onRemove(operator)
            ):
            Container()
          ],
        ),
      )
    );
  }
}
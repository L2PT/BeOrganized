import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/colors.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class CardEvent extends StatelessWidget {
  final Event event;
  final void Function(Event)? onTapAction;
  final Map<String, Function(Event)>? buttonArea;
  final double height;
  final bool externalBorder;
  final bool showEventDetails;
  final GlobalKey? key;

  CardEvent({required this.event,
    this.onTapAction,
    this.buttonArea,
    this.key,
    this.height = 160,
    this.externalBorder = false,
    this.showEventDetails = false});


  @override
  Widget build(BuildContext context) {

    Widget _buildButton(String text, Function onPressedAction) => Container(
      child: TextButton(
        child: new Text(text, style: button_card),
        style: flatButtonStyle.copyWith(backgroundColor: WidgetStateProperty.all<Color>(HexColor(event.color))),
        onPressed: () {
          onPressedAction.call(event);
        },
      ),
      margin: EdgeInsets.only(right: 10),
    );

    Widget _buildCardEvent() {
      Widget card;
      double paddingContainer;
      double heightBar;
      int maxLine;

      if (showEventDetails) {
        paddingContainer = 15;
        heightBar = 60;

        card = Card(
          key: key,
          child: Container(
            height: height,
            padding: EdgeInsets.only(left: 10, top: paddingContainer),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: HexColor(event.color)),
                      width: 6,
                      height: heightBar,
                      margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    ),
                    Expanded(
                      flex: 5,
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(DateFormat('HH : mm', 'it_IT').format(event.start) + '  -  ' + DateFormat('HH : mm', 'it_IT').format(event.end),
                              style: time_card,
                            ),
                            Text(
                              event.title.toUpperCase(),
                              style: title_rev,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(event.category.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: subtitle_rev.copyWith(
                                    color: HexColor(event.color),
                                    fontWeight: FontWeight.normal)),
                          ],
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                      ),
                    ),
                    if(showEventDetails)
                      // if a view don't need to show the time but need the date, add a flag parameter for the class
                      Expanded(
                        flex: 3,
                        child: Container(
                          alignment: Alignment.centerRight,
                          margin: EdgeInsets.only(right: 15),
                          child: Container(
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                                color: HexColor(event.color),
                                borderRadius:
                                BorderRadius.all(Radius.circular(25.0))),
                            width: 55,
                            height: 90,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.only(bottom: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Center(
                                  child: Text(DateFormat('MMM', "it_IT").format(event.start) .toUpperCase(),
                                      style: title_rev.copyWith(fontSize: 14)),
                                ),
                                Center(
                                  child: Text("${event.start.day}",
                                      style: title_rev.copyWith(fontSize: 14)),
                                ),
                                Center(
                                  child: Text(DateFormat('E', "it_IT").format(event.start),
                                      style: title_rev.copyWith(fontSize: 13, fontWeight: FontWeight.normal)),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Center(
                                    child: Text(DateFormat('y', "it_IT").format(event.start),
                                        style: title_rev.copyWith(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if(buttonArea != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: buttonArea!.entries.map((entry)=>_buildButton(entry.key, entry.value)).toList(),
                  )
              ],
            ),
          ),
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          elevation: 5,
          color: event.withCartel?darkred:event.isContratto()?darkblue:black,
          surfaceTintColor: black,
        );
      } else {

        heightBar = 40;
        maxLine = height <= Constants.MIN_CALENDAR_EVENT_HEIGHT ? 1:2;

        card = Card(
          borderOnForeground: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
            side: externalBorder? BorderSide(
              color: EventStatus.getColorStatus(event.status, event.withCartel, event.isContratto()),
              width: 2.0,
            ):BorderSide.none,
          ),
          child: Container(
            height: height,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: HexColor(event.color)),
                        width: 6,
                        height: heightBar,
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                      Expanded(
                          child:Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  event.title.toUpperCase(),
                                  style: PlatformUtils.isMobile?title_rev:title_rev.copyWith(fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: maxLine,
                                ),
                                Row(
                                  children: [
                                    Text(event.category.toUpperCase(),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: subtitle_rev.copyWith(
                                            fontSize: PlatformUtils.isMobile?16:14,
                                            color: HexColor(event.color),
                                            fontWeight: FontWeight.normal)),
                                    Expanded(child: Container(),),
                                    event.isRepeatedEvent()?
                                    Container(
                                      margin: EdgeInsets.only(right: 5,top: 2),
                                      child: Icon(
                                        Icons.repeat,
                                        size: 15,
                                        color: HexColor(event.color),
                                      ),
                                    ):Container(),
                                    event.notaOperator.isNotEmpty?
                                    Container(
                                      margin: EdgeInsets.only(right: 5,top: 2),
                                      child: Icon(
                                        Icons.assignment_ind,
                                        size: 18,
                                        color: HexColor(event.color),
                                      ),
                                    ):Container()
                                  ],
                                )
                              ],
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                        )
                      ),
                    ],
                  ),
                ],
              ),
          ),
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          elevation: 5,
          color: event.withCartel?darkred:event.isContratto()?darkblue:black,
          surfaceTintColor: black,
        );
      }
      return card;
    }

    return GestureDetector(
      onTap: () { onTapAction?.call(event); },
      child: _buildCardEvent(),
    );
  }

}

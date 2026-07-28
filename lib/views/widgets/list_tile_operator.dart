import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class ListTileOperator extends StatelessWidget {
  final Account operator;
  final int checkbox;
  final int isChecked;
  final int position;
  final double padding;
  final dynamic onTap;
  final dynamic onTapPrimary;
  final dynamic onTapSecondary;
  final dynamic onRemove;
  final bool darkStyle;
  final bool detailMode;
  final double iconSize;

  const ListTileOperator(
    this.operator, {
    super.key,
    this.detailMode = false,
    this.position = 0,
    this.darkStyle = false,
    this.checkbox = 0,
    this.isChecked = 0,
    this.onTap,
    this.onTapPrimary,
    this.onTapSecondary,
    this.onRemove,
    this.padding = 20,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (onTap != null && checkbox == 0) ? () => onTap?.call(operator) : null,
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 10.0),
              padding: const EdgeInsets.only(top: 5, left: 5, right: 8, bottom: 5),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                color: black,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 25,
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
                !PlatformUtils.isMobile && checkbox == 0 && darkStyle
                    ? Wrap(
                        direction: Axis.vertical,
                        children: [
                          Text(operator.surname.toUpperCase() + " ", style: title.copyWith(color: darkStyle ? grey_light : black, fontSize: 13)),
                          Text(operator.name, overflow: TextOverflow.ellipsis, style: subtitle.copyWith(fontSize: 12)),
                        ],
                      )
                    : Row(
                        children: [
                          Text(operator.surname.toUpperCase() + " ", style: title.copyWith(color: darkStyle ? grey_light : black)),
                          Text(operator.name, overflow: TextOverflow.ellipsis, style: subtitle),
                        ],
                      ),
                detailMode
                    ? Text(
                        position == 0 ? "Operatore principale" : "Operatore",
                        style: subtitle.copyWith(fontSize: 12),
                      )
                    : Container()
              ],
            ),
            Expanded(child: Container()),
            if (checkbox == 2) ...[
              Container(
                width: 40,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: onTapPrimary != null ? () => onTapPrimary.call() : null,
                  child: isChecked == 2
                      ? Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: black, width: 2), color: black),
                          child: Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: yellow))),
                        )
                      : Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: grey_light, width: 2)),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: onTapSecondary != null ? () => onTapSecondary.call() : null,
                  child: isChecked == 1
                      ? Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: black),
                          child: const Icon(Icons.check, size: 16, color: white),
                        )
                      : Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: grey_light, width: 2)),
                        ),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (checkbox == 1) ...[
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Theme(
                  data: ThemeData(unselectedWidgetColor: grey_light),
                  child: Checkbox(
                    onChanged: (v) => onTap?.call(operator),
                    value: isChecked > 0 ? true : false,
                    activeColor: black,
                    checkColor: white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (onRemove != null) ...[
              IconButton(
                icon: Icon(Icons.delete, color: darkStyle ? grey_dark : black, size: iconSize),
                onPressed: () => onRemove(operator),
              ),
            ] else ...[
              Container(),
            ]
          ],
        ),
      ),
    );
  }
}
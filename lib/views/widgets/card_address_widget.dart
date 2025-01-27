import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class CardAddress extends StatelessWidget {

  final Address address;
  final void Function()? onEditAction;
  final void Function()? onTapAction;
  final void Function()? onDeleteAction;
  final void Function(String address)? onLuanchAddressAction;
  final void Function(String phone)? onLuanchPhoneAction;
  final bool onclickMode;
  final bool selectItem;
  final bool actionButton;

  CardAddress({required this.address,
    this.onEditAction,
    this.onDeleteAction,
    this.onTapAction,
    this.onclickMode = false,
    this.selectItem = false,
    this.actionButton = false,
    this.onLuanchAddressAction,
    this.onLuanchPhoneAction,
  });

  @override
  Widget build(BuildContext context) {
    if(onclickMode){
      return MouseRegion(
          cursor: SystemMouseCursors.click,
          child:GestureDetector(
              onTap: onTapAction,
              child:  containerAddress()
              ));
    }else{
      return containerAddress();
    }
  }

  Widget rowPhone(){
    return Row(
      children: [
        Container(
          width: 16,
          margin: EdgeInsets.only(right: 10.0),
          child: Icon(
            Icons.phone,
            color: selectItem && onclickMode?white:grey_dark,
            size: 16,
          ),
        ),
        Container(
            child: Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(address.phone, overflow: TextOverflow.ellipsis, style: subtitle.copyWith(
                          fontSize: 13,
                          color: selectItem && onclickMode ? white : grey_dark))
                    ])
            )
        )
      ],
    );
  }

  Widget rowAddress(){
    return Row(
      children: [
        Container(
          width: 16,
          margin: EdgeInsets.only(right: 10.0),
          child: Icon(
            Icons.map,
            color: selectItem && onclickMode?white:grey_dark,
            size: 16,
          ),
        ),
        Container(
            child: Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(address.address, overflow: TextOverflow.visible,
                          style: subtitle.copyWith(fontSize: 13, color: selectItem && onclickMode ? white : grey_dark))
                    ])))
      ],
    );
  }



  Widget containerAddress(){
    return AnimatedContainer(
        duration: Duration(milliseconds: 300),
    padding: onclickMode?EdgeInsets.all(10):EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
    color: selectItem && onclickMode? black : onclickMode? grey_light2 : white,
    borderRadius: BorderRadius.circular(20.0)),
    child: Row(
      children: [
        Flexible(
          flex: 5,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            this.onLuanchAddressAction != null?
            MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () { this.onLuanchAddressAction!(address.address); },
                  child:rowAddress(),
            )):rowAddress(),
            !string.isNullOrEmpty(address.phone)?
            this.onLuanchPhoneAction != null?
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    onTap: () { this.onLuanchPhoneAction!(address.phone); },
                    child:rowPhone(),
                )
              ):rowPhone():Container(),
          ],
        )),
        actionButton?Flexible(
            flex: 1,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onEditAction,
                    child: Icon(Icons.edit, color: selectItem ? Colors.white : Colors.grey, size: 20),
                  ),
                  SizedBox(width: 8,),
                  GestureDetector(
                    onTap: onDeleteAction,
                    child: Icon(Icons.delete, color: selectItem ? Colors.white : Colors.grey, size: 20),
                  ),
                ])
            ],
          )):Container(),
      ],),
    );
  }

}
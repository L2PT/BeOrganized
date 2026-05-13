import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class CardReferrals extends StatelessWidget {

  final Referrals referral;
  final void Function()? onEditAction;
  final void Function()? onTapAction;
  final void Function()? onDeleteAction;
  final void Function(String phone)? onLuanchPhoneAction;
  final bool onclickMode;
  final bool selectItem;
  final bool actionButton;

  CardReferrals({required this.referral,
    this.onEditAction,
    this.onDeleteAction,
    this.onTapAction,
    this.onclickMode = false,
    this.selectItem = false,
    this.actionButton = false,
    this.onLuanchPhoneAction,
  });

  @override
  Widget build(BuildContext context) {
    if(onclickMode){
      return MouseRegion(
          cursor: SystemMouseCursors.click,
          child:GestureDetector(
              onTap: onTapAction,
              child:  containerReferrals()
          ));
    }else{
      return containerReferrals();
    }
  }


  Widget rowReferrals(){
    return Row(
      children: [
        Container(
          width: 16,
          margin: EdgeInsets.only(right: 10.0),
          child: Icon(
            Customer.getIconTypology(Customer.REFERENTE).icon,
            color: selectItem && onclickMode?white:grey_dark,
            size: 16,
          ),
        ),
        Container(
            child: Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(referral.toString(), overflow: TextOverflow.visible,
                          style: subtitle.copyWith(fontSize: 13, color: selectItem && onclickMode ? white : grey_dark))
                    ])))
      ],
    );
  }



  Widget containerReferrals(){
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
                  this.onLuanchPhoneAction != null?
                  MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () { this.onLuanchPhoneAction!(referral.phone); },
                        child:rowReferrals(),
                      )
                  ):rowReferrals(),
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
                        MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: onEditAction,
                              child: Icon(Icons.edit, color: selectItem ? Colors.white : Colors.grey, size: 20),
                            )),
                        SizedBox(width: 8,),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: onDeleteAction,
                            child: Icon(Icons.delete, color: selectItem ? Colors.white : Colors.grey, size: 20),
                          ),)
                      ])
                ],
              )):Container(),
        ],),
    );
  }

}
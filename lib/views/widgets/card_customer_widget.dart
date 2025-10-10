import 'package:flutter/material.dart';
import 'package:venturiautospurghi/animation/fade_animation.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/card_address_widget.dart';

class CardCustomer extends StatelessWidget {
  final Customer customer;
  final void Function()? onEditAction;
  final void Function()? onDeleteAction;
  final void Function(bool, Customer)? onExpansionChanged;
  ExpansibleController? controller;
  double paddingTopHeader;
  bool expadedMode;
  bool selectedMode;
  bool cardMode;
  bool buttonMode;
  bool selectAddressMode;
  //Address action
  final void Function()? onEditActionAddress;
  final void Function(Address address)? onTapActionAddress;
  final void Function(Address address)? onDeleteActionAddress;
  final void Function(String address)? onLuanchAddressAction;
  final void Function(String phone)? onLuanchPhoneAction;

  CardCustomer({required this.customer,
    this.onEditAction,
    this.controller,
    this.onDeleteAction,
    this.onExpansionChanged,
    this.expadedMode = false,
    this.selectedMode = false,
    this.cardMode = false,
    this.selectAddressMode = false,
    this.buttonMode = true,
    this.paddingTopHeader = 3,
    this.onEditActionAddress,
    this.onDeleteActionAddress,
    this.onTapActionAddress,
    this.onLuanchAddressAction,
    this.onLuanchPhoneAction,
  });

  @override
  Widget build(BuildContext context) {

    Widget addressListElement(Address address){
      return Container(
          margin: EdgeInsets.only(top: 10, ),
          child: CardAddress(address: address,
            onclickMode: true,
            selectItem: customer.address == address,
            actionButton: true,
            onTapAction: () => onTapActionAddress!(address),
            onDeleteAction: () => onDeleteActionAddress!(address),
            onEditAction: onEditActionAddress
          )
      );
    }

    List<Widget> buttonCustomer(){
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 16,),
                    SizedBox(width: 5,),
                    Text('Modifica', style: button_card.copyWith(fontSize: 13))
                  ],
                ),
                style: raisedButtonStyle,
                onPressed: this.onEditAction
            ),
            SizedBox(width: 10,),
            ElevatedButton(
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.white, size: 16,),
                    SizedBox(width: 5,),
                    Text('Rimuovi', style: button_card.copyWith(fontSize: 13))
                  ],
                ),
                style: raisedButtonStyle,
                onPressed: this.onDeleteAction
            ),
          ],
        ),
        SizedBox(height: 10,),
      ];
    }

    Widget headerCustomer(){
      return Padding(padding: EdgeInsets.only(top: paddingTopHeader),child:Row(
        children: [
          Container(
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              color: black,
            ),
            padding: EdgeInsets.all(5),
            child: Icon(Customer.getIconTypology(customer.typology).icon, size: 45, color: yellow,),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(customer.surname.toUpperCase() + " ", style: title.copyWith(color: black, fontSize: 15)),
                  Text(customer.name, overflow: TextOverflow.ellipsis,style: subtitle),
                ],
              ),
              (customer.codFiscale.isNotEmpty && !customer.isCompany()) || (customer.partitaIva.isNotEmpty && customer.isCompany())?
              Text(customer.isCompany()?customer.partitaIva: customer.codFiscale, overflow: TextOverflow.ellipsis,style: subtitle.copyWith(fontSize: 12)): Container(),
              Text(customer.email, overflow: TextOverflow.ellipsis,style: subtitle.copyWith(fontSize: 12)),
            ],
          )
        ],
      ));
    }
    Widget referralsCustomer(){
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            customer.referrals.length>1?'Referenti':'Referente',
            style: title.copyWith(fontSize: 15)
        ),
        SizedBox(height: 3,),
        customer.referrals.isNotEmpty?
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            this.onLuanchPhoneAction!=null?
            Container(
                height: 80,
                width: 255,
                child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: customer.referrals.length,
                    itemBuilder: (BuildContext context, int index) {
                      return FadeAnimation((1.0 + index) / 4,
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                  onTap: () { this.onLuanchPhoneAction!(customer.referrals.elementAt(index).phone); },
                                  child: Container(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            margin: EdgeInsets.only(right: 10.0),
                                            child: Icon(
                                              Customer.getIconTypology(Customer.REFERENTE).icon,
                                              color: grey_dark,
                                              size: 16,
                                            ),
                                          ),
                                          Text(customer.referrals.elementAt(index).toString(),
                                            style: subtitle.copyWith(fontSize: 13),overflow: TextOverflow.visible,),
                                        ],
                                      )
                                  ))));
                    }
                )):
            Row(
              children: [
                Container(
                  width: 16,
                  margin: EdgeInsets.only(right: 10.0),
                  child: Icon(
                    Customer.getIconTypology(Customer.REFERENTE).icon,
                    color: grey_dark,
                    size: 16,
                  ),
                ),
                Text(customer.referrals.join(' - '), overflow: TextOverflow.ellipsis,style: subtitle.copyWith(fontSize: 13)),
              ],
            )
          ],
        ):Text('Nessun referente', overflow: TextOverflow.ellipsis,style: subtitle.copyWith(fontSize: 13)),
      ]);
    }

    Widget phoneCustomer(){
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            customer.phones.length>1?'Telefoni':'Telefono',
            style: title.copyWith(fontSize: 15)
        ),
        SizedBox(height: 3,),
        customer.phones.isNotEmpty?
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            this.onLuanchPhoneAction!=null?
            Container(
                height: 80,
                width: 255,
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: (1 / .2),
                      mainAxisSpacing: 2,
                    ),
                    itemCount: customer.phones.length,
                    itemBuilder: (BuildContext context, int index) {
                      return FadeAnimation((1.0 + index) / 4,
                          MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                  onTap: () { this.onLuanchPhoneAction!(customer.phones.elementAt(index)); },
                                  child: Container(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            margin: EdgeInsets.only(right: 10.0),
                                            child: Icon(
                                              Icons.phone,
                                              color: grey_dark,
                                              size: 16,
                                            ),
                                          ),
                                          Text(customer.phones.elementAt(index),
                                            style: subtitle.copyWith(fontSize: 13),overflow: TextOverflow.visible,),
                                        ],
                                      )
                                  ))));
                    }
                )):
            Row(
              children: [
                Container(
                  width: 16,
                  margin: EdgeInsets.only(right: 10.0),
                  child: Icon(
                    Icons.phone,
                    color: grey_dark,
                    size: 16,
                  ),
                ),
                Text(customer.phones.join(' - '), overflow: TextOverflow.ellipsis,style: subtitle.copyWith(fontSize: 13)),
              ],
            )
          ],
        ):Text('Nessun numero di telefono', overflow: TextOverflow.ellipsis,style: subtitle.copyWith(fontSize: 13)),
      ]);
    }

    List<Widget> bodyCustomer(){
      return [
        Divider(color: grey_light,),
        SizedBox(height: 5,),
        Text(
            customer.addresses.length>1?'Indirizzi':'Indirizzo',
            style: title.copyWith(fontSize: 15)
        ),
        SizedBox(height: 3,),
        selectedMode && customer.addresses.length > 1?Column(children: <Widget>[...customer.addresses.asMap()
            .map((i, address) =>
            MapEntry(i,addressListElement(address))).values.toList()]):
        CardAddress(address: customer.address, onLuanchPhoneAction: this.onLuanchPhoneAction, onLuanchAddressAction: this.onLuanchAddressAction,),
        SizedBox(height: 10,),
        customer.isAdministrator()?referralsCustomer():phoneCustomer(),
        SizedBox(height: 15,),
      ];
    }

    Widget expansionTileMode(){
      List<Widget> body = bodyCustomer();
      if(buttonMode)
        body.addAll(buttonCustomer());
      return ExpansionTile(
        controller: this.controller??new ExpansibleController(),
        childrenPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        collapsedIconColor: black,
        onExpansionChanged: (isOpen) { this.onExpansionChanged != null? this.onExpansionChanged!(isOpen, this.customer):null; },
        title: headerCustomer(),
        initiallyExpanded: expadedMode,
        children: body,
      );
    }

    Widget cardWidgetMode(){
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerCustomer(),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: bodyCustomer()),
            Expanded(child: Container(),),
            buttonMode?
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: buttonCustomer(),
            ): Container()
          ]
        ),
      );
    }

    return Card(
        color: white,
        surfaceTintColor: white,
        borderOnForeground: true,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(
          color: selectedMode?black:grey_light,
          width: selectedMode?4:0.5,
          ),
        ),
      child:Theme(data: Theme.of(context).copyWith(dividerColor:Colors.transparent),
          child: cardMode?cardWidgetMode():expansionTileMode()
      )
    );
  }

}
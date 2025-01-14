import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event_status.dart';

class Headers{

  static final List<MapEntry<Tab,int>> tabsHeadersHistory = [
    MapEntry(new Tab(text: "CONCLUSI",icon: Icon(Icons.flag),),EventStatus.Ended),
    MapEntry(new Tab(text: "ELIMINATI",icon: Icon(Icons.delete),),EventStatus.Deleted),
    MapEntry(new Tab(text: "RIFIUTATI",icon: Icon(Icons.assignment_late),),EventStatus.Refused)
  ];

  static final List<MapEntry<Tab,int>> tabsHeadersContacts = [
    MapEntry(new Tab(text: "CLIENTI TOTALI",icon: Icon(FontAwesomeIcons.solidAddressBook),), Customer.getIntTypology(Customer.ALL)),
    MapEntry(new Tab(text: "PRIVATI",icon: Icon(FontAwesomeIcons.solidUser),), Customer.getIntTypology(Customer.PRIVATO)),
    MapEntry(new Tab(text: "AZIENDA",icon: Icon(FontAwesomeIcons.solidBuilding),),Customer.getIntTypology(Customer.AZIENDA)),
    MapEntry(new Tab(text: "REFERENTE",icon: Icon(FontAwesomeIcons.imagePortrait),),Customer.getIntTypology(Customer.REFERENTE)),
    MapEntry(new Tab(text: "AMMINISTRATORE",icon: Icon(FontAwesomeIcons.userTie),),Customer.getIntTypology(Customer.AMMINISTRATORE)),
  ];
}
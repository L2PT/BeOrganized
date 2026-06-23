import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/event_response_ai.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class Customer extends Equatable{

  static const String ALL = "All";
  static const String PRIVATO = "Privato";
  static const String AZIENDA = "Azienda";
  static const String REFERENTE = "Referente";
  static const String AMMINISTRATORE = "Amministratore";

  String id = "";
  String name = "";
  String surname = "";
  String email = "";
  String phone = "";
  Address address = Address.empty();
  Referrals referral = Referrals.empty();
  List<dynamic> phones = [];
  String partitaIva = "";
  String codFiscale = "";
  List<Address> addresses = [];
  List<Referrals> referrals = [];
  String typology = "Privato";

  Customer(this.id,this.name,this.surname,this.email,this.phone, this.phones, this.partitaIva,this.codFiscale, this.typology, this.address, this.referral, this.addresses, this.referrals);
  Customer.empty();

  Customer.fromMap(String id, Map<String,dynamic> json) :
        id = !string.isNullOrEmpty(id)? id : json["Id"] ?? json["id"] ?? "",
        name = json['Nome'],
        surname = json['Cognome']??'',
        email = json['Email'],
        phone = json['Telefono'],
        phones = json['Telefoni'] != null?List.from(json['Telefoni']):[],
        codFiscale = json['CodiceFiscale']??'',
        partitaIva = json['PartitaIva'],
        addresses = (json["Indirizzi"] as List).map((address) => Address.fromMap(address)).toList(),
        address = json["Indirizzo"] == null? Address.empty(): Address.fromMap(json["Indirizzo"]),
        referral = json["Referente"] == null? Referrals.empty(): Referrals.fromMap(json["Referente"]),
        referrals = json["Referenti"] == null? []: (json["Referenti"] as List).map((referrals) => Referrals.fromMap(referrals)).toList(),
        typology = json['Tipologia']??"Privato";

  Map<String, dynamic> toMap() => {
    "id":this.id,
    "Nome":this.name,
    "Cognome": this.surname,
    "Email":this.email,
    "Telefono":this.phone,
    "Telefoni":this.phones,
    "PartitaIva": this.partitaIva,
    "CodiceFiscale":this.codFiscale,
    "Indirizzi": this.addresses.map((address)=>address.toMap()).toList(),
    "Referenti": this.referrals.map((referrals)=>referrals.toMap()).toList(),
    "Indirizzo": this.address.toMap(),
    "Referente": this.referral.toMap(),
    "Tipologia":this.typology,
  };

  Map<String, dynamic> toDocument() {
    return Map<String, dynamic>.of({
      "Nome":this.name,
      "Cognome": this.surname,
      "Email":this.email,
      "Telefono":this.phone,
      "Telefoni":this.phones,
      "PartitaIva": this.partitaIva,
      "CodiceFiscale":this.codFiscale,
      "Indirizzi": this.addresses.map((address)=>address.toMap()).toList(),
      "Referenti": this.referrals.map((referrals)=>referrals.toMap()).toList(),
      "Indirizzo": this.address.toMap(),
      "Referente": this.referral.toMap(),
      "Tipologia":this.typology,
    });
  }

  Map<String, dynamic> toWebDocument() {
    return Map<String, dynamic>.of({
      "Id":this.id,
      "Nome":this.name,
      "Cognome": this.surname,
      "Email":this.email,
      "Telefono":this.phone,
      "Telefoni":this.phones,
      "PartitaIva": this.partitaIva,
      "CodiceFiscale":this.codFiscale,
      "Indirizzi": this.addresses,
      "Referenti": this.referrals,
      "Indirizzo": this.address,
      "Referente": this.referral,
      "Tipologia":this.typology,
    });
  }

  Customer.fromGenerateData(EventResponseAi eventResponseAi) {
    name = eventResponseAi.nome;
    surname = eventResponseAi.cognome;
    email = eventResponseAi.email;
    partitaIva = eventResponseAi.partitaIva;
    codFiscale = eventResponseAi.codicefiscale;
    typology = eventResponseAi.tipoCliente;
    phones.addAll(eventResponseAi.telefono);
    referrals.addAll(eventResponseAi.referenti);
    Address address = Address.empty();
    address.address.add(eventResponseAi.indirizzo);
    address.phone = eventResponseAi.telefono.first;
    this.address = address;
    addresses.add(address);
  }

  void update(Customer clientUpdate) {
    this.name = clientUpdate.name;
    this.surname = clientUpdate.surname;
    this.email = clientUpdate.email;
    this.phones = clientUpdate.phones;
    this.phone = clientUpdate.phone;
    this.codFiscale = clientUpdate.codFiscale;
    this.typology = clientUpdate.typology;
    this.partitaIva = clientUpdate.partitaIva;
    this.addresses = clientUpdate.addresses;
    this.referrals = clientUpdate.referrals;
    this.address = clientUpdate.address;
    this.referral = clientUpdate.referral;
  }

  bool isCompany(){
    return this.typology == Customer.AZIENDA;
  }

  bool isAdministrator(){
    return this.typology == Customer.AMMINISTRATORE;
  }

  bool filter(lambda, value){
    return lambda(this, value);
  }

  String allPhones(){
    List<String> allPhone = [];
    if (isAdministrator()) {
      allPhone.add(address.phone);
      allPhone.add(referral.phone);
    } else {
      allPhone.add(phone);
      allPhone.addAll(phones.map((e) => e.toString()));
      allPhone.add(address.phone);
    }
    List<String> filteredPhones = allPhone.where((p) => !string.isNullOrEmpty(p)).toSet().toList();
    return filteredPhones.join(" - ");
  }

  String phoneAddress(){
    String phones = allPhones();
    return string.isNullOrEmpty(phones) ? 'Nessun telefono indicato' : phones;
  }

  static int getIntTypology(String typology){
    switch(typology){
      case PRIVATO: return 1;
      case AZIENDA: return 2;
      case REFERENTE: return 3;
      case AMMINISTRATORE: return 4;
      default: return 0;
    }
  }

  static String getStringTypology(int status){
    switch(status){
      case 1: return PRIVATO;
      case 2: return AZIENDA;
      case 3: return REFERENTE;
      case 4: return AMMINISTRATORE;
      default: return ALL;
    }
  }

  static Color getColorTypology(int status){
    switch(status){
      case 1: return black;
      case 2: return black_light;
      case 3: return grey_dark;
      case 4: return grey_light;
      default: return black;
    }
  }

  static Icon getIconTypology(String typology){
    switch(typology){
      case PRIVATO: return Icon(FontAwesomeIcons.solidUser);
      case AZIENDA: return Icon(FontAwesomeIcons.solidBuilding);
      case REFERENTE: return Icon(FontAwesomeIcons.imagePortrait);
      case AMMINISTRATORE: return Icon(FontAwesomeIcons.userTie);
      default: return Icon(FontAwesomeIcons.solidUser);
    }
  }


  @override
  String toString() => id+name+surname+email+phones.join()+phone.toString()+partitaIva+codFiscale+typology+typology+address.toString()+referral.toString()+addresses.join()+referrals.join();

  @override
  List<Object?> get props => [name, surname, email, phone, address, addresses,referral, referrals, phones, partitaIva, codFiscale, typology];

}
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/models/address.dart';
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
  List<dynamic> phones = [];
  String partitaIva = "";
  String codFiscale = "";
  List<Address> addresses = [];
  String typology = "Privato";
  List<String> addressesSearch = [];

  Customer(this.id,this.name,this.surname,this.email,this.phone, this.phones, this.partitaIva,this.codFiscale, this.typology, this.address, this.addresses, this.addressesSearch);
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
        addressesSearch = json['IndirizziSearch'] != null?List.from(json['IndirizziSearch']):[],
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
    "Indirizzo": this.address.toMap(),
    "IndirizziSearch": this.addressesSearch,
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
      "Indirizzo": this.address.toMap(),
      "IndirizziSearch": this.addressesSearch,
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
      "Indirizzo": this.address,
      "IndirizziSearch": this.addressesSearch,
      "Tipologia":this.typology,
    });
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
    this.addressesSearch = clientUpdate.addressesSearch;
    this.address = clientUpdate.address;
  }

  bool isCompany(){
    return this.typology == "Azienda";
  }

  bool filter(lambda, value){
    return lambda(this, value);
  }

  String allPhones(){
    List<String> allPhone = List.from(phones); // Crea una copia della lista esistente
    allPhone.add(address.phone); // Aggiunge il telefono dall'indirizzo
    allPhone = allPhone.toSet().toList(); // Rimuove i duplicati convertendo in Set e poi di nuovo in List
    return allPhone.join(" - "); // Concatena
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
  String toString() => id+name+surname+email+phones.join()+phone.toString()+partitaIva+codFiscale+typology+typology+address.toString()+addresses.join();

  @override
  List<Object?> get props => [name, surname, email, phone, address, addresses, phones, partitaIva, codFiscale, typology];

}
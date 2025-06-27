import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class Account extends Equatable{

  static const String ALL = "All";
  static const String RESPONSABILE = "Responsabile";
  static const String OPERATORE = "Operatore";
  static const String VEICOLO = "Veicolo";

  String id = "";
  String name = "";
  String surname = "";
  String email = "";
  String phone = "";
  String codFiscale = "";
  String targa = "";
  List<Account> webops = [];
  List<dynamic> tokens = [];
  bool supervisor = false;
  String typology = "Operatore";

  Account(this.id, this.name, this.surname, this.email, this.phone, this.codFiscale, this.targa, this.webops, this.tokens, this.supervisor, this.typology);
  Account.empty();
  
  Account.fromMap(String id, Map<String,dynamic> json) :
    id = !string.isNullOrEmpty(id)? id : json["Id"] ?? json["id"] ?? "",
    name = json['Nome'],
    surname = json['Cognome'],
    email = json['Email'],
    phone = json['Telefono'],
    codFiscale = json['CodiceFiscale'],
    targa = json['Targa']??'',
    webops = json.containsKey('OperatoriWeb')? dynamicToObject(json['OperatoriWeb']) : <Account>[],
    tokens = json['Tokens']??[],
    supervisor = json['Responsabile'],
    typology = json['Tipologia']??"Operatore";

  Map<String, dynamic> toMap() => {
      "id":this.id,
      "Nome":this.name,
      "Cognome":this.surname,
      "Email":this.email,
      "Telefono":this.phone,
      "CodiceFiscale":this.codFiscale,
      "Targa": this.targa,
      "Tokens":this.tokens,
      "Responsabile":this.supervisor,
      "Tipologia":this.typology,
  };

  Map<String, dynamic> toDocument() {
    return Map<String, dynamic>.of({
      "Nome":this.name,
      "Cognome":this.surname,
      "Email":this.email,
      "Telefono":this.phone,
      "CodiceFiscale":this.codFiscale,
      "Targa": this.targa,
      "Tokens":this.tokens,
      "Responsabile":this.supervisor,
      "OperatoriWeb":this.webops,
      "Tipologia":this.typology,
    });
  }

  Map<String, dynamic> toWebDocument() {
    return Map<String, dynamic>.of({
      "Id":this.id,
      "Nome":this.name,
      "Cognome":this.surname,
      "Email":this.email,
      "Telefono":this.phone,
      "CodiceFiscale":this.codFiscale,
      "Targa": this.targa,
      "Tokens":this.tokens,
      "Responsabile":this.supervisor,
      "Tipologia":this.typology,
    });
  }
  
  void update(Account userUpdate) {
    this.name = userUpdate.name;
    this.surname = userUpdate.surname;
    this.email = userUpdate.email;
    this.phone = userUpdate.phone;
    this.codFiscale = userUpdate.codFiscale;
    this.targa = userUpdate.targa;
    this.webops = userUpdate.webops;
    this.tokens = userUpdate.tokens;
    this.supervisor = userUpdate.supervisor;
    this.typology = userUpdate.typology;
  }

  static List<Account> dynamicToObject(List<dynamic> json){
    List<Account> els = [];
    json.forEach((webOp)=>els.add(Account.fromMap("", webOp)));
    return els;
  }

  bool filter(lambda, value){
    return lambda(this, value);
  }

  static int getIntTypology(String typology){
    switch(typology){
      case OPERATORE: return 1;
      case RESPONSABILE: return 2;
      case VEICOLO: return 3;
      default: return 0;
    }
  }

  static String getStringTypology(int status){
    switch(status){
      case 1: return OPERATORE;
      case 2: return RESPONSABILE;
      case 3: return VEICOLO;
      default: return ALL;
    }
  }

  static Color getColorTypology(int status){
    switch(status){
      case 1: return black;
      case 2: return black_light;
      case 3: return grey_dark;
      default: return black;
    }
  }

  static Icon getIconTypology(String typology){
    switch(typology){
      case OPERATORE: return Icon(FontAwesomeIcons.helmetSafety);
      case RESPONSABILE: return Icon(FontAwesomeIcons.userTie);
      case VEICOLO: return Icon(FontAwesomeIcons.truck);
      default: return Icon(Icons.people);
    }
  }

  bool isVehicle(){
    return this.typology == Account.VEICOLO;
  }

  @override
  String toString() => id+name+surname+email+phone+codFiscale+supervisor.toString();

  @override
  List<Object?> get props => [id, name, surname, supervisor, email, webops, phone, codFiscale];
}

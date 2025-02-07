import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/utils/extensions.dart';

class Account extends Equatable{
  String id = "";
  String name = "";
  String surname = "";
  String email = "";
  String phone = "";
  String codFiscale = "";
  List<Account> webops = [];
  List<dynamic> tokens = [];
  bool supervisor = false;

  Account(this.id, this.name, this.surname, this.email, this.phone, this.codFiscale, this.webops, this.tokens, this.supervisor);
  Account.empty();
  
  Account.fromMap(String id, Map<String,dynamic> json) :
    id = !string.isNullOrEmpty(id)? id : json["Id"] ?? json["id"] ?? "",
    name = json['Nome'],
    surname = json['Cognome'],
    email = json['Email'],
    phone = json['Telefono'],
    codFiscale = json['CodiceFiscale'],
    webops = json.containsKey('OperatoriWeb')? dynamicToObject(json['OperatoriWeb']) : <Account>[],
    tokens = json['Tokens']??[],
    supervisor = json['Responsabile'];

  Map<String, dynamic> toMap() => {
      "id":this.id,
      "Nome":this.name,
      "Cognome":this.surname,
      "Email":this.email,
      "Telefono":this.phone,
      "CodiceFiscale":this.codFiscale,
      "Tokens":this.tokens,
      "Responsabile":this.supervisor
  };

  Map<String, dynamic> toDocument() {
    return Map<String, dynamic>.of({
      "Nome":this.name,
      "Cognome":this.surname,
      "Email":this.email,
      "Telefono":this.phone,
      "CodiceFiscale":this.codFiscale,
      "Tokens":this.tokens,
      "Responsabile":this.supervisor,
      "OperatoriWeb":this.webops,
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
      "Tokens":this.tokens,
      "Responsabile":this.supervisor,
    });
  }
  
  void update(Account userUpdate) {
    this.name = userUpdate.name;
    this.surname = userUpdate.surname;
    this.email = userUpdate.email;
    this.phone = userUpdate.phone;
    this.codFiscale = userUpdate.codFiscale;
    this.webops = userUpdate.webops;
    this.tokens = userUpdate.tokens;
    this.supervisor = userUpdate.supervisor;
  }

  static List<Account> dynamicToObject(List<dynamic> json){
    List<Account> els = [];
    json.forEach((webOp)=>els.add(Account.fromMap("", webOp)));
    return els;
  }

  @override
  String toString() => id+name+surname+email+phone+codFiscale+supervisor.toString();

  @override
  List<Object?> get props => [id, name, surname, supervisor, email, webops, phone, codFiscale];
}

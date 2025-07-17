import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/utils/extensions.dart';

class Referrals extends Equatable{

  String name = "";
  String phone = "";

  Referrals.empty();
  Referrals(this.name, this.phone);

  Referrals.fromMap(Map<String,dynamic> json) :
        name = json['Nome'],
        phone = json['Telefono'];

  Referrals.fromMapEventAi(Map<String,dynamic> json) :
        name = json['nome'],
        phone = json['telefono'];

  Map<String, dynamic> toMap() => {
    "Nome":this.name,
    "Telefono":this.phone,
  };

  Map<String, dynamic> toDocument() {
    return Map<String, dynamic>.of({
      "Nome":this.name,
      "Telefono":this.phone,
    });
  }

  Map<String, dynamic> toWebDocument() {
    return Map<String, dynamic>.of({
      "Nome":this.name,
      "Telefono":this.phone,
    });
  }

  void update(Referrals referralUpdate) {
    this.name = referralUpdate.name;
    this.phone = referralUpdate.phone;
  }

  @override
  String toString() => name.capitalize()+ ": " +phone;

  @override
  List<Object?> get props => [name, phone];

}
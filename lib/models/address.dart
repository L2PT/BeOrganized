import 'package:equatable/equatable.dart';

class Address extends Equatable{
  List<String> address = [];
  String phone = "";

  Address(this.address,this.phone);
  Address.empty();

  Address.fromMap(Map<String,dynamic> json) :
        address = _convertAddress(json['Indirizzo']),
        phone = json['Telefono'];

  static List<String> _convertAddress(dynamic addressData) {
    if (addressData == null) return [];
    if (addressData is String) return [addressData]; // Vecchio formato: converti in lista
    if (addressData is List) return List<String>.from(addressData); // Nuovo formato
    return [];
  }

  Map<String, dynamic> toMap() => {
    "Indirizzo":this.address,
    "Telefono": this.phone,
  };

  Map<String, dynamic> toDocument() {
    return Map<String, dynamic>.of({
      "Indirizzo":this.address,
      "Telefono": this.phone,
    });
  }

  Map<String, dynamic> toWebDocument() {
    return Map<String, dynamic>.of({
      "Indirizzo":this.address,
      "Telefono": this.phone,
    });
  }

  void update(Address addressUpdate) {
    this.address = addressUpdate.address;
    this.phone = addressUpdate.phone;
  }

  @override
  List<Object?> get props => [address, phone];
}
import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;

class ContactWhatsapp extends Equatable {
  final String id;
  final bool isBusiness;
  final bool isEnterprise;
  final bool isGroup;
  final bool isMyContact;
  final bool isWAContact;
  final String name;
  final String number;
  final String phoneNumber;
  final String? pushname;
  final String realPhoneNumber;
  final String shortName;
  final DateTime updatedAt;

  ContactWhatsapp({
    this.id = '',
    this.isBusiness = false,
    this.isEnterprise = false,
    this.isGroup = false,
    this.isMyContact = false,
    this.isWAContact = false,
    this.name = '',
    this.number = '',
    this.phoneNumber = '',
    this.pushname,
    this.realPhoneNumber = '',
    this.shortName = '',
    required this.updatedAt,
  });

  factory ContactWhatsapp.fromMap(String id, Map<String, dynamic> json) {
    return ContactWhatsapp(
      id: id,
      isBusiness: json['isBusiness'] ?? false,
      isEnterprise: json['isEnterprise'] ?? false,
      isGroup: json['isGroup'] ?? false,
      isMyContact: json['isMyContact'] ?? false,
      isWAContact: json['isWAContact'] ?? false,
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      pushname: json['pushname'],
      realPhoneNumber: json['realPhoneNumber'] ?? '',
      shortName: json['shortName'] ?? '',
      updatedAt: json["updatedAt"] is DateTime
          ? json["updatedAt"]
          : _.DateUtils.firestoreToItalianTime(json["updatedAt"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isBusiness': isBusiness,
      'isEnterprise': isEnterprise,
      'isGroup': isGroup,
      'isMyContact': isMyContact,
      'isWAContact': isWAContact,
      'name': name,
      'number': number,
      'phoneNumber': phoneNumber,
      'pushname': pushname,
      'realPhoneNumber': realPhoneNumber,
      'shortName': shortName,
      'updatedAt': updatedAt,
    };
  }

  ContactWhatsapp copyWith({
    String? id,
    bool? isBusiness,
    bool? isEnterprise,
    bool? isGroup,
    bool? isMyContact,
    bool? isWAContact,
    String? name,
    String? number,
    String? phoneNumber,
    String? pushname,
    String? realPhoneNumber,
    String? shortName,
    DateTime? updatedAt,
  }) {
    return ContactWhatsapp(
      id: id ?? this.id,
      isBusiness: isBusiness ?? this.isBusiness,
      isEnterprise: isEnterprise ?? this.isEnterprise,
      isGroup: isGroup ?? this.isGroup,
      isMyContact: isMyContact ?? this.isMyContact,
      isWAContact: isWAContact ?? this.isWAContact,
      name: name ?? this.name,
      number: number ?? this.number,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pushname: pushname ?? this.pushname,
      realPhoneNumber: realPhoneNumber ?? this.realPhoneNumber,
      shortName: shortName ?? this.shortName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  ContactWhatsapp update({
    String? id,
    bool? isBusiness,
    bool? isEnterprise,
    bool? isGroup,
    bool? isMyContact,
    bool? isWAContact,
    String? name,
    String? number,
    String? phoneNumber,
    String? pushname,
    String? realPhoneNumber,
    String? shortName,
    DateTime? updatedAt,
  }) => copyWith(
    id: id,
    isBusiness: isBusiness,
    isEnterprise: isEnterprise,
    isGroup: isGroup,
    isMyContact: isMyContact,
    isWAContact: isWAContact,
    name: name,
    number: number,
    phoneNumber: phoneNumber,
    pushname: pushname,
    realPhoneNumber: realPhoneNumber,
    shortName: shortName,
    updatedAt: updatedAt,
  );

  bool filter(lambda, value){
    return lambda(this, value);
  }

  @override
  List<Object?> get props => [
        id,
        isBusiness,
        isEnterprise,
        isGroup,
        isMyContact,
        isWAContact,
        name,
        number,
        phoneNumber,
        pushname,
        realPhoneNumber,
        shortName,
        updatedAt,
      ];
}


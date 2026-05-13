import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;

class MessageConfig extends Equatable{
  String qrCode = "";
  bool sessionActive = false;
  DateTime updatedAt = _.DateUtils.now();

  MessageConfig(this.sessionActive,this.qrCode);
  MessageConfig.empty();

  MessageConfig.fromMap(Map<String,dynamic> json) :
        qrCode = json['qrCode'],
        sessionActive = json['sessionActive'],
        updatedAt = json["updatedAt"] is DateTime?json["updatedAt"]:_.DateUtils.firestoreToItalianTime(json["updatedAt"]);

  Map<String, dynamic> toMap() => {
    "qrCode":this.qrCode,
    "sessionActive": this.sessionActive,
    "updatedAt": this.updatedAt
  };

  Map<String, dynamic> toDocument() {
    return Map<String, dynamic>.of({
      "qrCode":this.qrCode,
      "sessionActive": this.sessionActive,
      "updatedAt": this.updatedAt
    });
  }

  Map<String, dynamic> toWebDocument() {
    return Map<String, dynamic>.of({
      "qrCode":this.qrCode,
      "sessionActive": this.sessionActive,
      "updatedAt": this.updatedAt
    });
  }

  void update(MessageConfig messageConfigUpdate) {
    this.qrCode = messageConfigUpdate.qrCode;
    this.sessionActive = messageConfigUpdate.sessionActive;
    this.updatedAt = messageConfigUpdate.updatedAt;
  }

  @override
  List<Object?> get props => [qrCode, sessionActive, updatedAt, ];
}
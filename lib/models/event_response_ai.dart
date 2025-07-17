import 'package:equatable/equatable.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

class EventResponseAi extends Equatable {
  String nome = "";
  String cognome = "";
  String indirizzo = "";
  List<String> telefono = [];
  List<Referrals> referenti = [];
  String email = "";
  String codicefiscale = "";
  String partitaIva = "";
  String tipoCliente = "Privato";
  String tipo = "Intervento";
  bool cartello = false;
  String categoria = "Spurgo";
  String problematica = "";
  bool programmato = false;
  bool allDay = false;
  String operatore = "";
  String note = "";
  String color = Constants.fallbackHexColor;

  String data = "";
  String oraInizio = "";
  String oraFine = "";
  bool isRepeated = false;
  String dataInizioRipetizione = "";
  String dataFineRipetizione = "";
  int giornoMeseRipetizione = 1;
  int ogniQuantiMesiRipetizione = -1;

  EventResponseAi(
      this.nome,
      this.cognome,
      this.indirizzo,
      this.problematica,
      this.telefono,
      this.tipo,
      this.cartello,
      this.codicefiscale,
      this.partitaIva,
      this.email,
      this.tipoCliente,
      this.programmato,
      this.categoria,
      this.color,
      this.allDay,
      this.operatore,
      this.data,
      this.oraInizio,
      this.oraFine,
      this.isRepeated,
      this.dataInizioRipetizione,
      this.dataFineRipetizione,
      this.giornoMeseRipetizione,
      this.ogniQuantiMesiRipetizione,
      this.referenti,
      );

  EventResponseAi.empty();

  EventResponseAi.fromMap(Map json)
      : nome = json["nome"] ?? "",
        cognome = json["cognome"] ?? "",
        indirizzo = json["indirizzo"] ?? "",
        telefono = (json["telefono"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        referenti = (json["referenti"] as List).map((referrals) => Referrals.fromMapEventAi(referrals)).toList(),
        email = json["email"] ?? "",
        codicefiscale = json["codicefiscale"] ?? "",
        partitaIva = json["partitaIva"] ?? "",
        tipoCliente = json["tipoCliente"] ?? "Privato",
        tipo = json["tipo"] ?? "Intervento",
        cartello = json["cartello"] ?? false,
        categoria = json["categoria"] ?? "Spurgo",
        problematica = json["problematica"] ?? "",
        note = json["note"] ?? "",
        programmato = json["programmato"] ?? false,
        allDay = json["allDay"] ?? false,
        operatore = json["operatore"] ?? "",
        color = json["color"] ?? Constants.fallbackHexColor,
        data = json["data"] ?? "",
        oraInizio = json["oraInizio"] ?? "",
        oraFine = json["oraFine"] ?? "",
        isRepeated = json["isRepeated"] ?? false,
        dataInizioRipetizione = json["dataInizioRipetizione"] ?? "",
        dataFineRipetizione = json["dataFineRipetizione"] ?? "",
        giornoMeseRipetizione = json["giornoMeseRipetizione"] ?? DateTime.now().day,
        ogniQuantiMesiRipetizione = json["ogniQuantiMesiRipetizione"] ?? -1;

  @override
  List<Object?> get props => [
    nome,
    cognome,
    indirizzo,
    telefono,
    email,
    codicefiscale,
    partitaIva,
    tipoCliente,
    tipo,
    cartello,
    categoria,
    problematica,
    programmato,
    operatore,
    allDay,
    color,
    data,
    oraInizio,
    oraFine,
    isRepeated,
    dataInizioRipetizione,
    dataFineRipetizione,
    giornoMeseRipetizione,
    ogniQuantiMesiRipetizione,
  ];
}

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/utils/date_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';

class PDFUtils {
  late MemoryImage logoImage;
  late Font fontRegular;
  late Font fontBold;
  late Font fontIcon;
  double _fontSize = 12;

  PDFUtils({String logoPath = "assets/icona-app.png"}) {
    _loadResource(logoPath);
  }

  Future<void> _loadResource(String path) async {
    this.logoImage = MemoryImage(
        (await rootBundle.load(path)).buffer.asUint8List(),);
    fontRegular = await PdfGoogleFonts.openSansRegular();
    fontBold = await PdfGoogleFonts.openSansBold();
    fontIcon = await PdfGoogleFonts.materialIcons();
  }

  Future<Uint8List> createDailyProgram(List<Event> listEvent, DateTime date, Account operator) async {
    final pdf = Document(title: 'Programma Giornaliero - ' + operator.name.toUpperCase()
        +" " +operator.surname.toUpperCase(), author: 'Venturi Bruno');

    pdf.addPage(
        MultiPage(
          theme: ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            icons: fontIcon,
          ),
          margin: const EdgeInsets.all(25),
          orientation: PageOrientation.natural,
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(context,date, operator, logoImage),
          footer: _buildFooter,
          build: (context) => _buildContent(context, listEvent),
        )
    );

    return pdf.save();
  }

  Widget _buildHeader(Context context, DateTime date, Account operator, MemoryImage logo) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                      const BorderRadius.all(Radius.circular(5)),
                      border:  Border.all(color: PdfColors.grey200, width: 1)
                    ),
                    padding: const EdgeInsets.only(
                        left: 20, top: 15, bottom: 15, right: 20),
                    alignment: Alignment.centerLeft,
                    child: Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        DateUtils.pdfDateFormat(date).capitalize(),
                        style: TextStyle(
                          color: PdfColors.grey900,
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Operatore: ",
                              style: TextStyle(
                                color: PdfColors.grey600,
                                fontWeight: FontWeight.normal,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              operator.surname.toUpperCase() + " " + operator.name.toUpperCase(),
                              style: TextStyle(
                                color: PdfColors.grey800,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ]
                        )
                      ]
                    ),
                  )),
                ],
              ),
            ),Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(bottom: 8, left: 25),
                    height: 100,
                    child: Image(logo),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(Context context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Divider(
          color: PdfColors.grey400,
          thickness: 1,
          height: 10,
        ),
        Text(
          'Pagina ${context.pageNumber}/${context.pagesCount}',
          style: const TextStyle(
            fontSize: 12,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContent(Context context, List<Event> listEvent){
    return <Widget>[
      SizedBox(height: 15),
      Column(
        children: [
            ...listEvent.map((event) {
              return _buildContentEvent(event);
            }).expand((i) => i).toList()
          ]
      )
    ];
  }

  List<Widget> _buildContentEvent(Event event){
    return <Widget>[
      Container(
        decoration: BoxDecoration(
          borderRadius:
          const BorderRadius.all(Radius.circular(5)),
          border: Border.all(color: PdfColors.grey400, width: 1)
        ),
        padding: const EdgeInsets.only(
            left: 10, top: 5, bottom: 5, right: 10),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(IconData(0xe8b5), size: 15, color: PdfColors.grey800),
                SizedBox(width: 5,),
                Text((DateUtils.hoverDateFormat(event.start) == DateUtils.hoverDateFormat(event.end)?
                DateUtils.hoverTimeFormat(event.start) + " - " + DateUtils.hoverTimeFormat(event.end):
                DateUtils.hoverDateFormatDiff(event.start) + " - " + DateUtils.hoverDateFormatDiff(event.end)) + " - ",
                    style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.normal, color: PdfColors.grey700,), maxLines: 2),
                Text(event.title.toUpperCase(), style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  color: PdfColors.grey800,
                ), maxLines: 2),
              ],
            ),
            SizedBox(height: 2,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(IconData(0xe0c8), size: 15, color: PdfColors.grey800),
                SizedBox(width: 5,),
                Text(event.customer.address.address,
                    style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.normal, color: PdfColors.grey700,), maxLines: 2),
              ],
            ),
            event.customer.phones.length != 0?
            Container(
              margin: EdgeInsets.only(top: 2),
              child:Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(IconData(0xe0cf), size: 15, color: PdfColors.grey800),
                  SizedBox(width: 5,),
                  Text(event.customer.allPhones(),
                      style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.normal, color: PdfColors.grey700,), maxLines: 2),
                ],
              ),
            ):Container(),
            !string.isNullOrEmpty(event.description)?
            Container(
              margin: EdgeInsets.only(top: 2),
              child:Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(IconData(0xe85d), size: 15, color: PdfColors.grey800),
                  SizedBox(width: 5,),
                  Expanded(
                  flex: 1, child: Text(event.description,
                      style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.normal, color: PdfColors.grey700,), ),)
                ],
              ),
            ):Container(),
            !string.isNullOrEmpty(event.notaOperator)?
            Container(
              margin: EdgeInsets.only(top: 2),
              child:Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(IconData(0xe85e), size: 15, color: PdfColors.grey800),
                  SizedBox(width: 5,),
                  Expanded(
                      flex: 1, child: Text(event.notaOperator,
                      style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.normal, color: PdfColors.grey700,)),)
                ],
              ),
            ):Container(),
            SizedBox(height: 2,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(IconData(EventStatus.getIconCode(event.status)), size: 15, color: PdfColors.grey800),
                SizedBox(width: 5,),
                Text(EventStatus.getText(event.status),
                    style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.normal, color: PdfColors.grey700,)),
              ],
            ),
            SizedBox(height: 2,),
            event.isRefused()? Expanded(
                flex: 1, child: Text(event.motivazione,
                style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.normal, color: PdfColors.grey700,))):Container()
          ],
        ),
      ),
      SizedBox(
        height: 20,
      )
    ];
  }
}
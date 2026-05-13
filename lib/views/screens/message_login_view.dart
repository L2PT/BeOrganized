import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class WhatsAppLoginScreen extends StatelessWidget {
  final String qrCode;

  WhatsAppLoginScreen(this.qrCode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey_light2,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black26,
                offset: Offset(0, 4),
              ),
            ],
          ),
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 80, color: green),
              SizedBox(height: 16),

              Text(
                "Sessione WhatsApp non attiva",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),
              Text(
                "Scansiona il QR code con WhatsApp\nper attivare la sessione.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 24),

              if (qrCode == "")
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("QR non ancora pronto...",
                      style: TextStyle(color: Colors.grey)),
                )
              else
                QrImageView(
                  data: qrCode,
                  version: QrVersions.auto,
                  size: 240,
                ),
              SizedBox(height: 20),
              Text(
                "In attesa di connessione...",
                style: TextStyle(color: Colors.grey.shade600),
              )
            ],
          ),
        ),
      ),
    );
  }
}

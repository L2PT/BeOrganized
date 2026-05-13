import 'package:flutter/material.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';

class NoChat extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            (PlatformUtils.isMobile?'assets/':'/message/')+'message_nochat.png', // assicurati di aggiungere l'immagine nella cartella assets
            width: 300,
            height: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'Seleziona una chat dalla lista',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Inizia a rispondere ai tuoi clienti e mantieni le conversazioni sempre vive.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
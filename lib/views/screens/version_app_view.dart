import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class VersionApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: white,
        body: Stack(
          children: [
            Container(
                decoration:
                BoxDecoration(color: white.withOpacity(0.7)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding( padding: EdgeInsets.all(15.0),
                          child: Container(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 35),
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, color: yellow, size: 150,),
                                  SizedBox(height: 15,),
                                  Text("Applicazione non Aggiornata!", style: title_rev_big, textAlign: TextAlign.center,),
                                  Padding(padding: EdgeInsets.only(top: 20, bottom: 25),
                                    child: Text("Applicazione non aggiornata all'ultima versione, per utilizzare applicazione "
                                        "con le ultime funzionalità e non avere nessun errore durante l'utilizzo. Andare sullo store e aggiornarla.", style: subtitle_rev.copyWith(fontWeight: FontWeight.normal), textAlign: TextAlign.center,),

                                  ), ElevatedButton(
                                    style: ElevatedButton.styleFrom(side: BorderSide(width: 1.0, color: white,)),
                                    child: new Text('VISITA LO STORE', style: button_card),
                                    onPressed: null,
                                  ),
                                ],
                              ),
                            ),
                            decoration: BoxDecoration(color: black, borderRadius: new BorderRadius.all(Radius.circular(15.0)) ),
                          ))
                    ]
                )
            )
          ],
        ));
  }
}
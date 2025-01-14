import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class EventStatus {
  static const int Bozza = -3;
  static const int Deleted = -2;
  static const int Refused = -1;
  static const int New = 0;
  static const int Delivered = 1;
  static const int Seen = 2;
  static const int Accepted = 3;
  static const int Ended = 4;

  static IconData getIcon(int status){
    switch(status){
      case Bozza:
        return Icons.edit;
      case Deleted:
        return Icons.delete;
      case Refused:
        return Icons.assignment_late;
      case New:
        return Icons.assignment;
      case Delivered:
        return Icons.assignment_returned;
      case Seen:
        return Icons.assignment_ind;
      case Accepted:
        return Icons.assignment_turned_in;
      case Ended:
        return Icons.flag;
      default: return Icons.assignment;
    }
  }

  static int getIconCode(int status){
    switch(status){
      case Bozza:
        return 0xe3c9;
      case Deleted:
        return 0xe872;
      case Refused:
        return 0xe85f;
      case New:
        return 0xe85d;
      case Delivered:
        return 0xe861;
      case Seen:
        return 0xe85e;
      case Accepted:
        return 0xe862;
      case Ended:
        return 0xe153;
      default: return 0xe85d;
    }
  }

  static String getText(int status){
    switch(status){
      case EventStatus.Bozza: return "Bozza";
      case EventStatus.Deleted: return "Eliminato";
      case EventStatus.Refused: return "Rifiutato";
      case EventStatus.New: return "Nuovo";
      case EventStatus.Delivered: return "Consegnato";
      case EventStatus.Seen: return "Visualizzato";
      case EventStatus.Accepted: return "Accettato";
      case EventStatus.Ended: return "Terminato";
      default: return "Nuovo";
    }
  }

  static String getCategoryText(int status){
    switch(status){
      case EventStatus.Deleted: return "Eliminati";
      case EventStatus.Refused: return "Rifiutati";
      default: return "Conclusi";
    }
  }

  static Color getColorStatus(int status, bool withCartel, bool isContratto){
    switch(status){
      case EventStatus.Refused: return colorRefused;
      case EventStatus.Accepted: return colorAccepted;
      case EventStatus.Deleted: return colorDeleted;
      case EventStatus.Ended: return withCartel?darkred:isContratto?darkblue:black;
      default: return colorWaiting;
    }
  }

  static Color getColorArichive(int status){
    switch(status){
      case EventStatus.Refused: return black;
      case EventStatus.Deleted: return black_light;
      case EventStatus.Ended: return grey_dark;
      default: return black;
    }
  }

  static Color getColorDefault(int index){
    switch(index){
      case 0: return black;
      case 1: return black_light;
      case 2: return grey_dark;
      default: return black;
    }
  }

}

import 'package:flutter/widgets.dart';
import 'package:venturiautospurghi/models/event_status.dart';
import 'package:venturiautospurghi/views/screens/filter_event_list_view.dart';

class BozzeEventList extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return FilterEventList(filters: {"status": EventStatus.Bozza });
  }

}
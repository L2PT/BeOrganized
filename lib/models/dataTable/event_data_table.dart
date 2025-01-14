import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/event.dart';
import 'package:venturiautospurghi/utils/colors.dart';
import 'package:venturiautospurghi/utils/date_utils.dart' as _;
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class EventDataTable extends DataTableSource {
  // Generate some made-up data
  final List<Event> _data;
  int total;


  void Function(Event event)? onDelete;
  void Function(Event event)? onEdit;
  void Function(Event event)? onDetail;
  void Function(Event event, bool? value)? onSelected;
  Map<String, bool>? mapSelected;
  bool actionVisible;
  bool operatorVisible;

  EventDataTable(this._data, this.total, { this.onDetail, this.onDelete, this.onEdit, this.onSelected, this.mapSelected, this.actionVisible = false, this.operatorVisible = true});

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => total;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
    return eventDataRow(_data.elementAt(index));
  }

  List<DataCell> _getDataCell(Event event){
    List<DataCell> listDataCell = [
      DataCell(Tooltip(message: event.category, child: Container(
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          color: HexColor(event.color),
        ),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Text(event.category[0].toUpperCase(), style: title_rev.copyWith(fontSize: 14),),
      ))),
      DataCell(Container(
        width: 40,
        margin: EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        child: IconButton(icon: Icon(event.withCartel?Icons.warning_rounded:event.isContratto()?Icons.assignment:Icons.work,
          color: event.withCartel?darkred:event.isContratto()?darkblue:black,), onPressed: null, tooltip: event.withCartel?"Con cartello":event.isContratto()?"Contratto":"Intervento",)
      )),
      DataCell(Container(
      width: 150, child:Text(event.title, style: label.copyWith(fontSize: 13),))),
      DataCell(Text(_.DateUtils.hoverDateFormat(event.start) == _.DateUtils.hoverDateFormat(event.end)?
        _.DateUtils.tableDateFormat(event.start).toString().capitalize() + " - " + _.DateUtils.hoverTimeFormat(event.start) + " - " + _.DateUtils.hoverTimeFormat(event.end):
        _.DateUtils.hoverDateFormatDiff(event.start) + " - " + _.DateUtils.hoverDateFormatDiff(event.end), style: label.copyWith(fontSize: 13))
      ),
      DataCell(Row(
        children: [
          Text(event.customer.surname.toUpperCase() + " ", style: label.copyWith(fontSize: 13),),
          Text(event.customer.isCompany()?event.customer.name.toUpperCase():event.customer.name, overflow: TextOverflow.ellipsis,
              style: label.copyWith(fontSize: 13)),
        ],
      ),),
      DataCell(Text(event.customer.address.address, style: label.copyWith(fontSize: 13),)),
      DataCell(Container(
         width: 200, child: Text(event.customer.allPhones(), style: label.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis))),
    ];
    if(operatorVisible){
      listDataCell.insert(4,DataCell(Container(
          width: 100, child:Text([event.operator, ...event.suboperators].map((operator) =>
      "${operator?.name} ${operator?.surname}").reduce((value, element) => value+"; "+element),
          style: label.copyWith(fontSize: 13)))));
    }
    if(actionVisible){
      listDataCell.add(DataCell(Row(
          children: [
            IconButton(onPressed: () => onDetail!(event), icon: Icon(Icons.assignment, color: black, size: 20,), tooltip: "Dettaglio",),
            SizedBox(width: 5,),
            IconButton(onPressed: () => onEdit!(event), icon: Icon(Icons.edit, color: black, size: 20,), tooltip: "Modifica",),
            SizedBox(width: 5,),
            IconButton(onPressed: () => onDelete!(event), icon:Icon(Icons.delete, color: black, size: 20,), tooltip: "Elimina",)
          ]),));
    }
    return listDataCell;
  }

  DataRow eventDataRow(Event event){
    return DataRow(cells: _getDataCell(event),
        color: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.hovered) || states.contains(WidgetState.selected)?
          grey_light: white.withOpacity(0.5);
        }),
        selected: mapSelected?[event.id]??false,
        onSelectChanged: (value) => onSelected!(event, value));
  }
}
import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class AccountDataTable extends DataTableSource {
  // Generate some made-up data
  final List<Account> _data;
  int total;


  void Function(Account account) onDelete;
  void Function(Account account) onEdit;
  void Function(Account account, bool? value) onSelected;
  Map<String, bool> mapSelected;

  AccountDataTable(this._data, this.total, this.onDelete, this.onEdit, this.onSelected, this.mapSelected);

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => total;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    return accountDataRow(_data.elementAt(index));
  }

  DataRow accountDataRow(Account account){
    return DataRow(cells: [
      DataCell(Tooltip(message: account.typology, child: Container(
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          color: black,
        ),
        padding: EdgeInsets.all(5),
        child: Icon(Account.getIconTypology(account.typology).icon, size: 16, color: yellow,),
      ))),
      DataCell(Row(
        children: [
          Text(account.surname.toUpperCase() + " ", style: title.copyWith(color: black, fontSize: 15)),
          Text(account.name, overflow: TextOverflow.ellipsis, style: subtitle),
        ],
      ),),
      DataCell(Text(account.email, style: label.copyWith(fontSize: 13),)),
      DataCell(Text(account.phone, style: label.copyWith(fontSize: 13),)),
      DataCell(Text(account.codFiscale, style: label.copyWith(fontSize: 13),)),
      DataCell(Row(
          children: [
            IconButton(onPressed: () => onEdit(account), icon: Icon(Icons.edit, color: black, size: 20,)),
            SizedBox(width: 5,),
            IconButton(onPressed: () => onDelete(account), icon:Icon(Icons.delete, color: black, size: 20,))
          ]),)
    ],
        color: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? grey_light: white;
        }),
        selected: mapSelected[account.id]??false,
        onSelectChanged: (value) => onSelected(account, value));
  }
}
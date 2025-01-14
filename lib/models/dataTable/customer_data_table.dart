import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class CustomerDataTable extends DataTableSource {
  // Generate some made-up data
  final List<Customer> _data;
  int total;


  void Function(Customer customer) onDelete;
  void Function(Customer customer) onEdit;
  void Function(Customer customer, bool? value) onSelected;
  Map<String, bool> mapSelected;

  CustomerDataTable(this._data, this.total, this.onDelete, this.onEdit, this.onSelected, this.mapSelected);

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => total;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
    return customerDataRow(_data.elementAt(index));
  }

  DataRow customerDataRow(Customer customer){
    return DataRow(cells: [
      DataCell(Tooltip(message: customer.typology, child: Container(
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          color: black,
        ),
        padding: EdgeInsets.all(5),
        child: Icon(Customer.getIconTypology(customer.typology).icon, size: 16, color: yellow,),
      ))),
      DataCell(Row(
        children: [
          Text(customer.surname.toUpperCase() + " ", style: title.copyWith(color: black, fontSize: 15)),
          Text(customer.isCompany()?customer.name.toUpperCase():customer.name, overflow: TextOverflow.ellipsis,
              style: customer.isCompany()?title.copyWith(color: black, fontSize: 15):subtitle),
        ],
      ),),
      DataCell(Text(customer.email, style: label.copyWith(fontSize: 13),)),
      DataCell(Text(customer.address.address, style: label.copyWith(fontSize: 13),)),
      DataCell(Text(customer.allPhones(), style: label.copyWith(fontSize: 13),)),
      DataCell(Row(
          children: [
            IconButton(onPressed: () => onEdit(customer), icon: Icon(Icons.edit, color: black, size: 20,)),
            SizedBox(width: 5,),
            IconButton(onPressed: () => onDelete(customer), icon:Icon(Icons.delete, color: black, size: 20,))
          ]),)
    ],
        color: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? grey_light: white;
        }),
        selected: mapSelected[customer.id]??false,
        onSelectChanged: (value) => onSelected(customer, value));
  }
}
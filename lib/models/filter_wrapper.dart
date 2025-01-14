import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/event.dart';

class FilterWrapper {

  String fieldName = "";
  dynamic fieldValue = "";
  Function? filterFunction;

  FilterWrapper(this.fieldName, this.fieldValue, this.filterFunction);

  FilterWrapper update(newValue) => FilterWrapper(this.fieldName, newValue, this.filterFunction);

  FilterWrapper.from(FilterWrapper original)
      : fieldName = original.fieldName,
        fieldValue = original.fieldValue,
        filterFunction = original.filterFunction;

  @override
  String toString() {
    return 'FilterWrapper{fieldName: $fieldName, fieldValue: $fieldValue}';
  }

  static Map<String, FilterWrapper> initFilterEvent(){
    // maybe we can put the dbconstants strings
    Map<String, FilterWrapper> filters = {
      "title": new FilterWrapper("title", null, (Event event, value) => value == null || event.title.toUpperCase().contains(value.toUpperCase()) ),
      "address" : new FilterWrapper("address", null, (Event event, value) => value == null || event.address.toUpperCase().contains(value.toUpperCase()) ),
      "phone" : new FilterWrapper("phone", null, (Event event, value) => value == null || event.customer.allPhones().toUpperCase().contains(value.toUpperCase())),
      "startDate" : new FilterWrapper("startDate", null, (Event event, value) => value == null || event.start.add(Duration(minutes: 1)).isAfter(value) ),
      "status" : new FilterWrapper("status", null, (Event event, value) => value == null || event.status == value),
      "endDate" : new FilterWrapper("endDate", null, (Event event, value) => value == null || value.add(Duration(minutes: 1)).isAfter(event.end) ),
      "categories" : new FilterWrapper("categories", <String,bool>{}, (Event event, List<String>? value) =>
      value == null || value.any((category) => category == event.category)),
      "suboperators" : new FilterWrapper("suboperators", <Account>[], (Event event, List<Account>? value) {
        if(value == null) return true;
        List<String> idOperators = [...event.suboperators.map((op) => op.id),event.operator?.id??""];
        if(value.every((element) => idOperators.contains(element.id))) return true;
        return false;
      })};

    return filters;
  }

  static Map<String, FilterWrapper> initFilterCustomer(){
    // maybe we can put the dbconstants strings
    Map<String, FilterWrapper> filters = {
      "name-surname": new FilterWrapper("name-surname", null, (Customer customer, value) => value == null || (customer.name.toUpperCase()+" "+customer.surname.toUpperCase()).contains(value.toUpperCase()) ),
      "email" : new FilterWrapper("email", null, (Customer customer, value) => value == null || customer.email.toUpperCase().contains(value.toUpperCase()) ),
      "phone" : new FilterWrapper("phone", null, (Customer customer, value) => value == null || value == '' || customer.phones.where((phone) => phone.toUpperCase().contains(value.toUpperCase())).isNotEmpty),
      "address" : new FilterWrapper("address", null, (Customer customer, value) => value == null || value == '' || customer.addresses.where((address) => address.address.toUpperCase().contains(value.toUpperCase())).isNotEmpty),
      "partitaIva" : new FilterWrapper("partitaIva", null, (Customer customer, value) => value == null || customer.partitaIva.toUpperCase().contains(value.toUpperCase()) ),
      "codFiscale" : new FilterWrapper("codFiscale", null, (Customer customer, value) => value == null || customer.codFiscale.toUpperCase().contains(value.toUpperCase()) ),
    };

    return filters;
  }
}

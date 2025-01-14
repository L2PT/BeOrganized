import 'package:venturiautospurghi/utils/global_constants.dart';

extension DateTimeExtensions on DateTime {
  String stringify() {
    return this.year.toString() + '-' + ((this.month/10<1)?"0"+this.month.toString():this.month.toString()) + '-' + ((this.day/10<1)?"0"+this.day.toString():this.day.toString());
  }

  //LONGTERMTODO static extension is a working on for flutter team
  DateTime olderBetween(DateTime compare) {
    if(this.isAfter(compare))
      return this;
    else
      return compare;
  }
}
extension ListExtensions on Iterable {
  List<List<T>> groupBy<T, Y>(Y Function(dynamic) fn) {
    Map<Y,List<T>> a = Map.fromIterable(this, key: fn, value: (e)=>[]);
    this.forEach((element){ a[fn.call(element)]!.add(element); });
    return a.values.toList();
  }
  
  Map<Y,int> countBy<Y>(Y Function(dynamic) fn) {
    Map<Y,int> a = Map();
    this.forEach((element) {
      Y key = fn(element);
      a[key] = (a[key] ?? 0) +1;
    });
    return a;
  }

  T removeNulls<T>() {
    this.toList().removeWhere((element) => element==null);
    return this as T;    
  }
}

extension string on String {
  static bool isNullOrEmpty(String? v) {
    return v == null || v == "";
  }
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }

  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  static bool isPhoneNumber(String str) {
    RegExp regExp = new RegExp(Constants.pattternPhoneValid);
    if (str.length == 0) {
      return false;
    }
    else if (!regExp.hasMatch(str)) {
      return false;
    }
    return true;
  }

  static bool isEmail(String str) {
    String patttern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = new RegExp(patttern);
    if (str.length == 0) {
      return false;
    }
    else if (!regExp.hasMatch(str)) {
      return false;
    }
    return true;
  }
}
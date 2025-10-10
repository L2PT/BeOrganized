part of 'operator_list_cubit.dart';

abstract class OperatorListState extends Equatable {
  String searchNameField;
  DateTime searchTimeField;

  OperatorListState([String? searchNameField, DateTime? searchTimeField]) :
        this.searchNameField = searchNameField ?? "",
        this.searchTimeField = searchTimeField ?? _.DateUtils.now();
  
  @override
  List<Object> get props => [searchNameField, searchTimeField];
}

class LoadingOperators extends OperatorListState {
  
}

class ReadyOperators extends OperatorListState {
  List<Account> filteredOperators = [];

  ReadyOperators(List<Account> operators, {String? searchNameField, DateTime? searchTimeField}) : super(searchNameField, searchTimeField) {
    if(string.isNullOrEmpty(searchNameField))
      filteredOperators = [...operators];
    else
      operators.forEach((operator) {
        String searchedFields = operator.name + " " + operator.surname;
        if(searchedFields.toLowerCase().contains(searchNameField!.toLowerCase())){
          filteredOperators.add(operator);
        }
      });
  }

  @override
  List<Object> get props => [filteredOperators.map((op) => op.id).join(), searchNameField, searchTimeField];

  ReadyOperators assign({
    List<Account>? operators,
    String? searchNameField,
    DateTime? searchTimeField,
  }) {
    return ReadyOperators(
        operators ?? this.filteredOperators,
        searchNameField: searchNameField ?? this.searchNameField,
        searchTimeField: searchTimeField ?? this.searchTimeField
    );
  }
}
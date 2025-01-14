import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class PaginationTable extends StatelessWidget {

  DataTableSource source;
  List<String> columnLabels;
  int firstRowIndex;
  int rowsPerPage;
  bool showFirstLastButtons;
  Color arrowHeadColor;
  bool showCheckboxColumn;
  void Function()? handleFirst;
  void Function()? handleLast;
  void Function()? handlePrevious;
  void Function()? handleNext;
  void Function(bool? value)? selectAll;


  PaginationTable(this.source, this.columnLabels, {this.rowsPerPage = 10, this.firstRowIndex = 0,
    this.showFirstLastButtons = false, this.arrowHeadColor = white, this.handleFirst, this.handleLast,
    this.handleNext, this.handlePrevious, this.selectAll, this.showCheckboxColumn = true});

  List<DataRow> _getRows(int firstRowIndex, int rowsPerPage) {
    final List<DataRow> result = <DataRow>[];
    final int nextPageFirstRowIndex = firstRowIndex + rowsPerPage;
    for (int index = firstRowIndex; index < nextPageFirstRowIndex; index += 1) {
      DataRow? row;
      if (index < source.rowCount) {
        row = source.getRow(index);
      }
      if (row != null) {
        result.add(row);
      }
    }
    return result;
  }

  bool _isNextPageUnavailable() =>firstRowIndex + rowsPerPage >= source.rowCount;

  Widget _getFooter(BuildContext context){
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<Widget> footerWidgets = <Widget>[];
    footerWidgets.addAll(<Widget>[
      Container(width: 32.0),
      Text(
        localizations.pageRowsInfoTitle(
          firstRowIndex + 1,
          math.min(firstRowIndex + rowsPerPage, source.rowCount),
          source.rowCount,
          false,
        ),
        style: label_rev,
      ),
      Container(width: 32.0),
      if (showFirstLastButtons)
        IconButton(
          icon: Icon(Icons.skip_previous, color: arrowHeadColor),
          padding: EdgeInsets.zero,
          tooltip: localizations.firstPageTooltip,
          onPressed: firstRowIndex <= 0 ? null : handleFirst,
        ),
      IconButton(
        icon: Icon(Icons.chevron_left, color: arrowHeadColor),
        padding: EdgeInsets.zero,
        tooltip: localizations.previousPageTooltip,
        onPressed: firstRowIndex <= 0 ? null : handlePrevious,
      ),
      Container(width: 24.0),
      IconButton(
        icon: Icon(Icons.chevron_right, color: arrowHeadColor),
        padding: EdgeInsets.zero,
        tooltip: localizations.nextPageTooltip,
        onPressed: _isNextPageUnavailable() ? null : handleNext,
      ),
      if (showFirstLastButtons)
        IconButton(
          icon: Icon(Icons.skip_next, color: arrowHeadColor),
          padding: EdgeInsets.zero,
          tooltip: localizations.lastPageTooltip,
          onPressed: _isNextPageUnavailable()
              ? null
              : handleLast,
        ),
      Container(width: 14.0),
    ]);

    return ClipRRect(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight:  Radius.circular(16)), // Adjust the radius as needed
    child:Container(height: 40,
      color: black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: footerWidgets,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: ClipRRect(
            borderRadius: BorderRadius.circular(16), // Adjust the radius as needed
            child:Theme(data: ThemeData(
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.black;  // Colore quando selezionato
                  }
                  return Colors.white;  // Colore quando non selezionato
                }),
                checkColor: WidgetStateProperty.all(white),
                side: BorderSide(color: grey_light),
              ),),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DataTable(
                      showCheckboxColumn: showCheckboxColumn,
                      onSelectAll: selectAll,

                      headingRowColor: WidgetStateProperty.resolveWith<Color>((states) {
                        return black; // Change to your preferred color
                      }),
                      //rowsPerPage: context.read<CustomerContactsCubit>().state.customerList.length<10?
                      //context.read<CustomerContactsCubit>().state.customerList.length:10,
                      columnSpacing: 10,
                      columns: columnLabels.map((label) => DataColumn(label: Text(label, style: label_rev,),)).toList(),
                      rows: _getRows(firstRowIndex, rowsPerPage),
                      //source: new CustomerDataTable(context.read<CustomerContactsCubit>().state.customerList),
                    ),
                    _getFooter(context)
                  ],
                )
            )
        )
    );
  }

}
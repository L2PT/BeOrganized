import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/card_address_widget.dart';
import 'package:venturiautospurghi/views/widgets/card_referral_widget.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashGap = 3.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    Path dashedPath = Path();
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        double len = dashWidth;
        if (distance + len > measurePath.length) {
          len = measurePath.length - distance;
        }
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CardCustomer extends StatefulWidget {
  final Customer customer;
  final void Function()? onEditAction;
  final void Function()? onDeleteAction;
  final void Function(bool, Customer)? onExpansionChanged;
  final ExpansibleController? controller;
  final double paddingTopHeader;
  final bool expadedMode;
  final bool selectedMode;
  final bool cardMode;
  final bool buttonMode;
  final bool selectAddressMode;
  final bool showAddressSearch;

  // Address action
  final void Function(Address address)? onEditActionAddress;
  final void Function()? onCreateActionAddress;
  final void Function(Address address)? onTapActionAddress;
  final void Function(Address address)? onDeleteActionAddress;
  final void Function(String address)? onLuanchAddressAction;
  final void Function(String phone)? onLuanchPhoneAction;

  // Referrals action
  final void Function(Referrals referrals)? onEditActionReferrals;
  final void Function()? onCreateActionReferrals;
  final void Function(Referrals referrals)? onTapActionReferrals;
  final void Function(Referrals referrals)? onDeleteActionReferrals;

  const CardCustomer({
    super.key,
    required this.customer,
    this.onEditAction,
    this.controller,
    this.onDeleteAction,
    this.onExpansionChanged,
    this.expadedMode = false,
    this.selectedMode = false,
    this.cardMode = false,
    this.selectAddressMode = false,
    this.buttonMode = true,
    this.paddingTopHeader = 3,
    this.showAddressSearch = true,
    this.onEditActionAddress,
    this.onCreateActionAddress,
    this.onDeleteActionAddress,
    this.onTapActionAddress,
    this.onLuanchAddressAction,
    this.onLuanchPhoneAction,
    this.onEditActionReferrals,
    this.onCreateActionReferrals,
    this.onDeleteActionReferrals,
    this.onTapActionReferrals,
  });

  @override
  State<CardCustomer> createState() => _CardCustomerState();
}

class _CardCustomerState extends State<CardCustomer> {
  final TextEditingController _addressSearchCtrl = TextEditingController();
  final TextEditingController _referralSearchCtrl = TextEditingController();
  final TextEditingController _phoneSearchCtrl = TextEditingController();

  bool _showAllAddresses = false;
  bool _showAllReferrals = false;

  String _addressQuery = "";
  String _referralQuery = "";
  String _phoneQuery = "";

  @override
  void initState() {
    super.initState();
    _addressSearchCtrl.addListener(() {
      setState(() {
        _addressQuery = _addressSearchCtrl.text.toLowerCase();
      });
    });
    _referralSearchCtrl.addListener(() {
      setState(() {
        _referralQuery = _referralSearchCtrl.text.toLowerCase();
      });
    });
    _phoneSearchCtrl.addListener(() {
      setState(() {
        _phoneQuery = _phoneSearchCtrl.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _addressSearchCtrl.dispose();
    _referralSearchCtrl.dispose();
    _phoneSearchCtrl.dispose();
    super.dispose();
  }

  Widget addressListElement(Address address) {
    return Container(
        margin: const EdgeInsets.only(top: 10),
        child: CardAddress(
          address: address,
          onclickMode: true,
          selectItem: widget.customer.address == address,
          actionButton: true,
          onTapAction: () => widget.onTapActionAddress!(address),
          onDeleteAction: () => widget.onDeleteActionAddress!(address),
          onEditAction: widget.onEditActionAddress != null ? () => widget.onEditActionAddress!(address) : null,
        ));
  }

  Widget referralsListElement(Referrals referrals) {
    return Container(
        margin: const EdgeInsets.only(top: 10),
        child: CardReferrals(
          referral: referrals,
          onclickMode: true,
          selectItem: widget.customer.selectedReferrals.contains(referrals),
          actionButton: true,
          onTapAction: () => widget.onTapActionReferrals!(referrals),
          onDeleteAction: () => widget.onDeleteActionReferrals!(referrals),
          onEditAction: widget.onEditActionReferrals != null ? () => widget.onEditActionReferrals!(referrals) : null,
        ));
  }

  List<Widget> buttonCustomer() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: widget.onEditAction,
              child: const Text(
                'MODIFICA SCHEDA',
                style: TextStyle(fontWeight: FontWeight.bold, color: black, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: widget.onDeleteAction,
              child: const Text(
                'ELIMINA CLIENTE',
                style: TextStyle(fontWeight: FontWeight.bold, color: black, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
    ];
  }

  Widget headerCustomer() {
    final iconBgColor = black;
    final iconColor = yellow;

    // Build subtitle based on open/closed state
    List<String> subtitleParts = [widget.customer.typology];
    String idVal = widget.customer.isCompany() ? widget.customer.partitaIva : widget.customer.codFiscale;
    if (idVal.isNotEmpty) {
      subtitleParts.add(idVal);
    }
    // Only show email if expanded AND not empty
    if (widget.selectedMode && widget.customer.email.isNotEmpty) {
      subtitleParts.add(widget.customer.email);
    }
    String subtitleText = subtitleParts.join(" • ");

    return Padding(
      padding: EdgeInsets.only(top: widget.paddingTopHeader),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              color: iconBgColor,
            ),
            child: Center(
              child: Icon(
                Customer.getIconTypology(widget.customer.typology).icon,
                size: 24,
                color: iconColor,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.customer.surname.toUpperCase() + " ",
                      style: title.copyWith(color: black, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.customer.name,
                      overflow: TextOverflow.ellipsis,
                      style: subtitle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                if (subtitleText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    overflow: TextOverflow.ellipsis,
                    style: subtitle.copyWith(fontSize: 11, color: grey_dark),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget referralsCustomer() {
    List<Referrals> filteredReferrals = List<Referrals>.from(widget.customer.referrals);
    if (_referralQuery.isNotEmpty) {
      filteredReferrals = filteredReferrals.where((ref) {
        return ref.name.toLowerCase().contains(_referralQuery) ||
               ref.phone.toLowerCase().contains(_referralQuery);
      }).toList();
    }

    filteredReferrals.sort((a, b) {
      final aSelected = widget.customer.selectedReferrals.contains(a);
      final bSelected = widget.customer.selectedReferrals.contains(b);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return 0;
    });

    int hiddenCount = filteredReferrals.length - 2;
    List<Referrals> visibleReferrals = filteredReferrals;
    if (!_showAllReferrals && _referralQuery.isEmpty && filteredReferrals.length > 2) {
      visibleReferrals = filteredReferrals.take(2).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (widget.selectedMode ? widget.customer.referrals.length : (widget.customer.selectedReferrals.isNotEmpty ? widget.customer.selectedReferrals.length : 1)) > 1 ? 'Referenti' : 'Referente',
              style: title.copyWith(fontSize: 15),
            ),
            if (widget.onCreateActionReferrals != null || widget.onEditActionReferrals != null)
              TextButton.icon(
                onPressed: widget.onCreateActionReferrals ?? (widget.onEditActionReferrals != null ? () => widget.onEditActionReferrals!(widget.customer.referral) : null),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.person_add_alt_outlined, size: 14, color: black),
                label: const Text(
                  "Aggiungi",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: black),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.customer.referrals.length > 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: _referralSearchCtrl,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                hintText: 'Cerca referente...',
                hintStyle: subtitle.copyWith(fontSize: 11),
                prefixIcon: const Icon(Icons.search, size: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: black, width: 1.5),
                ),
              ),
            ),
          ),
        widget.customer.referrals.isNotEmpty
            ? widget.selectedMode
                ? (widget.customer.referrals.length > 1
                    ? Column(
                        children: visibleReferrals.map((ref) => referralsListElement(ref)).toList(),
                      )
                    : CardReferrals(
                        referral: widget.customer.referral,
                        onLuanchPhoneAction: widget.onLuanchPhoneAction,
                        onclickMode: widget.selectedMode,
                        selectItem: widget.selectedMode && widget.customer.selectedReferrals.contains(widget.customer.referral) && widget.customer.referral != Referrals.empty(),
                        onTapAction: widget.selectedMode ? () => widget.onTapActionReferrals!(widget.customer.referral) : null,
                        actionButton: widget.onEditActionReferrals != null,
                        onEditAction: widget.onEditActionReferrals != null ? () => widget.onEditActionReferrals!(widget.customer.referral) : null,
                        onDeleteAction: null,
                      ))
                : (widget.customer.selectedReferrals.isNotEmpty
                    ? Column(
                        children: widget.customer.selectedReferrals.map((ref) => CardReferrals(
                          referral: ref,
                          onLuanchPhoneAction: widget.onLuanchPhoneAction,
                          actionButton: false,
                        )).toList(),
                      )
                    : CardReferrals(
                        referral: widget.customer.referral,
                        onLuanchPhoneAction: widget.onLuanchPhoneAction,
                        actionButton: false,
                      ))
            : Text('Nessun referente', overflow: TextOverflow.ellipsis, style: subtitle.copyWith(fontSize: 13)),
        if (widget.selectedMode && !_showAllReferrals && _referralQuery.isEmpty && hiddenCount > 0) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllReferrals = true;
                });
              },
              child: const Text(
                "VEDI TUTTI I REFERENTI",
                style: TextStyle(fontWeight: FontWeight.bold, color: black, fontSize: 11),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget phoneCustomer() {
    List<dynamic> filteredPhones = widget.customer.phones;
    if (_phoneQuery.isNotEmpty) {
      filteredPhones = filteredPhones.where((ph) {
        return ph.toString().toLowerCase().contains(_phoneQuery);
      }).toList();
    }

    bool showEmail = widget.customer.email.isNotEmpty && _phoneQuery.isEmpty;
    if (filteredPhones.isEmpty && !showEmail) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredPhones.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CONTATTI RAPIDI",
                style: title.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: grey_dark),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (widget.customer.phones.length > 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: _phoneSearchCtrl,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                hintText: 'Cerca contatto...',
                hintStyle: subtitle.copyWith(fontSize: 11),
                prefixIcon: const Icon(Icons.search, size: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: black, width: 1.5),
                ),
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...filteredPhones.map((phone) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (widget.onLuanchPhoneAction != null) {
                      widget.onLuanchPhoneAction!(phone.toString());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: grey),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 14, color: grey_dark),
                        const SizedBox(width: 6),
                        Text(phone.toString(), style: subtitle.copyWith(fontSize: 12, color: black)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            if (showEmail)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mail_outline, size: 14, color: grey_dark),
                    const SizedBox(width: 6),
                    Text(widget.customer.email, style: subtitle.copyWith(fontSize: 12, color: black)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> bodyCustomer() {
    List<Address> filteredAddresses = List<Address>.from(widget.customer.addresses);
    if (_addressQuery.isNotEmpty) {
      filteredAddresses = filteredAddresses.where((addr) {
        return addr.address.join(" ").toLowerCase().contains(_addressQuery) ||
               addr.phone.toLowerCase().contains(_addressQuery);
      }).toList();
    }

    if (widget.customer.address != Address.empty()) {
      filteredAddresses.sort((a, b) {
        if (a == widget.customer.address) return -1;
        if (b == widget.customer.address) return 1;
        return 0;
      });
    }

    int hiddenCount = filteredAddresses.length - 2;
    List<Address> visibleAddresses = filteredAddresses;
    if (!_showAllAddresses && _addressQuery.isEmpty && filteredAddresses.length > 2) {
      visibleAddresses = filteredAddresses.take(2).toList();
    }

    return [
      const Divider(color: grey_light),
      const SizedBox(height: 5),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.customer.addresses.length > 1 ? 'Indirizzi' : 'Indirizzo',
            style: title.copyWith(fontSize: 15),
          ),
          if (widget.onCreateActionAddress != null || widget.onEditActionAddress != null)
            TextButton.icon(
              onPressed: widget.onCreateActionAddress ?? (widget.onEditActionAddress != null ? () => widget.onEditActionAddress!(widget.customer.address) : null),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add_location_alt_outlined, size: 14, color: black),
              label: const Text(
                "Aggiungi",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: black),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (widget.showAddressSearch && widget.customer.addresses.length > 3)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: _addressSearchCtrl,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              hintText: 'Cerca indirizzo...',
              hintStyle: subtitle.copyWith(fontSize: 11),
              prefixIcon: const Icon(Icons.search, size: 14, color: grey_dark,),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: black, width: 1.5),
              ),
            ),
          ),
        ),
      widget.selectedMode && widget.customer.addresses.length > 1
          ? Column(
              children: visibleAddresses.map((addr) => addressListElement(addr)).toList(),
            )
          : CardAddress(
              address: widget.customer.address,
              onLuanchPhoneAction: widget.onLuanchPhoneAction,
              onLuanchAddressAction: widget.onLuanchAddressAction,
              actionButton: widget.onEditActionAddress != null,
              onEditAction: widget.onEditActionAddress != null ? () => widget.onEditActionAddress!(widget.customer.address) : null,
              onDeleteAction: null,
            ),
      if (widget.selectedMode && !_showAllAddresses && _addressQuery.isEmpty && hiddenCount > 0) ...[
        const SizedBox(height: 10),
        CustomPaint(
          painter: DashedBorderPainter(color: const Color(0xFFCBD5E1), borderRadius: 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _showAllAddresses = true;
              });
            },
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                "MOSTRA ALTRI $hiddenCount INDIRIZZI",
                style: const TextStyle(fontWeight: FontWeight.bold, color: grey_dark, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 10),
      widget.customer.isAdministrator() ? referralsCustomer() : phoneCustomer(),
      const SizedBox(height: 15),
    ];
  }

  Widget expansionTileMode() {
    List<Widget> body = bodyCustomer();
    if (widget.buttonMode) {
      body.addAll(buttonCustomer());
    }
    return ExpansionTile(
      controller: widget.controller ?? ExpansibleController(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      collapsedIconColor: black,
      onExpansionChanged: (isOpen) {
        if (widget.onExpansionChanged != null) {
          widget.onExpansionChanged!(isOpen, widget.customer);
        }
      },
      title: headerCustomer(),
      initiallyExpanded: widget.expadedMode,
      children: body,
    );
  }

  Widget cardWidgetMode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerCustomer(),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: bodyCustomer()),
          Expanded(child: Container()),
          widget.buttonMode
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: buttonCustomer(),
                )
              : Container()
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      surfaceTintColor: white,
      borderOnForeground: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
          color: widget.selectedMode ? black : grey_light,
          width: widget.selectedMode ? 4 : 0.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: widget.cardMode ? cardWidgetMode() : expansionTileMode(),
      ),
    );
  }
}
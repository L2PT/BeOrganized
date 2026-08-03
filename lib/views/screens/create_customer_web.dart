import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/cubit/create_customer/create_customer_cubit.dart';
import 'package:venturiautospurghi/models/address.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/models/referrals.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/create_entity_utils.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/screens/create_address_view.dart';
import 'package:venturiautospurghi/views/screens/create_referrals_view.dart';
import 'package:venturiautospurghi/views/widgets/card_address_widget.dart';
import 'package:venturiautospurghi/views/widgets/card_referral_widget.dart';
import 'package:venturiautospurghi/views/widgets/web/create_event_web_widgets.dart';

enum _SlidePanel { none, address, referral }

class CreateCustomerWeb extends StatefulWidget {
  const CreateCustomerWeb({super.key});

  @override
  State<CreateCustomerWeb> createState() => _CreateCustomerWebState();
}

class _CreateCustomerWebState extends State<CreateCustomerWeb> with TickerProviderStateMixin {

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  _SlidePanel _activePanel = _SlidePanel.none;
  TypeStatus _sidePanelStatus = TypeStatus.create;
  Address? _editingAddress;
  Referrals? _editingReferral;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _openPanel(_SlidePanel panel, {TypeStatus status = TypeStatus.create}) {
    setState(() {
      _activePanel = panel;
      _sidePanelStatus = status;
    });
    _slideCtrl.forward(from: 0);
  }

  void _closePanel() {
    _slideCtrl.reverse().then((_) {
      if (mounted) setState(() => _activePanel = _SlidePanel.none);
    });
  }

  void _openAddReferralSidePanel() {
    _editingReferral = null;
    context.read<CreateCustomerCubit>().state.customer.referral = Referrals.empty();
    _openPanel(_SlidePanel.referral, status: TypeStatus.create);
  }

  void _openEditReferralSidePanel(Referrals referral) {
    _editingReferral = referral;
    context.read<CreateCustomerCubit>().state.customer.referral = referral;
    _openPanel(_SlidePanel.referral, status: TypeStatus.modify);
  }

  void _openAddAddressSidePanel() {
    _editingAddress = null;
    context.read<CreateCustomerCubit>().state.customer.address = Address.empty();
    _openPanel(_SlidePanel.address, status: TypeStatus.create);
  }

  void _openEditAddressSidePanel(Address address) {
    _editingAddress = address;
    context.read<CreateCustomerCubit>().state.customer.address = address;
    _openPanel(_SlidePanel.address, status: TypeStatus.modify);
  }



  String _getTypologyDescription(String key) {
    if (key == Customer.PRIVATO) return "Persona fisica / Privato";
    if (key == Customer.AZIENDA) return "Ditta / Persona giuridica / Società";
    if (key == Customer.AMMINISTRATORE) return "Amministratore condominiale / Condominio";
    return "Tipologia generica";
  }

  IconData _getTypologyIcon(String key) {
    if (key == Customer.PRIVATO) return FontAwesomeIcons.solidUser;
    if (key == Customer.AZIENDA) return FontAwesomeIcons.solidBuilding;
    if (key == Customer.AMMINISTRATORE) return FontAwesomeIcons.userTie;
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CreateCustomerCubit>().state;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _leftCol(state),
                Expanded(child: _rightCol(state)),
              ],
            ),
            if (_activePanel != _SlidePanel.none)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _slideCtrl,
                  child: GestureDetector(
                    onTap: _closePanel,
                    child: Container(color: Colors.black.withOpacity(0.18)),
                  ),
                ),
              ),
            if (_activePanel != _SlidePanel.none)
              Positioned(
                top: 0, bottom: 0, right: 0,
                child: SlideTransition(
                  position: _slideAnim,
                  child: RepaintBoundary(
                    child: _buildPanelContent(state),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  //  LEFT COLUMN
  // ===========================================================================
  Widget _leftCol(CreateCustomerState state) {
    final cubit = context.read<CreateCustomerCubit>();
    final types = cubit.types;
    return Container(
      width: 310,
      decoration: const BoxDecoration(
        color: white,
        border: Border(right: BorderSide(color: grey_light)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            webSecLbl('Tipologia Cliente'),
            const SizedBox(height: 10),
            ...types.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              final active = state.customer.typology == key;
              final assetPath = (PlatformUtils.isMobile ? 'assets/' : '/typologyCustomer/') + value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AssetTypeCard(
                  label: key,
                  description: _getTypologyDescription(key),
                  assetPath: assetPath,
                  fallbackIcon: _getTypologyIcon(key),
                  active: active,
                  onTap: () => cubit.onSelectedType(key),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  //  RIGHT COLUMN
  // ===========================================================================
  Widget _rightCol(CreateCustomerState state) {
    final cubit = context.read<CreateCustomerCubit>();
    final customer = state.customer;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          webSecLbl('Informazioni Principali'),
          const SizedBox(height: 8),
          Form(
            key: cubit.formKeyBasiclyInfo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customer.isCompany()) ...[
                  Row(
                    children: [
                      Expanded(
                        child: webLField(
                          label: 'Ragione Sociale / Nome', req: true,
                          child: TextFormField(
                            key: ValueKey('name_${customer.typology}'),
                            initialValue: customer.name,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci la ragione sociale o nome..."),
                            validator: (v) => v == null || v.trim().isEmpty ? "Il campo 'Ragione Sociale' è obbligatorio" : null,
                            onSaved: (v) => customer.name = v ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: webLField(
                          label: 'Partita IVA',
                          child: TextFormField(
                            key: ValueKey('partitaIva_${customer.typology}'),
                            initialValue: customer.partitaIva,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci la partita IVA..."),
                            onSaved: (v) => customer.partitaIva = v ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: webLField(
                          label: 'Nome', req: true,
                          child: TextFormField(
                            key: ValueKey('name_${customer.typology}'),
                            initialValue: customer.name,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci il nome..."),
                            validator: (v) => v == null || v.trim().isEmpty ? "Il campo 'Nome' è obbligatorio" : null,
                            onSaved: (v) => customer.name = v ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: webLField(
                          label: 'Cognome',
                          child: TextFormField(
                            key: ValueKey('surname_${customer.typology}'),
                            initialValue: customer.surname,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci il cognome..."),
                            onSaved: (v) => customer.surname = v ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: webLField(
                          label: 'Codice Fiscale',
                          child: TextFormField(
                            key: ValueKey('codFiscale_${customer.typology}'),
                            initialValue: customer.codFiscale,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci il codice fiscale..."),
                            validator: (v) => v != null && v.trim().isNotEmpty && v.trim().length != 16
                                ? "Il codice fiscale deve essere di 16 caratteri"
                                : null,
                            onSaved: (v) => customer.codFiscale = v ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: webLField(
                        label: 'Email',
                        child: TextFormField(
                          key: ValueKey('email_${customer.typology}'),
                          initialValue: customer.email,
                          style: const TextStyle(fontSize: 12.5, color: black),
                          decoration: webIdeco(hint: "Inserisci l'indirizzo email..."),
                          validator: (v) => v != null && v.trim().isNotEmpty && !string.isEmail(v.trim())
                              ? "Inserisci un indirizzo email valido"
                              : null,
                          onSaved: (v) => customer.email = v ?? '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 10, thickness: 1, color: grey_light),
          const SizedBox(height: 14),
          customer.isAdministrator() ? _referentiSection(state) : _telefoniSection(state),
          const SizedBox(height: 20),
          Divider(height: 10, thickness: 1, color: grey_light),
          const SizedBox(height: 14),
          _indirizziSection(state),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  //  PHONE SECTION
  // ===========================================================================
  Widget _telefoniSection(CreateCustomerState state) {
    final cubit = context.read<CreateCustomerCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        webSecLbl('Contatti Telefonici'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: cubit.formFieldPhoneKey,
                maxLines: 1,
                cursorColor: black,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 12.5, color: black),
                decoration: webIdeco(hint: "Aggiungi un numero di telefono..."),
                validator: (value) => !string.isNullOrEmpty(value) && !string.isPhoneNumber(value!)
                    ? 'Inserisci un numero di telefono valido'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: cubit.addPhoneOnCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14),
                  SizedBox(width: 4),
                  Text("Aggiungi", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (state.customer.phones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("Nessun numero di telefono inserito", style: TextStyle(fontSize: 11, color: grey_dark, fontStyle: FontStyle.italic)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: state.customer.phones.map((phone) => Chip(
                label: Text(phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: black)),
                backgroundColor: grey_light2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: grey_light),
                ),
                onDeleted: () => cubit.removePhoneOnCustomer(phone),
                deleteIconColor: red,
                deleteIcon: const Icon(Icons.close, size: 12),
              )).toList(),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  //  REFERRALS SECTION
  // ===========================================================================
  Widget _referentiSection(CreateCustomerState state) {
    final cubit = context.read<CreateCustomerCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        webSecLbl('Referenti Associati'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final int columns = constraints.maxWidth > 500 ? 2 : 1;
            final double itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: EmptyPickerCard(
                    icon: Customer.getIconTypology(Customer.REFERENTE).icon!,
                    title: 'Aggiungi Referente',
                    subtitle: 'Associa un nuovo referente',
                    onTap: _openAddReferralSidePanel,
                  ),
                ),
                ...state.customer.referrals.map((referral) {
                  final isSelected = cubit.onSelectItemReferral(referral);
                  return SizedBox(
                    width: itemWidth,
                    child: CardReferrals(
                      referral: referral,
                      onclickMode: cubit.onClickModeReferral(),
                      selectItem: isSelected,
                      actionButton: true,
                      onTapAction: () => cubit.selectReferralsOnCustomer(referral),
                      onDeleteAction: () => cubit.removeReferralOnCustomer(referral),
                      onEditAction: () => _openEditReferralSidePanel(referral),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  //  ADDRESSES SECTION
  // ===========================================================================
  Widget _indirizziSection(CreateCustomerState state) {
    final cubit = context.read<CreateCustomerCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            webSecLbl('Indirizzi Associati'),
            if (state.customer.addresses.isEmpty) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: red, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final int columns = constraints.maxWidth > 500 ? 2 : 1;
            final double itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: EmptyPickerCard(
                    icon: Icons.place,
                    title: 'Aggiungi Indirizzo',
                    subtitle: 'Associa un nuovo indirizzo',
                    onTap: _openAddAddressSidePanel,
                  ),
                ),
                ...state.customer.addresses.map((address) {
                  final isSelected = cubit.onSelectItemAddress(address);
                  return SizedBox(
                    width: itemWidth,
                    child: CardAddress(
                      address: address,
                      onclickMode: cubit.onClickModeAddress(),
                      selectItem: isSelected,
                      actionButton: true,
                      onTapAction: () => cubit.selectAddressOnCustomer(address),
                      onDeleteAction: () => cubit.removeAddressOnCustomer(address),
                      onEditAction: () => _openEditAddressSidePanel(address),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }

  // Helper styling methods are imported globally from create_event_web_widgets.dart

  // ===========================================================================
  //  SIDE PANEL CONTENT BUILDER
  // ===========================================================================
  Widget _buildPanelContent(CreateCustomerState state) {
    final cubit = context.read<CreateCustomerCubit>();
    switch (_activePanel) {
      case _SlidePanel.address:
        return CreateAddress.slidePanel(
          event: state.event,
          type: _sidePanelStatus,
          onConfirm: (Address address) {
            cubit.addAddress(address, toReplace: _editingAddress);
            _closePanel();
          },
          onClose: _closePanel,
        );
      case _SlidePanel.referral:
        return CreateReferrals.slidePanel(
          event: state.event,
          type: _sidePanelStatus,
          onConfirm: (Referrals referral) {
            cubit.addReferral(referral, toReplace: _editingReferral);
            _closePanel();
          },
          onClose: _closePanel,
        );
      case _SlidePanel.none:
        return const SizedBox.shrink();
    }
  }
}


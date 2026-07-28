import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/cubit/create_event/create_event_cubit.dart';
import 'package:venturiautospurghi/cubit/generate_ai_event/generate_ai_event_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/models/customer.dart';
import 'package:venturiautospurghi/repositories/cloud_firestore_service.dart';
import 'package:venturiautospurghi/utils/colors.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';
import 'package:venturiautospurghi/utils/global_methods.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/screens/customer_selection_view.dart';
import 'package:venturiautospurghi/views/screens/operator_selection_view.dart';
import 'package:venturiautospurghi/views/widgets/platform_datepicker.dart';
import 'package:venturiautospurghi/views/widgets/web/create_event_web_widgets.dart';

// ── Costanti condivise ────────────────────────────────────────────────────────
const _kModalRadius = BorderRadius.only(
  topRight: Radius.circular(12),
  bottomLeft: Radius.circular(12),
  bottomRight: Radius.circular(12),
);

// ─────────────────────────────────────────────────────────────────────────────
//  Slide-panel enum
// ─────────────────────────────────────────────────────────────────────────────
enum _SlidePanel { none, operators, customers }


// ─────────────────────────────────────────────────────────────────────────────
//  CreateEventWeb – schermata principale
// ─────────────────────────────────────────────────────────────────────────────
class CreateEventWeb extends StatefulWidget {
  const CreateEventWeb({super.key});

  @override
  State<CreateEventWeb> createState() => _CreateEventWebState();
}

class _CreateEventWebState extends State<CreateEventWeb>
    with TickerProviderStateMixin {
  final _aiCtrl = TextEditingController();
  bool _isDragging = false;
  bool _isTransitionReady = false;

  // ── Pannello laterale ──────────────────────────────────────────────────────
  _SlidePanel _activePanel = _SlidePanel.none;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _isTransitionReady = true);
      }
    });
  }

  @override
  void dispose() {
    _aiCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _openPanel(_SlidePanel panel) {
    setState(() => _activePanel = panel);
    _slideCtrl.forward(from: 0);
  }

  void _closePanel() {
    _slideCtrl.reverse().then((_) {
      if (mounted) setState(() => _activePanel = _SlidePanel.none);
    });
  }

  void _onPanelConfirmed(_) {
    context.read<CreateEventCubit>().forceRefresh();
    _closePanel();
  }

  void showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: label_rev,),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Build principale ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isTransitionReady) {
      return const SizedBox.shrink();
    }
    final state = context.watch<CreateEventCubit>().state;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: _kModalRadius,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: _kModalRadius,
        child: Stack(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _leftCol(state),
            Expanded(child: _rightCol(state)),
          ]),
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
        ]),
      ),
    );
  }

  Widget _buildPanelContent(CreateEventState state) {
    switch (_activePanel) {
      case _SlidePanel.operators:
        return OperatorSelection.slidePanel(
            event: state.event, onConfirm: _onPanelConfirmed, onClose: _closePanel);
      case _SlidePanel.customers:
        return CustomerSelection.slidePanel(
            event: state.event, onConfirm: _onPanelConfirmed, onClose: _closePanel);
      case _SlidePanel.none:
        return const SizedBox.shrink();
    }
  }

  // ===========================================================================
  //  COLONNA SINISTRA
  // ===========================================================================
  Widget _leftCol(CreateEventState state) => Container(
    width: 310,
    decoration: const BoxDecoration(
      color: white,
      border: Border(right: BorderSide(color: grey_light)),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _secLbl('Campo Testo Libero (IA)'),
        const SizedBox(height: 6),
        _aiCard(),
        const SizedBox(height: 12),
        _tipologiaSection(state),
        const SizedBox(height: 10),
        _categoriaSection(state),
        const SizedBox(height: 12),
        _secLbl('Documenti e Allegati'),
        const SizedBox(height: 6),
        _uploadBox(),
        const SizedBox(height: 5),
        ...state.documents.keys.map(_fileRow),
      ]),
    ),
  );

  Widget _aiCard() => BlocBuilder<GenerateAiEventCubit, GenerateAiEventState>(
    builder: (context, aiState) {
      final isLoading = aiState.isLoading();
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLoading ? const Color(0xFFFFFBF0) : const Color(0xFFFDFCFF),
          border: Border.all(color: isLoading ? yellow : grey_light),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          TextField(
            controller: _aiCtrl, maxLines: 4,
            enabled: !isLoading,
            style: const TextStyle(fontSize: 10.5),
            decoration: InputDecoration(
              hintText: "Descrivi l'attivita a parole tue...",
              hintStyle: const TextStyle(fontSize: 10, color: grey_dark),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: grey_light)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: grey_light)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: yellow)),
              contentPadding: const EdgeInsets.all(8), isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : () async {
                final aiCubit = context.read<GenerateAiEventCubit>();
                final createCubit = context.read<CreateEventCubit>();
                aiCubit.text = _aiCtrl.text;
                final success = await aiCubit.generateEvent();
                if (success) {
                  // Copia i dati generati nel CreateEventCubit
                  createCubit.applyGeneratedEvent(aiCubit.state.event);
                  showSnackbar('Autocompilazione completata', green);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLoading ? const Color(0xFF555555) : black,
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700),
              ),
              child: isLoading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 13, height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text('Elaborazione in corso...'),
                    ])
                  : const Text('Elabora con IA'),
            ),
          ),
        ]),
      );
    },
  );



  Widget _uploadBox() => DropTarget(
    onDragEntered: (_) => setState(() => _isDragging = true),
    onDragExited: (_) => setState(() => _isDragging = false),
    onDragDone: (details) {
      setState(() => _isDragging = false);
      context.read<CreateEventCubit>().addDroppedFiles(details.files);
    },
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<CreateEventCubit>().openFileExplorer(),
        child: CustomPaint(
          painter: DashedRectPainter(
            color: _isDragging ? yellow : const Color(0xFFCBD5E1),
            strokeWidth: _isDragging ? 2.5 : 1.5,
            dashWidth: _isDragging ? 7 : 5,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: _isDragging ? const Color(0xFFF8AD09).withOpacity(0.07) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isDragging ? Icons.file_download_rounded : Icons.upload_file_outlined,
                  key: ValueKey(_isDragging),
                  size: 18,
                  color: _isDragging ? yellow : const Color(0xFFB0BEC5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isDragging ? 'Rilascia il file qui...' : 'Carica un file o trascinalo',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: _isDragging ? yellow : const Color(0xFF374151)),
              ),
              const SizedBox(height: 3),
              Text(
                'PDF, PNG, JPG fino a 10MB',
                style: TextStyle(fontSize: 8.5,
                    color: _isDragging ? yellow.withOpacity(0.7) : const Color(0xFF94A3B8)),
              ),
            ]),
          ),
        ),
      ),
    ),
  );

  Widget _fileRow(String f) => Container(
    margin: const EdgeInsets.only(bottom: 3),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: grey_light),
        borderRadius: BorderRadius.circular(5)),
    child: Row(children: [
      const Icon(Icons.insert_drive_file_outlined, size: 12, color: grey_dark),
      const SizedBox(width: 4),
      Expanded(child: Text(f, style: const TextStyle(fontSize: 9.5, color: black),
          overflow: TextOverflow.ellipsis)),
      GestureDetector(
        onTap: () => context.read<CreateEventCubit>().removeDocument(f),
        child: const Icon(Icons.close, size: 10, color: red),
      ),
    ]),
  );

  // ===========================================================================
  //  COLONNA DESTRA
  // ===========================================================================
  Widget _rightCol(CreateEventState state) {
    final cubit = context.read<CreateEventCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _secLbl('Dettagli Attivita'),
        const SizedBox(height: 8),
        Form(
          key: cubit.formKeyBasiclyInfo,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lField(
              label: 'Titolo Incarico', req: true,
              child: TextFormField(
                initialValue: state.event.title,
                onSaved: (v) => state.event.title = v ?? '',
                onChanged: (v) => state.event.title = v,
                validator: (v) => v == null || v.trim().isEmpty ? "Il campo 'Titolo' e obbligatorio" : null,
                style: const TextStyle(fontSize: 12.5, color: black),
                decoration: _ideco(hint: "Specifica l'oggetto operativo dell'attivita..."),
              ),
            ),
            const SizedBox(height: 10),
            _lField(
              label: 'Descrizione Attivita',
              child: TextFormField(
                initialValue: state.event.description,
                onSaved: (v) => state.event.description = v ?? '',
                onChanged: (v) => state.event.description = v,
                maxLines: 2,
                style: const TextStyle(fontSize: 12.5, color: black),
                decoration: _ideco(hint: 'Aggiungi note specifiche o dettagli sul lavoro...'),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        _clienteSection(state),
        const SizedBox(height: 14),
        _secLbl('Pianificazione Oraria'),
        const SizedBox(height: 6),
        Form(
          key: cubit.formTimeControlsKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _toggles(state),
            const SizedBox(height: 6),
            AnimatedSize(
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
              child: state.event.isRepeated ? _repeatPanel(state) : const SizedBox.shrink(),
            ),
            _dateBlock(state),
          ]),
        ),
        const SizedBox(height: 14),
        Form(key: cubit.formKeyAssignedInfo, child: _operatoriSection(state)),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Tipologia ─────────────────────────────────────────────────────────────
  Widget _tipologiaSection(CreateEventState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Tipologia Attivita', required: true),
      const SizedBox(height: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AssetTypeCard(
          label: 'Intervento', description: 'Pronto intervento o guasto urgente',
          assetPath: 'assets/intervento.png', fallbackIcon: Icons.bolt_outlined,
          active: state.event.typology == 'Intervento',
          onTap: () => context.read<CreateEventCubit>().onSelectedType('Intervento'),
        ),
        const SizedBox(height: 10),
        AssetTypeCard(
          label: 'Contratto', description: 'Lavoro programmato ricorrente',
          assetPath: 'assets/contratto.png', fallbackIcon: Icons.assignment_outlined,
          active: state.event.typology == 'Contratto',
          onTap: () => context.read<CreateEventCubit>().onSelectedType('Contratto'),
        ),
      ]),
      AnimatedSize(
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
        child: (state.event.typology == 'Contratto' || state.event.withCartel)
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: AssetTypeCard(
                  label: 'Esposizione Cartello',
                  description: "E richiesta l'affissione dell'avviso cartaceo",
                  assetPath: 'assets/contratto-cartello.png',
                  fallbackIcon: Icons.assignment_late_outlined,
                  active: state.event.withCartel,
                  onTap: () => context.read<CreateEventCubit>().onSelectedType('contratto-cartello'),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );

  // ── Categoria ─────────────────────────────────────────────────────────────
  Widget _categoriaSection(CreateEventState state) {
    final dbCats = context.read<CloudFirestoreService>().categories;
    if (dbCats.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel("Categoria d'Intervento", required: true),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: dbCats.entries.map((e) {
          final name = e.key;
          final color = HexColor(e.value.toString());
          final active = state.event.category == name;
          return GestureDetector(
            onTap: () => context.read<CreateEventCubit>().onSelectedCategory(name),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.12) : Colors.white,
                  border: Border.all(color: active ? color : grey_light, width: active ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(name, style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? color : black,
                  )),
                  if (active) ...[const SizedBox(width: 4), Icon(Icons.check, size: 11, color: color)],
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  // ── Cliente ───────────────────────────────────────────────────────────────
  Widget _clienteSection(CreateEventState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Cliente Associato', required: true),
      const SizedBox(height: 6),
      state.event.customer.id.isEmpty
          ? EmptyPickerCard(
              icon: FontAwesomeIcons.solidAddressBook,
              title: 'Associa o crea cliente',
              subtitle: 'Nessun cliente inserito',
              onTap: () => _openPanel(_SlidePanel.customers),
            )
          : _clientFilled(state.event.customer),
    ],
  );

  Widget _clientFilled(Customer c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: grey_light),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Black Square with Customer Type Icon
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Customer.getIconTypology(c.typology).icon,
              color: yellow,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Vertical Line
          Container(
            width: 1,
            height: 52,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 12),
          // Content divided into two columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Customer details (Name, Address, Email, Tax Info)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        (c.surname.toUpperCase() + " " + c.name).trim(),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: black),
                      ),
                      const SizedBox(height: 5),
                      // Address
                      if (c.address.address.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 11, color: grey_dark),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.address.address.join(" "),
                                style: const TextStyle(fontSize: 9.5, color: grey_dark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],
                      // Email
                      if (c.email.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 11, color: grey_dark),
                            const SizedBox(width: 4),
                            Text(c.email, style: const TextStyle(fontSize: 9.5, color: grey_dark)),
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],
                      // Tax Info
                      if (c.isCompany() && c.partitaIva.isNotEmpty)
                        Text("P.IVA: ${c.partitaIva}", style: const TextStyle(fontSize: 9.5, color: grey_dark))
                      else if (!c.isCompany() && c.codFiscale.isNotEmpty)
                        Text("C.F.: ${c.codFiscale}", style: const TextStyle(fontSize: 9.5, color: grey_dark)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right Column: Recapiti (Phone numbers / Selected Referents)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.isAdministrator()) ...[
                        if (c.selectedReferrals.isNotEmpty) ...[
                          const Text("Referenti Selezionati:", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: grey_dark)),
                          const SizedBox(height: 4),
                          ...c.selectedReferrals.map((ref) => Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 11, color: black),
                                const SizedBox(width: 4),
                                Text(
                                  "${ref.name}: ${ref.phone}",
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: black),
                                ),
                              ],
                            ),
                          )),
                        ] else
                          const Text("Nessun referente selezionato", style: TextStyle(fontSize: 9.5, color: grey_dark)),
                      ] else ...[
                        if (c.phone.isNotEmpty || c.phones.isNotEmpty) ...[
                          const Text("Recapiti Telefonici:", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: grey_dark)),
                          const SizedBox(height: 4),
                          if (c.phone.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 11, color: black),
                                const SizedBox(width: 4),
                                Text(c.phone, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: black)),
                              ],
                            ),
                          ...c.phones.where((p) => p != c.phone).map((p) => Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 11, color: black),
                                const SizedBox(width: 4),
                                Text(p.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: black)),
                              ],
                            ),
                          )),
                        ] else
                          const Text("Nessun recapito telefonico", style: TextStyle(fontSize: 9.5, color: grey_dark)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Action button
          OutlinedButton(
            onPressed: () => _openPanel(_SlidePanel.customers),
            style: OutlinedButton.styleFrom(
              foregroundColor: black,
              side: const BorderSide(color: grey_light),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Cambia'),
          ),
        ],
      ),
    );
  }

  // ── Toggles ───────────────────────────────────────────────────────────────
  Widget _toggles(CreateEventState state) => Row(children: [
    Expanded(child: _toggle('Tutto il Giorno', 'Senza orario specifico', state.isAllDay,
        (v) => context.read<CreateEventCubit>().setAlldayLong(v))),
    const SizedBox(width: 8),
    Expanded(child: _toggle('Programmato', 'Aggiungi a calendario', state.event.isScheduled,
        (v) => context.read<CreateEventCubit>().setIsScheduled(v))),
    const SizedBox(width: 8),
    Expanded(child: _toggle('Ripetizione', 'Incarico ricorrente', state.event.isRepeated,
        (v) => context.read<CreateEventCubit>().setIsRepeated(v))),
  ]);

  Widget _toggle(String title, String desc, bool val, ValueChanged<bool> onChange) =>
      GestureDetector(
        onTap: () => onChange(!val),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: val ? grey_light2 : const Color(0xFFFAFAFA),
              border: Border.all(color: val ? yellow : grey_light),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: black)),
                Text(desc, style: const TextStyle(fontSize: 8, color: grey_dark)),
              ])),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: val, onChanged: onChange,
                  inactiveTrackColor: grey_light,
                  activeTrackColor: yellow, activeThumbColor: white, focusColor: white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ]),
          ),
        ),
      );

  // ── Ripetizione ───────────────────────────────────────────────────────────
  Widget _repeatPanel(CreateEventState state) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: grey_light),
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Expanded(child: Row(children: [
        const Flexible(child: Text('Esegui il giorno (1-31)',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: black))),
        const SizedBox(width: 8),
        _numberInput(
          value: state.event.recurrenceDayOfMonth > 0 ? state.event.recurrenceDayOfMonth : 1,
          onChanged: (v) { state.event.recurrenceDayOfMonth = v.clamp(1, 31); },
        ),
      ])),
      const SizedBox(width: 14),
      Expanded(child: Row(children: [
        const Flexible(child: Text('Frequenza Ripetizione',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: black))),
        const SizedBox(width: 8),
        const Text('Ogni ', style: TextStyle(fontSize: 11, color: grey_dark)),
        _numberInput(
          value: state.event.recurrenceIntervalInMonths > 0 ? state.event.recurrenceIntervalInMonths : 1,
          onChanged: (v) { state.event.recurrenceIntervalInMonths = v.clamp(1, 99); },
        ),
        const SizedBox(width: 6),
        const Text('mesi', style: TextStyle(fontSize: 11, color: grey_dark, fontWeight: FontWeight.w500)),
      ])),
    ]),
  );

  Widget _numberInput({required int value, required ValueChanged<int> onChanged}) => SizedBox(
    width: 60, height: 32,
    child: TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: black),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: grey_light)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: grey_light)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: yellow)),
      ),
      onChanged: (val) { final v = int.tryParse(val); if (v != null) onChanged(v); },
    ),
  );

  // ── Date / Ore ────────────────────────────────────────────────────────────
  Widget _dateBlock(CreateEventState state) {
    final cubit = context.read<CreateEventCubit>();
    if (state.isAllDay) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _datePickerField(
          context: context,
          label: 'Data Incarico (Tutto il Giorno)',
          date: state.event.start,
          onSelected: cubit.setAllDayDate,
          req: true,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Expanded(child: Row(children: [
          Expanded(child: _datePickerField(
            context: context,
            label: 'Data Inizio',
            date: state.event.start,
            onSelected: cubit.setStartDate,
          )),
          const SizedBox(width: 8),
          Expanded(child: _timePickerField(
            context: context,
            label: 'Ora Inizio',
            time: state.event.start,
            canModify: cubit.canModify,
            minTime: TimeUtils.truncateDate(state.event.start, 'day')
                .add(const Duration(hours: Constants.MIN_WORKTIME)),
            maxTime: TimeUtils.truncateDate(state.event.start, 'day')
                .add(const Duration(hours: Constants.MAX_WORKTIME))
                .subtract(const Duration(minutes: Constants.WORKTIME_SPAN)),
            onConfirm: cubit.setStartTime,
          )),
        ])),
        const SizedBox(width: 10),
        Expanded(child: Row(children: [
          Expanded(child: _datePickerField(
            context: context,
            label: 'Data Fine',
            date: state.event.end,
            onSelected: cubit.setEndDate,
          )),
          const SizedBox(width: 8),
          Expanded(child: _timePickerField(
            context: context,
            label: 'Ora Fine',
            time: state.event.end,
            canModify: cubit.canModify,
            minTime: state.event.start.add(const Duration(minutes: Constants.WORKTIME_SPAN)),
            maxTime: TimeUtils.truncateDate(state.event.end, 'day')
                .add(const Duration(hours: Constants.MAX_WORKTIME)),
            onConfirm: cubit.setEndTime,
          )),
        ])),
      ]),
    );
  }

  Widget _datePickerField({
    required BuildContext context,
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onSelected,
    bool req = false,
  }) {
    return _lField(
      label: label,
      req: req,
      child: GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (d != null) onSelected(d);
        },
        child: _fakeDate(_formatDate(date)),
      ),
    );
  }

  Widget _timePickerField({
    required BuildContext context,
    required String label,
    required DateTime time,
    required bool canModify,
    required DateTime minTime,
    required DateTime maxTime,
    required ValueChanged<dynamic> onConfirm,
  }) {
    return _lField(
      label: label,
      child: GestureDetector(
        onTap: canModify
            ? () => PlatformDatePicker.selectTime(
                  context,
                  minTime: minTime,
                  maxTime: maxTime,
                  currentTime: time,
                  onConfirm: onConfirm,
                )
            : null,
        child: _fakeDate(
          TimeOfDay.fromDateTime(time).format(context),
          isTime: true,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _fakeDate(String text, {bool isTime = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: grey_light),
        borderRadius: BorderRadius.circular(6)),
    child: Row(children: [
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: black))),
      Icon(isTime ? Icons.access_time_outlined : Icons.calendar_today_outlined,
          size: 12, color: grey_dark),
    ]),
  );

  // ── Operatori ─────────────────────────────────────────────────────────────
  Widget _operatoriSection(CreateEventState state) {
    final ops = <Account>[
      if (state.event.operator.id.isNotEmpty) state.event.operator,
      ...state.event.suboperators,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _secLbl('Assegnazione Operatori'),
        OutlinedButton(
          onPressed: _openOperatorPanelIfValid,
          style: OutlinedButton.styleFrom(
            foregroundColor: black, side: const BorderSide(color: grey_light),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('Seleziona Team'),
        ),
      ]),
      const SizedBox(height: 6),
      ops.isEmpty
          ? EmptyPickerCard(
              icon: FontAwesomeIcons.helmetSafety,
              title: "Associa tecnici all'attivita",
              subtitle: 'Nessun operatore assegnato',
              onTap: _openOperatorPanelIfValid,
            )
          : _opGrid(state.event.operator, state.event.suboperators),
    ]);
  }

  void _openOperatorPanelIfValid() {
    final cubit = context.read<CreateEventCubit>();
    final s = cubit.state;
    if (s.event.start.hour < Constants.MIN_WORKTIME || s.event.start.hour >= Constants.MAX_WORKTIME) {
      showSnackbar("Inserisci un'orario iniziale valido", red); return;
    }
    if (s.event.end.hour < Constants.MIN_WORKTIME) {
      showSnackbar("Inserisci un'orario finale valido", red); return;
    }
    if (cubit.formTimeControlsKey.currentState!.validate()) {
      cubit.formTimeControlsKey.currentState!.save();
    }
    _openPanel(_SlidePanel.operators);
  }

  Widget _opGrid(Account primary, List<Account> suboperators) {
    final allOps = <Account>[
      if (primary.id.isNotEmpty) primary,
      ...suboperators,
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: allOps.map((op) {
        final isPrimary = primary.id == op.id;
        return Container(
          width: 170, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPrimary ? grey_light2 : Colors.white,
            border: Border.all(color: isPrimary ? yellow : grey_light, width: isPrimary ? 1.5 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 28, height: 28, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Account.getIconTypology(op.typology).icon,
                  color: yellow,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${op.surname} ${op.name}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: black)),
                Text(op.typology, style: const TextStyle(fontSize: 8.5, color: grey_dark)),
              ])),
              GestureDetector(
                onTap: () => _removeOperator(op, isPrimary, suboperators),
                child: const Icon(Icons.close, size: 11, color: grey_dark),
              ),
            ]),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isPrimary ? yellow : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPrimary ? 'PRINCIPALE' : 'SUPPORTO',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                    color: isPrimary ? Colors.white : const Color(0xFF475569)),
              ),
            ),
            if (!isPrimary) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _promoteOperator(op),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: grey_light),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Rendi Principale',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: grey_dark)),
                ),
              ),
            ],
          ]),
        );
      }).toList(),
    );
  }

  void _removeOperator(Account op, bool isPrimary, List<Account> suboperators) {
    final cubit = context.read<CreateEventCubit>();
    if (isPrimary) {
      cubit.state.event.operator = Account.empty();
      if (suboperators.isNotEmpty) {
        cubit.state.event.operator = suboperators.removeAt(0);
      }
    } else {
      cubit.removeSuboperatorFromEventList(op);
    }
    cubit.forceRefresh();
  }

  void _promoteOperator(Account op) {
    final cubit = context.read<CreateEventCubit>();
    final oldPrimary = cubit.state.event.operator;
    cubit.state.event.operator = op;
    cubit.state.event.suboperators.remove(op);
    if (oldPrimary.id.isNotEmpty) cubit.state.event.suboperators.add(oldPrimary);
    cubit.forceRefresh();
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  Widget _secLbl(String text) => Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
          color: grey_dark, letterSpacing: 0.5));

  Widget _sectionLabel(String text, {bool required = false}) => Row(children: [
    Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
        color: Color(0xFF374151))),
    if (required) const Text(' *', style: TextStyle(color: red, fontWeight: FontWeight.bold)),
  ]);

  Widget _lField({required String label, required Widget child,
      bool req = false, bool hasError = false, String? errTxt}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(label, required: req),
        const SizedBox(height: 4),
        child,
        if (hasError && errTxt != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(errTxt, style: const TextStyle(
                color: red, fontSize: 9.5, fontWeight: FontWeight.w500)),
          ),
      ]);

  InputDecoration _ideco({String? hint, bool err = false}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12.5, color: grey_dark),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: err ? red : grey_light)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: err ? red : grey_light)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: err ? red : yellow)),
    fillColor: err ? const Color(0xFFFEF2F2) : Colors.white,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    isDense: true,
  );
}



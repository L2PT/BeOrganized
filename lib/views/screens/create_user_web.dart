import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:venturiautospurghi/cubit/create_user/create_user_cubit.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/plugins/dispatcher/platform_loader.dart';
import 'package:venturiautospurghi/utils/extensions.dart';
import 'package:venturiautospurghi/utils/theme.dart';
import 'package:venturiautospurghi/views/widgets/web/create_event_web_widgets.dart';

class CreateUserWeb extends StatelessWidget {
  const CreateUserWeb({super.key});

  String _getTypologyDescription(String key) {
    if (key == Account.RESPONSABILE) return "Amministratore / Responsabile di sistema";
    if (key == Account.OPERATORE) return "Operatore sul campo / Dipendente";
    if (key == Account.VEICOLO) return "Mezzo / Veicolo aziendale";
    return "Tipologia generica";
  }

  IconData _getTypologyIcon(String key) {
    if (key == Account.RESPONSABILE) return FontAwesomeIcons.userTie;
    if (key == Account.OPERATORE) return FontAwesomeIcons.helmetSafety;
    if (key == Account.VEICOLO) return FontAwesomeIcons.solidTruck;
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CreateUserCubit>().state;
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _leftCol(context, state),
            Expanded(child: _rightCol(context, state)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  //  LEFT COLUMN
  // ===========================================================================
  Widget _leftCol(BuildContext context, CreateUserState state) {
    final cubit = context.read<CreateUserCubit>();
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
            webSecLbl('Tipologia Utente'),
            const SizedBox(height: 10),
            ...types.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              final active = state.user.typology == key;
              final assetPath = (PlatformUtils.isMobile ? 'assets/' : '/typologyUser/') + value;

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
  Widget _rightCol(BuildContext context, CreateUserState state) {
    final cubit = context.read<CreateUserCubit>();
    final user = state.user;

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
                if (user.isVehicle()) ...[
                  Row(
                    children: [
                      Expanded(
                        child: webLField(
                          label: 'Nome Veicolo', req: true,
                          child: TextFormField(
                            key: ValueKey('surname_${user.typology}'),
                            initialValue: user.surname,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci il nome del veicolo..."),
                            validator: (v) => v == null || v.trim().isEmpty ? "Il campo 'Nome Veicolo' è obbligatorio" : null,
                            onSaved: (v) => user.surname = v ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: webLField(
                          label: 'Targa',
                          child: TextFormField(
                            key: ValueKey('targa_${user.typology}'),
                            initialValue: user.targa,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci la targa..."),
                            onSaved: (v) => user.targa = v ?? '',
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
                            key: ValueKey('name_${user.typology}'),
                            initialValue: user.name,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci il nome..."),
                            validator: (v) => v == null || v.trim().isEmpty ? "Il campo 'Nome' è obbligatorio" : null,
                            onSaved: (v) => user.name = v ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: webLField(
                          label: 'Cognome',
                          child: TextFormField(
                            key: ValueKey('surname_${user.typology}'),
                            initialValue: user.surname,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci il cognome..."),
                            onSaved: (v) => user.surname = v ?? '',
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
                            key: ValueKey('codFiscale_${user.typology}'),
                            initialValue: user.codFiscale,
                            style: const TextStyle(fontSize: 12.5, color: black),
                            decoration: webIdeco(hint: "Inserisci il codice fiscale..."),
                            validator: (v) => v != null && v.trim().isNotEmpty && v.trim().length != 16
                                ? "Il codice fiscale deve essere di 16 caratteri"
                                : null,
                            onSaved: (v) => user.codFiscale = v ?? '',
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
                        label: 'Email', req: true,
                        child: TextFormField(
                          key: ValueKey('email_${user.typology}'),
                          initialValue: user.email,
                          style: const TextStyle(fontSize: 12.5, color: black),
                          decoration: webIdeco(hint: "Inserisci l'indirizzo email..."),
                          validator: (v) => v == null || v.trim().isEmpty || !string.isEmail(v.trim())
                              ? "Inserisci un indirizzo email valido"
                              : null,
                          onSaved: (v) => user.email = v ?? '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: webLField(
                        label: 'Telefono',
                        child: TextFormField(
                          key: ValueKey('phone_${user.typology}'),
                          initialValue: user.phone,
                          style: const TextStyle(fontSize: 12.5, color: black),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: webIdeco(hint: "Inserisci il numero di telefono..."),
                          validator: (v) => v != null && v.trim().isNotEmpty && !string.isPhoneNumber(v.trim())
                              ? "Inserisci un numero di telefono valido"
                              : null,
                          onSaved: (v) => user.phone = v ?? '',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

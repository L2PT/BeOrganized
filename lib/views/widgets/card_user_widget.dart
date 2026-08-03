import 'package:flutter/material.dart';
import 'package:venturiautospurghi/models/account.dart';
import 'package:venturiautospurghi/utils/theme.dart';

class CardUserWidget extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onLock;
  final VoidCallback onDelete;

  CardUserWidget({
    required this.account,
    required this.onEdit,
    required this.onLock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Account.getIconTypology(account.typology).icon, color: yellow, size: 22),
            ),
            SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: 'Roboto'),
                children: [
                  TextSpan(text: "${account.surname.toUpperCase()} ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: account.name),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              account.email.isNotEmpty ? account.email : 'Nessuna email',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              account.phone.isNotEmpty ? account.phone : 'Nessun telefono',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.edit, onEdit),
                SizedBox(width: 8),
                _buildActionButton(Icons.lock, onLock),
                SizedBox(width: 8),
                _buildActionButton(Icons.delete, onDelete),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: black,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
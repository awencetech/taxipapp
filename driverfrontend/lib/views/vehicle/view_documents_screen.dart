import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/driver_models.dart';
import 'document_upload_screen.dart';

class ViewDocumentsScreen extends StatefulWidget {
  const ViewDocumentsScreen({super.key});

  @override
  State<ViewDocumentsScreen> createState() => _ViewDocumentsScreenState();
}

class _ViewDocumentsScreenState extends State<ViewDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh driver profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.fetchDriverProfile();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green;
      case 'Expiring Soon':
        return Colors.orange;
      case 'Pending':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Documents'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          if (authViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicleDocs = authViewModel.getDocumentsByCategory('vehicle');
          final personalDocs = authViewModel.getDocumentsByCategory('personal');

          debugPrint('Vehicle docs length: ${vehicleDocs.length}');
          debugPrint('Personal docs length: ${personalDocs.length}');
          debugPrint('All docs: ${authViewModel.documents}');

          if (vehicleDocs.isEmpty && personalDocs.isEmpty) {
            return const Center(
              child: Text(
                'No documents uploaded yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildDocSection(
                'Vehicle Documents',
                vehicleDocs,
                'vehicle',
                authViewModel,
              ),
              const SizedBox(height: 32),
              _buildDocSection(
                'Personal Documents',
                personalDocs,
                'personal',
                authViewModel,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocSection(
    String title,
    List<DocumentModel> docs,
    String category,
    AuthViewModel authViewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...docs.map((doc) => _buildDocItem(doc, category, authViewModel)),
      ],
    );
  }

  Widget _buildDocItem(
    DocumentModel doc,
    String category,
    AuthViewModel authViewModel,
  ) {
    final theme = Theme.of(context);
    final color = _getStatusColor(doc.status);

    return GestureDetector(
      onTap: () async {
        if (doc.url != null && doc.url!.isNotEmpty) {
          final uri = Uri.parse(doc.url!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open: ${doc.url}')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                doc.status == 'Verified'
                    ? Icons.verified_user_outlined
                    : (doc.status == 'Pending'
                          ? Icons.pending_actions_outlined
                          : Icons.error_outline),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (doc.uploadedAt != null)
                    Text(
                      'Uploaded: ${doc.uploadedAt!.day}/${doc.uploadedAt!.month}/${doc.uploadedAt!.year}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  if (doc.expiryDate != null)
                    Text(
                      'Expires: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                doc.status,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFFF6D00)),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentUploadScreen(
                      documentTitle: doc.title,
                      category: category,
                      document: doc,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Document updated successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Document?'),
                    content: const Text(
                      'Are you sure you want to remove this document?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await authViewModel.deleteDocument(
                    docId: doc.id,
                  );
                  if (mounted && success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Document deleted successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

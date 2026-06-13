import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/driver_models.dart';
import 'package:image_picker/image_picker.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String documentTitle;
  final String category;
  final DocumentModel? document;

  const DocumentUploadScreen({
    super.key, 
    required this.documentTitle,
    this.category = 'vehicle',
    this.document,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  PlatformFile? _selectedFile;
  DateTime? _selectedExpiryDate;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      _selectedExpiryDate = widget.document!.expiryDate;
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  Future<void> _uploadAndSave() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      XFile? xFile;
      if (_selectedFile != null) {
        if (kIsWeb) {
          xFile = XFile.fromData(
            _selectedFile!.bytes!,
            name: _selectedFile!.name,
          );
        } else {
          xFile = XFile(_selectedFile!.path!);
        }
      }

      bool success;
      if (widget.document != null) {
        // Edit existing document
        success = await authViewModel.editDocument(
          docId: widget.document!.id,
          title: widget.documentTitle,
          category: widget.category,
          documentFile: xFile,
          expiryDate: _selectedExpiryDate,
        );
      } else {
        // Upload new document
        success = await authViewModel.uploadDocument(
          title: widget.documentTitle,
          category: widget.category,
          documentFile: xFile,
          expiryDate: _selectedExpiryDate,
        );
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditMode = widget.document != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit ${widget.documentTitle}' : 'Upload ${widget.documentTitle}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode 
                  ? 'Please update your document (PDF format only)' 
                  : 'Please upload your document in PDF format only for verification.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Expiry Date Picker
            GestureDetector(
              onTap: _isUploading ? null : _pickExpiryDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedExpiryDate != null 
                          ? 'Expiry Date: ${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}' 
                          : 'Select Expiry Date (Optional)',
                      style: TextStyle(
                        color: _selectedExpiryDate != null ? theme.colorScheme.onSurface : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: const Color(0xFFFF6D00)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Picker
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (_selectedFile != null || (widget.document != null && widget.document!.url != null)) 
                        ? const Color(0xFFFF6D00) 
                        : Colors.grey.withValues(alpha: 0.3), 
                    style: BorderStyle.solid,
                    width: (_selectedFile != null || (widget.document != null && widget.document!.url != null)) ? 2 : 1,
                  ),
                ),
                child: (_selectedFile != null || (widget.document != null && widget.document!.url != null))
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFile?.name ?? 'Current Document',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (_selectedFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Change File'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6D00)),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Icon(Icons.upload_file_outlined, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to select PDF document',
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Only .pdf files are accepted',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditMode ? 'Update Document' : 'Save & Submit', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../dashboard/dashboard_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _selectedFilter = 'All Documents';

  final List<Map<String, dynamic>> documents = [
    {
      'id': 'DOC001',
      'name': 'Aadhar Card',
      'associatedWith': 'Rajesh Kumar',
      'uploadDate': '2024-01-15',
      'expiryDate': '2030-12-31',
      'status': 'Verified',
      'type': 'Driver Documents',
      'url': 'https://example.com/aadhar.pdf',
    },
    {
      'id': 'DOC002',
      'name': 'Driving License',
      'associatedWith': 'Rajesh Kumar',
      'uploadDate': '2024-01-15',
      'expiryDate': '2028-06-30',
      'status': 'Verified',
      'type': 'Driver Documents',
      'url': 'https://example.com/license.pdf',
    },
    {
      'id': 'DOC003',
      'name': 'RC Book',
      'associatedWith': 'Vehicle MH 02 AB 1234',
      'uploadDate': '2024-01-20',
      'expiryDate': '2027-03-15',
      'status': 'Verified',
      'type': 'Vehicle Documents',
      'url': 'https://example.com/rc.pdf',
    },
    {
      'id': 'DOC004',
      'name': 'Insurance',
      'associatedWith': 'Vehicle MH 02 AB 1234',
      'uploadDate': '2024-06-15',
      'expiryDate': '2026-12-31',
      'status': 'Pending',
      'type': 'Vehicle Documents',
      'url': 'https://example.com/insurance.pdf',
    },
    {
      'id': 'DOC005',
      'name': 'PUC Certificate',
      'associatedWith': 'Vehicle MH 03 CD 5678',
      'uploadDate': '2024-05-01',
      'expiryDate': '2026-05-30',
      'status': 'Expired',
      'type': 'Vehicle Documents',
      'url': 'https://example.com/puc.pdf',
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case 'Verified':
        return const Color(0xFF22C55E);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Expired':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Color getStatusBgColor(String status, bool isDark) {
    switch (status) {
      case 'Verified':
        return isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7);
      case 'Pending':
        return isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFFFFEED3);
      case 'Expired':
        return isDark ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFFFFE4E6);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  Future<void> _handleDownload(Map<String, dynamic> doc) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${doc['name']}...'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${doc['name']} downloaded successfully!'),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  Future<void> _handlePreview(Map<String, dynamic> doc) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc['name']),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description,
                  size: 80,
                  color: Color(0xFFFF7A00),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preview of ${doc['name']}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Associated with: ${doc['associatedWith']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = result.files.first;
        setState(() {
          documents.add({
            'id': 'DOC${documents.length + 101}',
            'name': file.name,
            'associatedWith': 'General',
            'uploadDate': DateTime.now().toIso8601String().split('T')[0],
            'expiryDate': 'N/A',
            'status': 'Pending',
            'type': 'General Documents',
            'url': file.path,
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  List<Map<String, dynamic>> getFilteredDocuments() {
    if (_selectedFilter == 'All Documents') {
      return documents;
    } else if (_selectedFilter == 'Pending') {
      return documents.where((d) => d['status'] == 'Pending').toList();
    } else if (_selectedFilter == 'Expired') {
      return documents.where((d) => d['status'] == 'Expired').toList();
    } else {
      return documents.where((d) => d['type'] == _selectedFilter).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final isDark = themeVM.isDarkMode;
    final filteredDocs = getFilteredDocuments();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? const Color(0xFF0D1B2A) : const Color(0xFF1D2951),
                      isDark ? const Color(0xFF1B263B) : const Color(0xFF2D4A6D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Documents Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage driver and vehicle documents',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildStatCard(
                      title: 'Verified Documents',
                      value: '3',
                      icon: Icons.check_circle,
                      color: const Color(0xFF22C55E),
                      bgColor: const Color(0xFFDCFCE7),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Pending Verification',
                      value: '1',
                      icon: Icons.access_time,
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFEED3),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Expired Documents',
                      value: '1',
                      icon: Icons.close,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFFE4E6),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Upload Button Centered
              Center(
                child: ElevatedButton.icon(
                  onPressed: _handleUpload,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Upload Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Document Repository Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Document Repository',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All uploaded and verified documents',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All Documents', 'Driver Documents', 'Vehicle Documents', 'Pending', 'Expired']
                              .map((filter) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedFilter == filter
                                        ? const Color(0xFFFF7A00)
                                        : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: _selectedFilter == filter
                                          ? Colors.white
                                          : (isDark ? Colors.grey[300] : Colors.black),
                                      fontWeight: _selectedFilter == filter
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Documents List
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 70,
                          columnSpacing: 16,
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          dataTextStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                          ),
                          columns: const [
                            DataColumn(label: Text('Document ID')),
                            DataColumn(label: Text('Document Name')),
                            DataColumn(label: Text('Associated With')),
                            DataColumn(label: Text('Upload Date')),
                            DataColumn(label: Text('Expiry Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredDocs.map((doc) {
                            return DataRow(
                              cells: [
                                DataCell(Text(doc['id'])),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECD2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.description,
                                          size: 16,
                                          color: Color(0xFFFF7A00),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          doc['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    doc['associatedWith'],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataCell(Text(doc['uploadDate'])),
                                DataCell(Text(doc['expiryDate'])),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusBgColor(doc['status'], isDark),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          doc['status'] == 'Verified' ? Icons.check_circle :
                                          doc['status'] == 'Pending' ? Icons.access_time :
                                          Icons.close,
                                          size: 14,
                                          color: getStatusColor(doc['status']),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          doc['status'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: getStatusColor(doc['status']),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _handlePreview(doc),
                                        icon: const Icon(
                                          Icons.remove_red_eye,
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _handleDownload(doc),
                                        icon: const Icon(
                                          Icons.download,
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.2) : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

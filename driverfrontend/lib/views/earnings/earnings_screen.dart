import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../profile/bank_details_screen.dart';
import '../home/home_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedTab = 'This Week';

  Future<void> _generateAndDownloadPDF() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final driver = authViewModel.driver;

    // Create PDF document
    final pdf = pw.Document();

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final nonNullDriver = driver;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [
                      PdfColor.fromInt(0xFF2D2D2D),
                      PdfColor.fromInt(0xFFE65100),
                    ],
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Earnings Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'For: ${driver?.name ?? 'Driver'}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColor.fromInt(0xB3FFFFFF), // 70% white
                      ),
                    ),
                    pw.Text(
                      'Period: $_selectedTab',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColor.fromInt(0xB3FFFFFF), // 70% white
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Earnings Summary
              pw.Text(
                'Earnings Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("This Week's Earnings:", style: const pw.TextStyle(fontSize: 14)),
                  pw.Text('₹15,420', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Today:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('₹2,850', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Yesterday:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('₹3,200', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('This Month:', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('₹58,900', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 24),

              // Statistics
              pw.Text(
                'Statistics',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                context: null,
                headers: ['Metric', 'Value'],
                data: [
                  ['Total Trips', '42'],
                  ['Average Fare', '₹367'],
                  ['Peak Hours', '6PM - 9PM'],
                  ['Top Route', 'MG Road'],
                ],
              ),
              pw.SizedBox(height: 24),

              // Bank Details (if available)
              if (nonNullDriver != null && nonNullDriver.bankName.isNotEmpty) ...[
                pw.Text(
                  'Bank Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Bank: ${nonNullDriver.bankName}'),
                if (nonNullDriver.accountNumber.length >= 4)
                  pw.Text('Account: **** **** **** ${nonNullDriver.accountNumber.substring(nonNullDriver.accountNumber.length - 4)}'),
              ],
            ],
          );
        },
      ),
    );

    // Save or print the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'earnings_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2D2D), Color(0xFFE65100)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          HomeScreen.of(context)?.setSelectedIndex(0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Earnings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Track your income and performance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Main Earnings Card
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A00),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "This Week's Earnings",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              "₹15,420",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.trending_up, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Today', '₹2850'),
                        _buildSummaryItem('Yesterday', '₹3200'),
                        _buildSummaryItem('This Month', '₹58,900'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final authViewModel = context.watch<AuthViewModel>();
                final driver = authViewModel.driver;
                
                if (driver != null && driver.bankAccounts.isNotEmpty) {
                  // Show saved bank details on earnings page too for consistency
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BankDetailsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.teal[50]!,
                              Colors.teal[100]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.teal[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.teal[600],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.account_balance, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver.bankAccounts[0].bankName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    () {
                                      final accNo = driver.bankAccounts[0].accountNumber;
                                      if (accNo.length >= 4) {
                                        return '**** **** **** ${accNo.substring(accNo.length - 4)}';
                                      }
                                      return '';
                                    }(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit, color: Colors.teal[600], size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),

            // Custom Tab Switcher
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabItem('Today'),
                  _buildTabItem('This Week'),
                  _buildTabItem('This Month'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Weekly Earnings Trend Chart Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Weekly Earnings Trend",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Mock Chart using Containers
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(120, "Mon"),
                        _buildBar(160, "Tue"),
                        _buildBar(140, "Wed"),
                        _buildBar(180, "Thu"),
                        _buildBar(150, "Fri"),
                        _buildBar(100, "Sat"),
                        _buildBar(60, "Sun"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Statistics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.8,
                    children: [
                      _buildStatCard("42", "Total Trips"),
                      _buildStatCard("₹367", "Average Fare"),
                      _buildStatCard("6PM - 9PM", "Peak Hours", icon: Icons.access_time),
                      _buildStatCard("MG Road", "Top Route", icon: Icons.map_outlined),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Download Report Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _generateAndDownloadPDF,
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text("Download Earnings Report"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label) {
    bool isSelected = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 25,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A00),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFFFF8A00)),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}



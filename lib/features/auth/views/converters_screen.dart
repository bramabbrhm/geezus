import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ConvertersScreen extends StatefulWidget {
  const ConvertersScreen({super.key});

  @override
  State<ConvertersScreen> createState() => _ConvertersScreenState();
}

class _ConvertersScreenState extends State<ConvertersScreen> {
  final TextEditingController _amountController = TextEditingController(text: '100.000');
  String _selectedCurrency = 'USD';
  String _conversionResult = '';
  
  // Timer untuk zona waktu real-time
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  // Kurs asumsi terhadap IDR (Rupiah)
  final Map<String, double> _exchangeRates = {
    'USD': 15500.0, // 1 USD = Rp 15.500
    'EUR': 16800.0, // 1 EUR = Rp 16.800
    'SGD': 11500.0, // 1 SGD = Rp 11.500
  };

  @override
  void initState() {
    super.initState();
    _calculateConversion('100000');
    
    // Jalankan timer untuk memperbarui detik jam global setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _calculateConversion(String rawValue) {
    // Hilangkan semua titik agar bisa dibaca sebagai angka mentah
    String cleanValue = rawValue.replaceAll('.', '');
    double inputIdr = double.tryParse(cleanValue) ?? 0.0;
    double rate = _exchangeRates[_selectedCurrency] ?? 15500.0;
    
    double result = inputIdr / rate;

    setState(() {
      _conversionResult = '${result.toStringAsFixed(2)} $_selectedCurrency';
    });
  }

  // Fungsi untuk memformat angka dengan pemisah titik otomatis (contoh: 100.000)
  String _formatNumber(String string) {
    if (string.isEmpty) return '';
    string = string.replaceAll('.', '');
    if (double.tryParse(string) == null) return string;
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(double.parse(string)).replaceAll(',', '.');
  }

  // Fungsi untuk menampilkan jam berdasarkan zona waktu tertentu
  String _getTimeForOffset(int hoursOffset) {
    DateTime targetTime = _currentTime.toUtc().add(Duration(hours: hoursOffset));
    return DateFormat('HH:mm:ss').format(targetTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Modul Konversi & Zona Waktu', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Konversi Mata Uang
            const Text(
              'Konversi Poin Reward (IDR ke Valuta Asing)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Jumlah dalam IDR (Rp)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        String formatted = _formatNumber(val);
                        _amountController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                        _calculateConversion(formatted);
                      } else {
                        _calculateConversion('0');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          dropdownColor: const Color(0xFF1E1E2C),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF121212),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: ['USD', 'EUR', 'SGD'].map((currency) {
                            return DropdownMenuItem(value: currency, child: Text(currency));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCurrency = val!;
                              _calculateConversion(_amountController.text);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Hasil: $_conversionResult',
                      style: const TextStyle(color: Color(0xFF00E676), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bagian Zona Waktu Global (Real-time detik berjalan)
            const Text(
              'Zona Waktu Global Marathon',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTimeZoneTile('WIB (Jakarta)', 7),
                  const Divider(height: 1, color: Colors.white24),
                  _buildTimeZoneTile('WITA (Makassar)', 8),
                  const Divider(height: 1, color: Colors.white24),
                  _buildTimeZoneTile('WIT (Jayapura)', 9),
                  const Divider(height: 1, color: Colors.white24),
                  _buildTimeZoneTile('London (UTC)', 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeZoneTile(String title, int offsetHours) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Text(
        _getTimeForOffset(offsetHours),
        style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
    );
  }
}
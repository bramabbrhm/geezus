import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class ConvertersScreen extends StatefulWidget {
  const ConvertersScreen({super.key});

  @override
  State<ConvertersScreen> createState() => _ConvertersScreenState();
}

class _ConvertersScreenState extends State<ConvertersScreen> {
  // Controller dengan teks awal terformat
  final TextEditingController _idrController = TextEditingController(text: '100.000');
  
  String _selectedCurrency = 'USD';
  double _result = 6.45;

  // Kurs konversi (Contoh asumsi nilai tukar terhadap IDR)
  final Map<String, double> _rates = {
    'USD': 0.0000645, // 1 IDR ke USD
    'EUR': 0.0000590, // 1 IDR ke EUR
    'SGD': 0.0000860, // 1 IDR ke SGD
  };

  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
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
    _idrController.dispose();
    super.dispose();
  }

  // Fungsi untuk memformat angka dengan titik otomatis saat diketik
  void _onIdrChanged(String value) {
    // Hapus semua karakter selain angka
    String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanValue.isEmpty) {
      _idrController.text = '';
      _idrController.selection = const TextSelection.collapsed(offset: 0);
      setState(() {
        _result = 0.0;
      });
      return;
    }

    final double? parsedValue = double.tryParse(cleanValue);
    if (parsedValue == null) {
      setState(() {
        _result = 0.0;
      });
      return;
    }
    
    // Format angka menggunakan pemisah titik ala Indonesia
    final formatter = NumberFormat('#,###', 'id_ID');
    String formatted = formatter.format(parsedValue).replaceAll(',', '.');

    _idrController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    // Hitung hasil konversi
    setState(() {
      _result = parsedValue * (_rates[_selectedCurrency] ?? 0.0000645);
    });
  }

  void _onCurrencyChanged(String? newCurrency) {
    if (newCurrency != null) {
      setState(() {
        _selectedCurrency = newCurrency;
        // Hitung ulang berdasarkan nilai saat ini
        String cleanValue = _idrController.text.replaceAll(RegExp(r'[^0-9]'), '');
        double parsedValue = double.tryParse(cleanValue) ?? 0;
        _result = parsedValue * (_rates[_selectedCurrency] ?? 0.0000645);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime utcTime = _currentTime.toUtc();
    DateTime wibTime = utcTime.add(const Duration(hours: 7));
    DateTime witaTime = utcTime.add(const Duration(hours: 8));
    DateTime witTime = utcTime.add(const Duration(hours: 9));
    DateTime londonTime = utcTime;

    String formatDigits(int n) => n.toString().padLeft(2, '0');
    String getTimeString(DateTime dt) => 
        '${formatDigits(dt.hour)}:${formatDigits(dt.minute)}:${formatDigits(dt.second)}';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Modul Konversi & Zona Waktu', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konversi Poin Reward (IDR ke Valuta Asing)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jumlah dalam IDR (Rp)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  
                  // Input Nominal dengan Format Titik Otomatis
                  TextField(
                    controller: _idrController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _onIdrChanged,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dropdown Pilihan Valuta Asing (USD, EUR, SGD)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        dropdownColor: const Color(0xFF1E1E2C),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: ['USD', 'EUR', 'SGD'].map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: _onCurrencyChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kotak Hasil Konversi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hasil:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(
                          '${_result.toStringAsFixed(2)} $_selectedCurrency',
                          style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ZONA WAKTU GLOBAL MARATHON (REAL-TIME)
            const Text(
              'Zona Waktu Global Marathon',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('WIB (Jakarta)', style: TextStyle(color: Colors.white)),
                    trailing: Text(getTimeString(wibTime), style: const TextStyle(color: Color(0xFF9C88FF), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    title: const Text('WITA (Makassar)', style: TextStyle(color: Colors.white)),
                    trailing: Text(getTimeString(witaTime), style: const TextStyle(color: Color(0xFF9C88FF), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    title: const Text('WIT (Jayapura)', style: TextStyle(color: Colors.white)),
                    trailing: Text(getTimeString(witTime), style: const TextStyle(color: Color(0xFF9C88FF), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    title: const Text('London (UTC)', style: TextStyle(color: Colors.white)),
                    trailing: Text(getTimeString(londonTime), style: const TextStyle(color: Color(0xFF9C88FF), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

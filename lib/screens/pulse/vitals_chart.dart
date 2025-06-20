import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/theme_notifier.dart'; // adaptează calea dacă e nevoie

// FUNCTIE: Fetch date din InfluxDB
Future<String?> fetchVitalsFromInflux() async {
  final url = Uri.parse('https://us-east-1-1.aws.cloud2.influxdata.com/api/v2/query?org=UNITBV');
  final token = 'hN8YT0iff_SWbUopWAfCaEZ5YxiUMABzq_dnCZNfwImbzcbGrHHzwplkULzKuJOSJAgqTjQVZnk-uphaC2EhNQ==';

  final fluxQuery = '''
from(bucket: "DateSenzorPuls")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "health_metrics")
  |> filter(fn: (r) => r._field == "bpm" or r._field == "spo2" or r._field == "temp" or r._field == "pasi")
  |> last()
''';

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/vnd.flux',
      'Accept': 'application/csv',
    },
    body: fluxQuery,
  );
  print("STATUS: ${response.statusCode}");
  print("BODY:\n${response.body}");

  if (response.statusCode == 200) {
    return response.body;
  } else {
    print('Eroare: ${response.statusCode} ${response.body}');
    return null;
  }
}

// FUNCTIE: Parsează CSV din InfluxDB în map - SIGURĂ PE HEADER!
Map<String, dynamic> parseVitalsCsv(String csv) {
  final lines = csv.split('\n');
  if (lines.length < 2) return {};

  // Găsește index-urile coloanelor relevante
  final header = lines[0].split(',');
  int idxField = header.indexOf('_field');
  int idxValue = header.indexOf('_value');
  // Poți adăuga și timestamp, dacă vrei: int idxTime = header.indexOf('_time');

  Map<String, dynamic> data = {};

  for (var line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final columns = line.split(',');
    if (columns.length <= idxValue || columns.length <= idxField) continue;
    final field = columns[idxField].trim();
    final value = columns[idxValue].trim();
    data[field] = value;
  }
  print("VitalsData: $data"); // Debug: vezi ce valori ai în map
  return data;
}

class VitalsChartScreen extends StatefulWidget {
  const VitalsChartScreen({super.key});

  @override
  State<VitalsChartScreen> createState() => _VitalsChartScreenState();
}

class _VitalsChartScreenState extends State<VitalsChartScreen> {
  Map<String, dynamic>? vitalsData;
  bool loading = true;
  String? errorMsg;
  Timer? _timer; // Variabilă pentru Timer

  @override
  void initState() {
    super.initState();
    fetchAndParseVitals();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchAndParseVitals();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchAndParseVitals() async {
    try {
      final csv = await fetchVitalsFromInflux();
      if (csv != null) {
        final data = parseVitalsCsv(csv);
        setState(() {
          vitalsData = data;
          loading = false;
        });
      } else {
        setState(() {
          errorMsg = tr("error_fetch");
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obține tema actuală din provider (asigură-te că ai ThemeNotifier peste app!)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF232323) : Colors.white;
    final accentColor = const Color(0xFF217A6B);

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr("vitals_title"))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(tr("loading")),
            ],
          ),
        ),
      );
    }
    if (errorMsg != null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr("vitals_title"))),
        body: Center(child: Text(errorMsg!)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("vitals_title")),
        actions: [
          // Schimbă tema (toggle light/dark)
        //  IconButton(
         //   icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          //  onPressed: () {
          //   final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
           //   themeNotifier.toggleTheme(isDark);
           // },
          //  tooltip: isDark ? 'Light mode' : 'Dark mode',
        //  ),
          // Schimbă limba rapid
        //  IconButton(
          //  icon: const Icon(Icons.translate),
           // onPressed: () {
           //   final newLocale = context.locale.languageCode == 'ro'
           //      ? const Locale('en')
            //      : const Locale('ro');
           //   context.setLocale(newLocale);
           // },
          //  tooltip: 'Switch language',
        //  ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _vitalTile(tr("pulse"), vitalsData?["bpm"], tr("unit_bpm"), accentColor, cardColor, isDark),
          _vitalTile(tr("spo2"), vitalsData?["spo2"], tr("unit_percent"), accentColor, cardColor, isDark),
          _vitalTile(tr("temperature"), vitalsData?["temp"], tr("unit_celsius"), accentColor, cardColor, isDark),
          _vitalTile(tr("steps"), vitalsData?["pasi"], "", accentColor, cardColor, isDark),
        ],
      ),
    );
  }

  Widget _vitalTile(String label, dynamic value, String unit, Color accent, Color card, bool isDark) {
    String showValue = (value != null && value.toString().isNotEmpty) ? value.toString() : "--";
    return Card(
      color: card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : accent,
          ),
        ),
        trailing: Text(
          showValue,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : accent,
          ),
        ),
        subtitle: unit.isNotEmpty
            ? Text(
          unit,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        )
            : null,
      ),
    );
  }
}

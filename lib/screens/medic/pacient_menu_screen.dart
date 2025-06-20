import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

// ====================== FETCH & PARSE LOGIC =========================

Future<String?> fetchVitalsFromInflux(String pacientId) async {
  final url = Uri.parse('https://us-east-1-1.aws.cloud2.influxdata.com/api/v2/query?org=UNITBV');
  final token = 'hN8YT0iff_SWbUopWAfCaEZ5YxiUMABzq_dnCZNfwImbzcbGrHHzwplkULzKuJOSJAgqTjQVZnk-uphaC2EhNQ==';

  // Poți filtra după pacientId dacă ai acel camp în datele tale Influx!
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
  if (response.statusCode == 200) {
    return response.body;
  } else {
    return null;
  }
}

Map<String, dynamic> parseVitalsCsv(String csv) {
  final lines = csv.split('\n');
  if (lines.length < 2) return {};

  final header = lines[0].split(',');
  int idxField = header.indexOf('_field');
  int idxValue = header.indexOf('_value');

  Map<String, dynamic> data = {};
  for (var line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final columns = line.split(',');
    if (columns.length <= idxValue || columns.length <= idxField) continue;
    final field = columns[idxField].trim();
    final value = columns[idxValue].trim();
    data[field] = value;
  }
  return data;
}

// ======================= UI =========================

class PacientMenuScreen extends StatefulWidget {
  final String pacientId;
  final String nume;
  final String prenume;

  const PacientMenuScreen({
    Key? key,
    required this.pacientId,
    required this.nume,
    required this.prenume,
  }) : super(key: key);

  @override
  State<PacientMenuScreen> createState() => _PacientMenuScreenState();
}

class _PacientMenuScreenState extends State<PacientMenuScreen> {
  Map<String, dynamic>? vitalsData;
  bool loading = true;
  String? errorMsg;
  Timer? _timer;

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
      final csv = await fetchVitalsFromInflux(widget.pacientId);
      if (csv != null) {
        final data = parseVitalsCsv(csv);
        setState(() {
          vitalsData = data;
          loading = false;
        });
      } else {
        setState(() {
          errorMsg = "no_data".tr();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF18191B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.nume} ${widget.prenume}'),
        backgroundColor: isDark ? const Color(0xFF232323) : const Color(0xFF217A6B),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: pageBg,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Center(child: Text(errorMsg!))
          : ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _vitalTile(context, "pulse".tr(), vitalsData?["bpm"], "unit_bpm".tr()),
          _vitalTile(context, "spo2".tr(), vitalsData?["spo2"], "unit_percent".tr()),
          _vitalTile(context, "temperature".tr(), vitalsData?["temp"], "unit_celsius".tr()),
          _vitalTile(context, "steps".tr(), vitalsData?["pasi"], "unit_steps".tr()),
        ],
      ),
    );
  }

  Widget _vitalTile(BuildContext context, String label, dynamic value, String unit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String showValue = (value != null && value.toString().isNotEmpty) ? value.toString() : "--";
    return Card(
      color: isDark ? const Color(0xFF232323) : Colors.white,
      elevation: 3,
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        trailing: Text(
          showValue,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: unit.isNotEmpty
            ? Text(unit, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]))
            : null,
      ),
    );
  }
}

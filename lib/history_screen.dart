// File: lib/history_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/ble_scanner_cubit.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _dateController = TextEditingController(text: formattedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _requestData() {
    final cubit = context.read<BleScannerCubit>();
    final date = _dateController.text;
    if (date.isNotEmpty) {
      cubit.requestLogFile("$date.txt");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateRequester(),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: BlocBuilder<BleScannerCubit, BleScannerState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.logLines.isEmpty) {
                    return const Center(
                      child: Text('No data. Request a file to view logs.'),
                    );
                  }
                  return _buildDataDisplay(state.logLines);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRequester() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: 'Log Date (YYYY-MM-DD)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: const Text("Load"),
          onPressed: _requestData,
        ),
      ],
    );
  }

  Widget _buildDataDisplay(List<String> lines) {
    final data = _parseLogData(lines);

    // If no valid data found
    if (data.pm2p5.isEmpty) {
      return const Center(child: Text("Could not parse file data."));
    }

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Particulate Matter (µg/m³)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildChartSection('PM 1.0', data.pm1p0, Colors.purpleAccent),
        _buildChartSection('PM 2.5', data.pm2p5, Colors.pinkAccent),
        _buildChartSection('PM 4.0', data.pm4p0, Colors.blueAccent),
        _buildChartSection('PM 10.0', data.pm10p0, Colors.teal),

        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Environmental Data",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildChartSection('Temperature (°C)', data.temp, Colors.orangeAccent),
        _buildChartSection('Humidity (%)', data.hum, Colors.cyan),

        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Gas & Air Quality",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildChartSection('VOC Index', data.voc, Colors.deepPurple),
        _buildChartSection('NOx Index', data.nox, Colors.redAccent),
        _buildChartSection('CO2 (ppm)', data.co2, Colors.green),

        const Divider(),
        ExpansionTile(
          title: Text('Raw Log Data (${lines.length} lines)'),
          children: [
            Container(
              height: 200,
              color: Colors.black12,
              child: ListView.builder(
                itemCount: lines.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    lines[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(String title, List<FlSpot> spots, Color color) {
    if (spots.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ), // Hide time for cleanliness
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper class for parsed data
  ParsedLogData _parseLogData(List<String> lines) {
    final data = ParsedLogData();

    for (final line in lines) {
      try {
        // Format: YYYY-MM-DDTHH:MM:SS,PM1.0:10,PM2.5:15,PM4.0:16,PM10.0:18,T:5080,H:4550,VOC:120,NOx:10,CO2:850
        final parts = line.split(',');
        if (parts.length < 10) continue; // Ensure we have all columns

        final timestampStr = parts[0];
        final dateTime = DateTime.parse(timestampStr);
        final double x = dateTime.millisecondsSinceEpoch.toDouble();

        // Helper to extract value after ':'
        double getVal(String part) => double.parse(part.split(':')[1]);

        data.pm1p0.add(FlSpot(x, getVal(parts[1])));
        data.pm2p5.add(FlSpot(x, getVal(parts[2])));
        data.pm4p0.add(FlSpot(x, getVal(parts[3])));
        data.pm10p0.add(FlSpot(x, getVal(parts[4])));

        // Sensirion Scaling: Temp / 200, Hum / 100
        data.temp.add(FlSpot(x, getVal(parts[5]) / 200.0));
        data.hum.add(FlSpot(x, getVal(parts[6]) / 100.0));

        data.voc.add(FlSpot(x, getVal(parts[7])));
        data.nox.add(FlSpot(x, getVal(parts[8])));
        data.co2.add(FlSpot(x, getVal(parts[9])));
      } catch (e) {
        // Silently ignore lines that fail parsing to prevent crash
      }
    }
    return data;
  }
}

class ParsedLogData {
  List<FlSpot> pm1p0 = [];
  List<FlSpot> pm2p5 = [];
  List<FlSpot> pm4p0 = [];
  List<FlSpot> pm10p0 = [];
  List<FlSpot> temp = [];
  List<FlSpot> hum = [];
  List<FlSpot> voc = [];
  List<FlSpot> nox = [];
  List<FlSpot> co2 = [];
}

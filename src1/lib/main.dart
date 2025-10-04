import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/alert.dart';
import 'services/api_service.dart';
import 'widgets/left_panel.dart';
import 'widgets/map_view.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the assets folder
  await dotenv.load(fileName: "assets/.env");
  // print the Google Maps API key for debugging
  print(dotenv.env['GOOGLE_MAPS_API_KEY']);
  // Dynamically inject the Google Maps script tag into the HTML head
  final completer = Completer<void>();
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
    ..async = true
    ..defer = true;

  script.onLoad.listen((_) => completer.complete());
  script.onError.listen((_) => completer.completeError('Failed to load Google Maps script.'));

  html.document.head?.append(script);
  await completer.future;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEO Orbiters',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  List<Alert> _alerts = [];
  String _lastUpdate = '';
  FIRType _selectedFir = FIRType.all;
  Alert? _selectedAlert;
  MapMode _mapMode = MapMode.twoD;
  String _selectedDate = '';
  List<String> _availableDates = [];
  Timer? _fetchTimer;

  @override
  void initState() {
    super.initState();
    _generateDateRange();
    _fetchAlerts();
    _fetchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchAlerts();
    });
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    super.dispose();
  }

  void _generateDateRange() {
    final dates = <String>[];
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      final formatted =
          '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
      dates.add(formatted);
    }
    setState(() {
      _availableDates = dates;
      _selectedDate = dates.isNotEmpty ? dates[0] : '';
    });
  }

  Future<void> _fetchAlerts() async {
    try {
      final response = await _apiService.fetchAlerts();
      setState(() {
        _alerts = response.alerts;
        _lastUpdate = response.lastUpdate;
      });
    } catch (e) {
      debugPrint('Failed to fetch alerts: $e');
    }
  }

  void _handleFirChange(FIRType fir) {
    setState(() {
      _selectedFir = fir;
      _selectedAlert = null;
    });
  }

  void _handleAlertClick(Alert alert) {
    setState(() {
      _selectedAlert = alert;
    });
  }

  void _handleMapModeChange(MapMode mode) {
    setState(() {
      _mapMode = mode;
    });
  }

  void _handleDateChange(String date) {
    setState(() {
      _selectedDate = date;
    });
  }

  List<Alert> get _filteredAlerts {
    if (_selectedFir == FIRType.all) {
      return _alerts;
    }
    return _alerts.where((alert) => alert.fir == _selectedFir.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          LeftPanel(
            alerts: _alerts,
            lastUpdate: _lastUpdate,
            selectedFir: _selectedFir,
            onFirChange: _handleFirChange,
            onAlertClick: _handleAlertClick,
          ),
          Expanded(
            child: MapView(
              alerts: _filteredAlerts,
              selectedAlert: _selectedAlert,
              mapMode: _mapMode,
              onMapModeChange: _handleMapModeChange,
              selectedDate: _selectedDate,
              onDateChange: _handleDateChange,
              availableDates: _availableDates,
            ),
          ),
        ],
      ),
    );
  }
}

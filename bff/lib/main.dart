import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const BffWorkshopApp());
}

class BffWorkshopApp extends StatelessWidget {
  const BffWorkshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BFF Pattern Workshop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // CONFIGURACIÓN DE RED
  // 10.0.2.2 es la IP para acceder al localhost de la PC desde el emulador Android.
  // Cambiar por la IP real de tu PC (ej. 192.168.1.X) si pruebas en celular físico.
  static const String host = "192.168.1.14"; 
  
  final Map<String, String> microservices = {
    "1": "Restaurantes",
    "2": "Pedidos",
    "3": "Perfil",
  };

  Map<String, bool> activeToggles = {"1": true, "2": true, "3": true};

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  int? lastLatency;
  List<dynamic> results = [];
  String currentMethod = "";

  Future<void> _fetchDirectly() async {
    final activeIndices = activeToggles.entries.where((e) => e.value).map((e) => e.key).toList();
    if (activeIndices.isEmpty) {
      _handleNoServiceSelected();
      return;
    }

    _resetState("Carga Directa (Anti-patrón)");
    final stopwatch = Stopwatch()..start();

    try {
      final urls = activeIndices.map((idx) => "http://$host:800${idx}/data").toList();
      final responses = await Future.wait(
        urls.map((url) => http.get(Uri.parse(url)).timeout(const Duration(seconds: 5))),
      );

      stopwatch.stop();
      
      setState(() {
        results = responses.map((res) => jsonDecode(res.body)).toList();
        lastLatency = stopwatch.elapsedMilliseconds;
        isLoading = false;
      });
    } catch (e) {
      _handleError();
    }
  }

  Future<void> _fetchViaBFF() async {
    final activeIndices = activeToggles.entries.where((e) => e.value).map((e) => e.key).join(",");
    if (activeIndices.isEmpty) {
      _handleNoServiceSelected();
      return;
    }

    _resetState("Carga vía BFF (Gateway)");
    final stopwatch = Stopwatch()..start();

    try {
      final bffUrl = "http://$host:8000/bff?active_services=$activeIndices";
      final response = await http.get(Uri.parse(bffUrl)).timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          results = data['results'];
          lastLatency = stopwatch.elapsedMilliseconds;
          isLoading = false;
        });
      } else {
        throw Exception("Error del servidor");
      }
    } catch (e) {
      _handleError();
    }
  }

  void _handleNoServiceSelected() {
    setState(() {
      errorMessage = "Por favor, selecciona al menos un servicio para probar.";
      results = [];
    });
  }

  void _resetState(String method) {
    setState(() {
      currentMethod = method;
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      results = [];
      lastLatency = null;
    });
  }

  void _handleError() {
    setState(() {
      isLoading = false;
      errorMessage = "¡Ups! La señal se perdió. Estamos intentando reconectar...";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Laboratorio BFF", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatCard(),
            const SizedBox(height: 20),
            _buildTogglesSection(),
            const SizedBox(height: 20),
            _buildActionButton(
              label: "Carga Directa",
              icon: Icons.flash_off,
              color: Colors.redAccent,
              onPressed: isLoading ? null : _fetchDirectly,
              subtitle: "Peticiones individuales",
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: "Carga BFF",
              icon: Icons.bolt,
              color: Colors.green,
              onPressed: isLoading ? null : _fetchViaBFF,
              subtitle: "Una sola petición filtrada",
            ),
            const SizedBox(height: 25),
            if (isLoading) 
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              _buildErrorView()
            else if (results.isNotEmpty)
              _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTogglesSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              "Configuración de Microservicios",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: activeToggles.keys.map((key) {
                return Column(
                  children: [
                    Switch(
                      value: activeToggles[key]!,
                      onChanged: (val) => setState(() => activeToggles[key] = val),
                      activeColor: Colors.indigo,
                    ),
                    Text(microservices[key]!, style: const TextStyle(fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo[900],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(
            currentMethod.isEmpty ? "Selecciona un método" : currentMethod,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            lastLatency != null ? "$lastLatency ms" : "-- ms",
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Latencia total en UI",
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String subtitle,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Estado de los Servicios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...microservices.entries.map((entry) {
          final String id = entry.key;
          final String name = entry.value;
          final bool isActive = activeToggles[id] ?? false;
          
          // Buscamos si hay un resultado real para este servicio en la lista que trajo el backend
          final result = results.firstWhere(
            (res) => res['service'] == name,
            orElse: () => null,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: isActive ? 1 : 0,
            color: isActive ? Colors.white : Colors.grey[200],
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isActive ? Colors.indigo[50] : Colors.grey[300],
                child: Icon(
                  isActive ? Icons.cloud_done : Icons.cloud_off,
                  size: 20,
                  color: isActive ? Colors.indigo : Colors.grey[600],
                ),
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black87 : Colors.grey[600],
                ),
              ),
              subtitle: Text(
                isActive 
                  ? (result != null ? "Status: ${result['status']}" : "Cargando...") 
                  : "Servicio Desactivado",
                style: TextStyle(color: isActive ? Colors.green[700] : Colors.grey[500]),
              ),
              trailing: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.redAccent,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Column(
        children: [
          const Icon(Icons.signal_wifi_off, size: 50, color: Colors.orange),
          const SizedBox(height: 15),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.brown, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => currentMethod.contains("Directa") ? _fetchDirectly() : _fetchViaBFF(),
            icon: const Icon(Icons.refresh),
            label: const Text("Reintentar ahora"),
          )
        ],
      ),
    );
  }
}

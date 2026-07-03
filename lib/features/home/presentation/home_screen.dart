import 'package:flutter/material.dart';
import '../../sos/presentation/sos_screen.dart';
import '../../services_screen/presentation/emergency_services_screen.dart';
import '../../contacts/presentation/contacts_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// Contenedor principal con navegación inferior.
/// Nota: Mapa, Historial, Perfil Médico y Acerca de se acceden desde el
/// menú lateral / botones de Configuración en esta primera entrega; se
/// integran como tabs adicionales en la siguiente iteración del proyecto.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    SosScreen(),
    EmergencyServicesScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sos_rounded), label: 'SOS'),
          NavigationDestination(icon: Icon(Icons.local_hospital_rounded), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.contacts_rounded), label: 'Contactos'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}

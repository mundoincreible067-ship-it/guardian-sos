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

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const SosScreen();
      case 1:
        return const EmergencyServicesScreen();
      case 2:
        return const ContactsScreen();
      case 3:
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Antes usaba IndexedStack, que mantiene las 4 pantallas construidas
      // y sus animaciones corriendo en segundo plano todo el tiempo, aunque
      // no se estén viendo — eso era lo que ralentizaba la app. Ahora solo
      // se construye (y anima) la pantalla que realmente se está mostrando.
      body: _buildScreen(_index),
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

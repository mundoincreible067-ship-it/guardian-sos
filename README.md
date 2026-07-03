# Guardian SOS

Aplicación móvil Flutter de emergencias personales. Botón SOS con envío automático
de ubicación, llamadas de emergencia, contactos, perfil médico y más.

## ⚠️ Estado de este proyecto — léelo primero

Este es un proyecto **real y compilable**, construido con arquitectura limpia
(Riverpod + Repository Pattern), pero es la **primera entrega** de un desarrollo
por etapas. Ya funcionan de extremo a extremo:

- ✅ Botón SOS con cuenta regresiva configurable
- ✅ Captura de GPS de alta precisión, dirección, velocidad, batería y precisión
- ✅ Envío de SMS directo (Android) + WhatsApp + Email pre-rellenados
- ✅ Gestión de hasta 10 contactos con contacto principal
- ✅ Pantalla de servicios de emergencia con llamada directa y números editables
- ✅ Configuración (tema claro/oscuro, cuenta regresiva, switches de funciones)
- ✅ Permisos completos declarados en Android e iOS

**Pendiente para la siguiente iteración** (decide con qué seguimos):

| Función | Estado |
|---|---|
| Grabación automática de audio/video | Servicio por integrar (`camera` + `record` ya en pubspec) |
| Flash estroboscópico + alarma sonora | Por integrar (`torch_light` + `audioplayers` ya en pubspec) |
| Detección de caídas (acelerómetro) | Por integrar (`sensors_plus` ya en pubspec) |
| Activación por voz ("SOS", "Ayuda") | Por integrar (`speech_to_text` ya en pubspec) |
| Activación por botones físicos (volumen x5) | Por integrar — limitación de SO, ver nota abajo |
| Mapa en vivo con recorrido (Google Maps) | Pantalla por construir (`google_maps_flutter` ya en pubspec) |
| Historial local + Firebase | Por construir (SQLite + Firestore) |
| Perfil médico + QR | Por construir (`qr_flutter` ya en pubspec) |
| Firebase Auth / Firestore / Storage / FCM | Paquetes listos, falta `flutterfire configure` |
| Notificaciones push | Por integrar (`flutter_local_notifications` ya en pubspec) |

Pídeme "continúa con [función]" y la construyo completa, sin recortar código,
igual que las piezas ya incluidas.

## Requisitos

- Flutter 3.19+ / Dart 3.3+
- Android Studio o VS Code con plugin de Flutter
- Una cuenta de Firebase (gratuita) si quieres backend en la nube
- Una API Key de Google Maps (gratuita hasta cierto uso)

## Instalación

```bash
cd guardian_sos
flutter pub get
```

### Android

1. Abre el proyecto en Android Studio.
2. Reemplaza `TU_GOOGLE_MAPS_API_KEY_AQUI` en
   `android/app/src/main/AndroidManifest.xml` por tu clave real de
   [Google Cloud Console](https://console.cloud.google.com/) (habilita "Maps SDK for Android").
3. Compilar APK: `flutter build apk --release`
4. Compilar AAB para Play Store: `flutter build appbundle --release`

### iOS

1. Abre `ios/Runner.xcworkspace` en Xcode (tras `flutter pub get`, corre `pod install` dentro de `ios/`).
2. Añade tu API Key de Google Maps en `ios/Runner/AppDelegate.swift`.
3. Configura tu Team/Bundle ID en Xcode para firmar.
4. Compilar: `flutter build ios --release`

### Firebase (opcional pero recomendado)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto genera `lib/firebase_options.dart`. Luego descomenta en `lib/main.dart`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Activa en la consola de Firebase: Authentication, Cloud Firestore, Storage y
Cloud Messaging.

## ⚠️ Limitaciones reales de plataforma (importante)

Estas restricciones **no son un defecto del código**, son políticas de
seguridad de Android/iOS que ninguna app puede saltarse:

- **SMS automático sin tocar nada**: solo es posible en Android si el usuario
  concede el permiso `SEND_SMS` (ya implementado). En iOS, Apple no lo permite
  bajo ninguna circunstancia: se abre el compositor de Mensajes pre-rellenado
  y el usuario toca enviar (1 toque).
- **Llamada 100% automática sin confirmación**: en Android funciona con el
  permiso `CALL_PHONE`. En iOS, Apple exige siempre que el usuario confirme
  desde la app Teléfono — se abre el marcador con el número ya cargado.
- **Activación con 5 pulsaciones del botón de volumen/encendido**: ni Android
  ni iOS exponen una API pública para interceptar estos botones estando la
  app en segundo plano o con la pantalla apagada, por razones de seguridad
  (evitar apps espía). La alternativa funcional real es un widget de
  pantalla de bloqueo / acceso directo de app, o activación por voz.
- **Grabación en segundo plano prolongada**: ambos sistemas limitan el tiempo
  que una app puede grabar con la pantalla apagada sin un *foreground
  service* declarado (ya añadido en el Manifest) y, en iOS, sin que el usuario
  reabra la app periódicamente.

## Arquitectura

```
lib/
  core/            → theme, constantes, servicios compartidos, providers globales
  features/
    sos/           → botón SOS y lógica de disparo
    contacts/      → contactos de emergencia (domain/data/presentation)
    services_screen/→ pantalla de llamada a servicios de emergencia
    settings/      → configuración de la app
    home/          → shell de navegación
    medical_profile/ (próxima entrega)
    history/       (próxima entrega)
    map/           (próxima entrega)
```

Patrón: **Clean Architecture** ligera (domain/data/presentation por feature) +
**Riverpod** para estado + **Repository Pattern** para persistencia.

## Publicación

- **Google Play**: necesitas firmar el AAB con un keystore propio
  (`flutter build appbundle` + configurar `key.properties`, no incluido aquí
  por seguridad — genera el tuyo con `keytool`).
- **App Store**: necesitas cuenta de Apple Developer ($99/año) y certificados
  de distribución configurados en Xcode.

# Rumbo - Lugares turísticos

Aplicación web desarrollada con **Flutter, Dart, Firebase Authentication, Cloud Firestore y Riverpod**.

## Ejecutar en desarrollo

Desde esta carpeta (la que contiene `pubspec.yaml`):

```bash
flutter pub get
flutter run -d chrome
```

## Configuración de Firebase

1. Crear un proyecto en Firebase Console.
2. Registrar la aplicación Flutter para Web con FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   dart pub global run flutterfire_cli:flutterfire configure --project=TU_PROJECT_ID --platforms=web
   ```
3. Mantener el archivo generado `lib/firebase_options.dart` en el proyecto para que `main.dart` pueda inicializar Firebase.
4. En **Authentication > Método de acceso**, habilitar **Correo electrónico/Contraseña**.
5. Crear una base de **Cloud Firestore**.
6. Copiar y publicar las reglas del archivo `firestore.rules` en **Firestore Database > Reglas**.

## Datos y persistencia

- Al entrar por primera vez con una cuenta, se crean seis destinos turísticos de ejemplo en Firestore.
- Los destinos se guardan por usuario autenticado en la colección `places`.
- La marca de carga inicial se guarda en `users/{uid}`, por lo que los ejemplos no se vuelven a crear si el usuario los elimina.
- Las altas, modificaciones y bajas se realizan directamente sobre Cloud Firestore.
- Los cambios permanecen guardados al cerrar y volver a abrir el navegador, siempre que se ingrese con la misma cuenta.

## Campos de cada destino

Nombre, descripción, URL de imagen, país/ubicación, valoración, comidas típicas, lugares imperdibles y recomendaciones.

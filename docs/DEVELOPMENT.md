# Desarrollo de Gaspi

Código Flutter/Dart para Windows x64 y Android. La interfaz ofrece modo claro, negro mate profundo y reproducción inmersiva. El logo animado se dibuja con vectores en Flutter; los iconos de sistema son estáticos, como corresponde a Android y Windows.

## Requisitos

- Flutter 3.44.3 / Dart 3.12.2, usados para la versión 0.1.0.
- Windows: Visual Studio con las herramientas de escritorio C++.
- Android: JDK 17, Android SDK y licencias aceptadas.

## Ejecutar

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Para Android, conecta un dispositivo con depuración USB, consulta `flutter devices` y usa `flutter run -d ID_DEL_DISPOSITIVO`.

## Compilar

```powershell
.\Build-Gaspi.ps1 -Target windows
.\Build-Gaspi.ps1 -Target android
.\Build-Gaspi.ps1 -Target all
```

El script local analiza, prueba y genera ZIP/APK en `releases/`. El [workflow de GitHub](../.github/workflows/release.yml) genera también el instalador Windows con [Inno Setup](../installer/gaspi.iss), añade las DLL de Visual C++ y publica los archivos con SHA-256 en una Release. Las compilaciones de la versión 0.1.0 finalizaron correctamente: [registro](https://github.com/DAJEFF11/Gaspi/actions/runs/39312328052).

El entorno automatizado local utilizado al preparar el proyecto bloqueó los procesos hijos de Dart; esa limitación se resolvió para la distribución compilando en GitHub Actions. Los binarios publicados proceden de ese flujo, no de las capturas simuladas.

## Datos y formatos

El selector admite MP3, FLAC, WAV, OGG, OPUS, M4A, AAC, AIF/AIFF, APE, WMA, ALAC y WV. media_kit/libmpv se encarga de la decodificación. La compatibilidad depende del archivo y su códec; las etiquetas dañadas no impiden importar el nombre del archivo como alternativa.

En Windows se conservan rutas a los originales. Android mantiene una copia en el directorio privado de soporte de Gaspi, con SHA-256 para deduplicar. La biblioteca, playlists, favoritos, carátulas, letras y tema son locales. El índice usa una copia de seguridad. Quitar registros no borra los originales ni las copias internas; desinstalar Android elimina los datos privados de la app.

Las letras embebidas se leen durante la importación. Puedes añadir `.lrc` o `.txt` desde la interfaz; en Windows se detecta el `.lrc` junto al audio. Las LRC resaltan la línea correspondiente y permiten buscar pulsando una línea; todavía no hay desplazamiento automático.

## Estructura

- `lib/main.dart`: inicialización de ventanas y audio.
- `lib/app.dart`: biblioteca, temas, agrupaciones y reproducción inmersiva.
- `lib/library.dart`: importación, persistencia, cola y reproductor.
- `lib/models.dart`: canciones y análisis LRC.
- `lib/metadata.dart`: extracción de etiquetas y carátulas en otro isolate.
- `lib/ghost.dart`: identidad vectorial animada; respeta movimiento reducido.
- `test/`: pruebas de lógica.
- `tool/render_preview.dart`: arnés con datos ficticios y reproductor simulado, utilizado para las capturas. No es la entrada de la app.

## Alcance de la vista previa

No incluye servicio Android de reproducción en segundo plano, controles de pantalla bloqueada, ecualizador, sincronización entre dispositivos ni edición de etiquetas. No se probó reproducción o instalación en dispositivos reales durante esta entrega. El APK usa firma de depuración y el instalador Windows no tiene firma Authenticode.

[Verificación](../VERIFICACION.md) · [Informe REA](../analysis/REA-SPOTIFY.md) · [Release 0.1.0](https://github.com/DAJEFF11/Gaspi/releases/tag/v0.1.0)


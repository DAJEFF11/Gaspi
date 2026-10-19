# Gaspi · tu música, tu espacio

Reproductor local para **Windows y Android** desarrollado con Flutter. Incluye biblioteca, búsqueda, álbumes, artistas, favoritos, playlists, cola, letras locales, modo claro y negro mate profundo. Sin cuentas, anuncios ni música de la nube.

El diseño sigue las referencias aportadas: panel blanco minimalista con carátulas compactas y selección de canción invertida; en PC, barra lateral y panel de reproducción. La vista de pantalla completa muestra carátula grande a la izquierda y canción, letra, progreso, controles y volumen a la derecha. El fondo difumina la carátula, con menor intensidad en modo oscuro. En móvil se organiza en una columna.

El logo es un fantasmita propio: flota, parpadea y respeta la preferencia de movimiento reducido. Hay versiones SVG animada, GIF, PNG y los iconos nativos en `branding/` y en cada plataforma.

## Abrir y compilar

Requiere Flutter estable compatible con Dart 3.12.2 o posterior; aquí se detectó Flutter 3.44.3. Windows necesita Visual Studio con desarrollo de escritorio en C++; Android necesita Android SDK/JDK y licencias aceptadas.

Desde esta carpeta, en una terminal normal:

```powershell
flutter pub get
flutter run -d windows
```

Para generar entregas:

```powershell
.\Build-Gaspi.ps1 -Target windows
.\Build-Gaspi.ps1 -Target android
.\Build-Gaspi.ps1 -Target all
```

El script ejecuta análisis y pruebas y después guarda `releases/Gaspi-Windows.zip` y/o `releases/Gaspi-Android.apk`. El ZIP de Windows debe distribuirse completo, con DLL y `data`. El APK usa firma de depuración para uso personal; no está preparado para Play Store.

## Uso

1. Pulsa `+` para añadir canciones; en Windows también puedes elegir una carpeta completa.
2. Usa Canciones, Álbumes o Artistas para explorar; busca por título, artista, álbum o formato.
3. Usa el menú de una canción para marcarla como favorita o añadirla a una playlist.
4. Pulsa la canción en el mini reproductor, o el icono de expandir en PC, para abrir la vista inmersiva. Vuelve con la flecha superior o `Esc` en PC.
5. En Letra, carga un `.lrc` o `.txt`. También se leen letras embebidas; en Windows se detecta el `.lrc` junto al audio al importar. Las líneas sincronizadas se resaltan y puedes pulsarlas para saltar a ese momento.
6. El botón de sol/luna cambia el tema y guarda la elección.

## Formatos y almacenamiento

El selector admite MP3, FLAC, WAV, OGG, OPUS, M4A, AAC, AIF, AIFF, APE, WMA, ALAC y WV. El motor nativo es media_kit/libmpv; la compatibilidad efectiva depende del códec, contenedor y estado del archivo. No se garantiza decodificar todos los formatos posibles.

**Windows:** reproduce los originales por su ruta. Si los mueves o eliminas, vuelve a importarlos.

**Android:** copia los archivos seleccionados al almacenamiento privado de Gaspi para conservarlos después de cerrar el selector, con SHA-256 para evitar duplicados. Ocupa espacio adicional; al desinstalar se borran esas copias. No elimina los originales. Quitar una canción de la biblioteca solo elimina su registro: esta versión conserva las copias y carátulas internas.

La biblioteca, playlists, favoritos, tema, carátulas y letras importadas se guardan en el directorio de soporte de Gaspi del sistema, con copia de seguridad del índice. No se suben archivos. No hay descargas de internet porque la biblioteca ya es local.

## Verificación y límites

Consulta `VERIFICACION.md` para los resultados ejecutados. Las imágenes de `previews/` son capturas reales del código de interfaz, renderizadas con datos de prueba y un reproductor simulado: no demuestran decodificación de audio ni incluyen canciones reales.

**No se generaron EXE/APK finales:** el entorno restringido impide a Dart abrir los canales de sus procesos hijos (`CreateFile failed 5 / Acceso denegado`). Las compilaciones se detuvieron antes de ejecutar Visual Studio/Java. El script permite continuar en una terminal normal y comprobar posibles problemas adicionales.

Esta primera versión no incluye servicio Android para reproducción en segundo plano, controles de bloqueo/notificación, ecualizador, sincronización entre dispositivos, editor de etiquetas o desplazamiento automático de letras. No se verificó la reproducción real, selectores nativos, instalación ni cambio de pantalla completa en Windows.

## REA

Se ejecutó REA sobre el instalador que aportaste y sobre los recursos públicos de tu instalación de Spotify. El inventario funcionó; la interpretación de JavaScript quedó parcial por un error de permisos. El informe y sus límites están en `analysis/REA-SPOTIFY.md`. Gaspi utiliza código y logo propios; no incorpora los recursos extraídos de Spotify.

## Código

`lib/app.dart`: interfaz y reproductor inmersivo. `library.dart`: importación, reproducción y persistencia. `models.dart`: canciones y LRC. `metadata.dart`: etiquetas y carátulas. `ghost.dart`: logo vectorial animado. `tool/render_preview.dart`: render de comprobación con datos ficticios; no es la entrada de la app.

Dependencias: https://pub.dev/packages/media_kit · https://pub.dev/packages/audio_metadata_reader · https://pub.dev/packages/file_picker/versions/10.3.10 · https://pub.dev/packages/window_manager

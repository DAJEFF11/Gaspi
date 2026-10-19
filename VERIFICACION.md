# Verificación de Gaspi 0.1.0

19 de octubre de 2026. Flutter 3.44.3, Dart 3.12.2.

## Compilación y distribución nativa

[GitHub Actions · ejecución exitosa](https://github.com/DAJEFF11/Gaspi/actions/runs/39312328052) sobre el commit `690dfbdf4cc5fe2e8b6751877a62c06e60836ba9`.

- Windows Server 2022: `flutter analyze` sin problemas, suite Flutter con tres pruebas aprobadas, seis comprobaciones directas, compilación release de `gaspi.exe`, empaquetado de DLL de Visual C++, ZIP portátil e instalador Inno Setup. Resultado: **éxito**.
- Ubuntu 24.04/JDK 17: `flutter analyze`, suite Flutter y `flutter build apk --release`. Resultado: **éxito**.
- Publicación de EXE, APK, ZIP y `SHA256SUMS.txt` en [Release v0.1.0](https://github.com/DAJEFF11/Gaspi/releases/tag/v0.1.0). Los cuatro activos están subidos y la versión es pública, marcada como vista previa.

El primer intento de empaquetado de Windows encontró una disposición diferente de carpetas en Visual Studio. Se corrigió buscando el runtime x64 dentro de la instalación. La compilación corregida finalizó correctamente. No se omiten las DLL necesarias para entregar un EXE aislado.

## Código e interfaz

- Dependencias resueltas y bloqueadas en `pubspec.lock`.
- Análisis completo mediante el servidor oficial de análisis Dart en local, sin diagnósticos.
- Compilación kernel de la interfaz y del arnés de render: cero errores.
- Seis casos directos aprobados: tiempos LRC repetidos/fracciones/offset y orden; extracción de texto LRC; letras sin tiempos; tiempos negativos; persistencia de canciones; alternativa ante metadatos dañados con LRC lateral.
- Render real con `flutter_tester`: **nueve capturas, cero errores de Flutter/layout**. Móvil claro/oscuro (390×844), PC claro/oscuro (1440×900), reproductor PC (1440×900), reproductor móvil (390×844), biblioteca móvil compacta (320×640), PC compacto (1024×640) y reproductor móvil compacto (320×640).
- Se revisaron visualmente las capturas principales y se corrigieron las superficies Material de las listas y los controles en móvil compacto.
- Logo propio PNG/GIF/SVG e iconos nativos Windows/Android incluidos.
- REA ejecutado sobre el instalador y recursos públicos de la instalación de Spotify: inventario parcial, interpretación semántica interrumpida por permisos. [Informe](analysis/REA-SPOTIFY.md).

Las capturas usan un reproductor simulado y canciones ficticias sin archivos de audio; esos datos no forman parte de la app normal. El fantasma es la carátula alternativa cuando un archivo no tiene imagen embebida.

## Límites de estas comprobaciones

La compilación y las pruebas automatizadas **no verifican** reproducción real de cada códec, selectores del sistema, instalación, batería, recuperación del índice ni cambio nativo de pantalla completa en un dispositivo real. La pantalla inmersiva sí se renderizó. La app se distribuye como primera vista previa.

El entorno local restringido no podía crear los canales de procesos hijos de Dart y fallaba antes de lanzar Visual Studio/Java. Los binarios finales se generaron en GitHub Actions, donde las compilaciones sí concluyeron.


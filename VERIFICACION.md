# Verificación de Gaspi

19 de octubre de 2026. Flutter 3.44.3, Dart 3.12.2, Windows x64.

## Ejecutado correctamente

- Resolución y descarga de dependencias con Dart Pub; `pubspec.lock` incluido.
- Análisis completo mediante el protocolo del servidor oficial de análisis Dart: finalizado, sin diagnósticos en `lib/`, `test/` ni `tool/`.
- Compilación kernel del código de interfaz y su arnés de render mediante `frontend_server_aot`: resultado de compilación 0 errores.
- Seis casos directos de lógica: tiempos LRC repetidos y ordenados con fracciones/offset; extracción de texto LRC; letras sin tiempos; tiempos negativos; persistencia de canción con metadatos y letra; metadatos dañados con alternativa al nombre de archivo y LRC lateral.
- Render real con `flutter_tester`: **nueve capturas, cero errores de Flutter/layout**. Biblioteca móvil clara/oscura (390×844), biblioteca PC clara/oscura (1440×900), reproductor inmersivo PC (1440×900), reproductor móvil (390×844), biblioteca móvil compacta (320×640), biblioteca PC compacta (1024×640), reproductor móvil compacto (320×640).
- Se revisaron visualmente las capturas principales. Se corrigieron las superficies Material de las listas y la adaptación de controles al móvil compacto.
- Logo vectorial integrado y archivos PNG/GIF/SVG generados; iconos Windows y Android reemplazados.
- REA ejecutado sobre el instalador y recursos de interfaz instalados; resultados y límites en `analysis/REA-SPOTIFY.md`.

Las capturas usan un reproductor simulado y canciones ficticias sin archivos de audio. La carátula del fantasma es la alternativa que muestra la app cuando un archivo no tiene imagen embebida. No se inyectan esos datos en la app normal.

## No verificado / pendiente

- Las compilaciones nativas de Windows y APK se intentaron y fallaron por acceso denegado al crear los canales para procesos hijos de Dart, antes de ejecutar Visual Studio o Java. No se produjo EXE ni APK final.
- No se ejecutó la suite mediante el comando `flutter test`; se ejecutaron directamente los seis casos descritos y el render de interfaz. El script de compilación sí incluye `flutter test` para el entorno normal.
- No se probó audio real, códecs en los dispositivos, acceso con el selector del sistema, recuperación del índice en condiciones reales, instalación ni cambio nativo de pantalla completa. La pantalla inmersiva sí se renderizó.
- REA obtuvo inventario estático parcial del paquete de interfaz; el análisis semántico de JavaScript se interrumpió con EPERM. No se afirma una reconstrucción completa de Spotify.

## Continuar la compilación

Abre PowerShell en esta carpeta y ejecuta:

```powershell
.\Build-Gaspi.ps1 -Target all
```

El script se detiene en cualquier fallo de análisis, pruebas o compilación. Las salidas exitosas van a `releases/`. Su ejecución podría revelar requisitos o problemas adicionales que no llegaron a comprobarse aquí.

# REA: Spotify como referencia para Gaspi

Análisis estático local, 19 de octubre de 2026. No se ejecutó el instalador ni se modificó Spotify. No se leyeron `Users`, preferencias, sesiones, cachés musicales o credenciales.

## Evidencia observada

- `SpotifySetup.exe`: 1.075.688 bytes, SHA-256 `7835735e412d3acb375edd1bd2ac7ef16bc76338ae02a187161b20db99531f21`.
- REA 6.7.0 `inspect-artifact`: contenedor PE, un único artefacto, sin entradas hijas recuperadas por ese flujo.
- REA `inspect-managed-artifact`: PE32+, x86_64, siete secciones, sin directorio CLI/.NET. Este resultado no recupera funciones ni interfaz.
- Instalación encontrada en `%APPDATA%/Spotify`. Se revisó únicamente su carpeta pública de recursos `Apps`.
- `Apps/xpui.spa` es un ZIP. Incluye recursos con nombres `xpui-routes-collection-local-files`, `xpui-routes-playlist`, `xpui-routes-lyrics`, `xpui-routes-search`, `xpui-routes-album`, `xpui-routes-artist` y `xpui-routes-your-library-x`.

## Derivación y límites

REA rechazó el ZIP directamente porque incluye una entrada de directorio raíz `/`. Se conservó el original y se generó una copia extraída bajo `work/spotify-xpui`, verificando que cada ruta permaneciera dentro del destino. Solo se omitió ese marcador vacío de raíz; no se ejecutó JavaScript. El manifiesto local de extracción conserva hashes del archivo y de cada miembro.

Se ejecutó `analyze-javascript-application` seleccionando `index.html` y los recursos de archivos locales, playlists, letras y búsqueda. REA devolvió un inventario parcial de 547 nodos. La interpretación semántica de JavaScript se interrumpió al transferir un archivo temporal con `EPERM`. Un segundo intento con temporales en el workspace encontró el mismo bloqueo. Hay 268 archivos inventariados fuera de la selección. **El resultado no acredita decompilación completa, funciones recuperadas, ejecución observada ni equivalencia con Spotify.**

Los nombres de los recursos sustentan una separación de pantallas para biblioteca, archivos locales, álbumes, artistas, playlists, letras y búsqueda. La organización de Gaspi usa esas funciones generales. Su aspecto visual se construyó siguiendo las dos imágenes proporcionadas por el usuario: biblioteca monocromática y vista inmersiva de reproducción. No se incorporó código, fuentes, imágenes, marcas o recursos de Spotify a Gaspi.

## Implementación en Gaspi

- Biblioteca local, agrupación por artista/álbum, búsqueda, favoritos y playlists.
- Mini reproductor y cola; pantalla completa con carátula a la izquierda y controles/letra a la derecha en PC.
- Blanco minimalista y negro mate profundo, con preferencia guardada.
- Fantasmita vectorial propio con flotación y parpadeo, respetando movimiento reducido.

Los JSON adjuntos conservan los resultados completos y pequeños del instalador. La evidencia parcial extensa del paquete instalado y el manifiesto de extracción se conservaron en `work` y no se incluyen en la distribución del código.

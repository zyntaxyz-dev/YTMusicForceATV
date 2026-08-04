# ForceATV

Tweak Logos (Theos) para YouTube Music: fuerza la preferencia de la variante **ATV (Art Track)** sobre **OMV/Visualizer** cuando existe el par.

- Target: `com.google.ios.youtubemusic`
- Build: solo genera el **dylib** (`.deb` + `.dylib` + `.plist`). La inyección a la IPA se hace manualmente.

## Toggle

El tweak se activa/desactiva con el switch **"Preferir Art Track (ATV)"** en **Ajustes → YouTube Music** (pane inyectado vía `Settings.bundle`). La clave BOOL **`preferATV`** se guarda directamente en el NSUserDefaults del app, default **OFF**.

Con `preferATV = NO` (o ausente), los hooks devuelven `%orig` (comportamiento original intacto).

> Nota: tweak independiente. YTMusicUltimate se usó solamente como referencia de patrón, no como dependencia.

## Qué hooks

| Clase | Método | Efecto con `preferATV=YES` |
|---|---|---|
| `YTDefaultQueueConfig` | `forceATVPreferredWhenPlayAudioOnly` | `YES` (config global) |
| `YTMQueueConfigImpl` | `forceATVPreferredWhenPlayAudioOnly` | `YES` (config impl) |
| `YTQueueController` | `initialUserContentModeATVPreferred` | `YES` (modo inicial ATV) |

## Build

En GitHub Actions (fork): `workflow_dispatch` → genera `ForceATV.deb`, `ForceATV.dylib`, `ForceATV.plist` en la Release/Artifacts. **No se sube IPA a GitHub.**

Local (Theos):

```
make clean package DEBUG=0 FINALPACKAGE=1
```

## Inyección manual (fuera de GitHub)

1. Descifra tu IPA de YouTube Music 9.29.3.
2. Inyecta el dylib en el bundle y firma con tu cert de 7 días (ej. `insert_dylib` + `zsign` / `codesign`):
   - Copia `ForceATV.dylib` a `Payload/YouTubeMusic.app/`
   - Copia `ForceATV.plist` como `Payload/YouTubeMusic.app/ForceATV.plist`
   - Inserta el load command `LC_LOAD_DYLIB` apuntando a `@executable_path/ForceATV.dylib`.
3. Copia la carpeta **`Settings.bundle/`** a `Payload/YouTubeMusic.app/Settings.bundle` (para que el toggle aparezca en Ajustes → YouTube Music).
4. Re-firma el `.app` con tu certificado.
5. Instala, activa "Preferir Art Track (ATV)" en Ajustes y reproduce.

## Referencia de análisis

El mecanismo ATV/OMV (videoId distinto, `hasATVOMVPair`, `updateUserContentModeForVideoAtIndex:forceATVPreferred:`, etc.) está documentado en `YTAnalysis/ANALISIS.md` del workspace.

# ForceATV

Tweak Logos (Theos) para YouTube Music: fuerza la preferencia de la variante **ATV (Art Track)** sobre **OMV/Visualizer** cuando existe el par.

- Target: `com.google.ios.youtubemusic`
- Build: solo genera el **dylib** (`.deb` + `.dylib` + `.plist`). La inyección a la IPA se hace manualmente.

## Toggle

El tweak se activa/desactiva por usuario con la clave BOOL `preferATV` dentro del NSUserDefaults **`YTMUltimate`** (mismo diccionario que YTMusicUltimate), default **OFF**.

Formas de activarlo:
- Desde un plist en el dispositivo (ej. por Preferences, app de ajustes del tweak, o `defaults write`).
- O dejando la clave `preferATV = YES` en el diccionario `YTMUltimate`.

Sin la clave (o `NO`), los hooks devuelven `%orig` (comportamiento original intacto).

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
2. Inyecta el dylib en el bundle y firma con tu cert de 7 días (ej. `cyan`, `zsign`, `ldid` + `codesign`):
   - Copia `ForceATV.dylib` a `Payload/YouTubeMusic.app/`
   - Copia `ForceATV.plist` como `Payload/YouTubeMusic.app/ForceATV.plist`
   - Añade load command / `LC_LOAD_DYLIB` o usa la inyección del tool elegido.
3. Instala, activa `preferATV=YES` y reproduce.

## Referencia de análisis

El mecanismo ATV/OMV (videoId distinto, `hasATVOMVPair`, `updateUserContentModeForVideoAtIndex:forceATVPreferred:`, etc.) está documentado en `YTAnalysis/ANALISIS.md` del workspace.

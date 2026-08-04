# ForceATV

Tweak Logos (Theos) para YouTube Music 9.29.3 que fuerza la variante **ATV (Art Track / audio puro)** sobre **OMV (Official Music Video)** cuando existe el par.

- Target: `com.google.ios.youtubemusic`
- Entrega: solo el **dylib crudo** `ForceATV.dylib`. Inyección manual con esign.

## Qué hace

Compara y registra qué videoId se usa en cada content mode (0=OMV, 1=ATV) durante la reproducción, para diagnosticar el flujo de selección de videoId.

## Build

En GitHub Actions (fork): `workflow_dispatch` → genera `ForceATV.dylib` (firma limpia, sin entitlements). **No se sube IPA a GitHub.**

Local (Theos):

```
make clean package DEBUG=0 FINALPACKAGE=1
```

El `.dylib` compilado está en `obj/Debug/iphone/ForceATV.dylib`. Se recomienda quitarle la firma antes de inyectar (`ldid -r`).

## Inyección manual (fuera de GitHub)

1. Descifra tu IPA de YouTube Music 9.29.3.
2. Copia `ForceATV.dylib` a `Payload/YouTubeMusic.app/`.
3. Asegúrate de que el binary principal tiene el load command `LC_LOAD_DYLIB` apuntando a `@executable_path/ForceATV.dylib` (esign lo añade automáticamente al inyectar).
4. Re-firma el `.app` con tu certificado (esign, zsign, etc.).
5. Instala, abre YTM y reproduce un álbum con par ATV/OMV (ej. `MPREb_NNmY1n1NJFS` → ATV: `NBghhjuMNKM`, OMV: `p38WgakuYDo`).

## Diagnóstico

Si el tweak no hace nada, conecta el iPhone al PC y revisa:

```
Apps/com.google.ios.youtubemusic/Documents/ForceATV.log
```

- **Archivo no existe** → el dylib no se cargó (problema de firma/carga).
- **Archivo existe** → el dylib se cargó; los hooks se dispararon.

## Referencia de análisis

El mecanismo ATV/OMV (videoId distinto, `hasATVOMVPair`, `updateUserContentModeForVideoAtIndex:forceATVPreferred:`, etc.) está documentado en `YTAnalysis/ANALISIS.md` del workspace.
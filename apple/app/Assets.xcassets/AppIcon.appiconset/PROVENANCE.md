# BananaPad app-icon provenance

Created: 2026-09-01

## Ownership and process

This is original BananaPad project artwork generated with OpenAI's built-in image-generation tool from a BananaPad-specific design brief. No DK64 screenshots, ROM assets, Nintendo/Rare logos, Kong characters, bananas/coins from the game, controller product photographs, third-party project icons, or other third-party artwork were supplied as source images or used in the generation.

The generated source master is `design/app-icon-source/BananaPad-AppIcon-generated-master-v1.png`, 1254×1254 opaque RGB PNG, SHA-256 `9ef7f7fa2a0e2da390bd67192a9c8e7e94979346e38202f4b76a24bf424bf4d8`. The Xcode asset is a deterministic 1024×1024 opaque resize produced with macOS `sips`, SHA-256 `e8c1213d036e12f1acd6b388c537ddb72d9dded5a3e7bb52f53731e63410a882`.

The previous generic paper/controller image is retained for audit history at `design/app-icon-source/legacy-paper-controller-icon.png`; it is no longer referenced by the asset catalog or packaged app.

## Design brief and generation prompt

```text
Use case: logo-brand
Asset type: original 1024x1024 iOS/iPadOS/macOS app icon master for BananaPad
Primary request: create a polished, original app icon whose central mark is one simple curved yellow banana integrated with a neutral modern game-controller pad motif
Scene/backdrop: solid deep indigo-to-teal subtle gradient background, fully opaque, with generous breathing room for Apple icon masks
Subject: a single generic banana curve forming the upper arc of an abstract controller pad; two small neutral circular input dots and one understated cross-direction element; unmistakably original and generic
Style/medium: crisp vector-friendly geometric illustration, premium native Apple app aesthetic, flat shapes with restrained soft depth, readable at very small size
Composition/framing: centered, symmetric visual weight, important artwork inside the central 72 percent safe zone, square canvas, no baked rounded corners
Color palette: warm banana yellow, deep navy/indigo, restrained teal highlight, high contrast
Constraints: no text, no letters, no logos, no watermark, no characters, no game screenshots, no coins, no Nintendo/Rare imagery, no recognizable Nintendo controller silhouette, no existing project icon, opaque edge-to-edge square background, no transparent pixels, no baked rounded-corner mask
Avoid: photorealistic banana, paper/document imagery, confetti, brand marks, detailed controller hardware, trademarked visual language
```

## Acceptance notes

- The square master has no alpha channel and no baked system corner mask.
- The high-contrast centered mark leaves edge space for Apple masks.
- Xcode owns platform-specific icon rendition and package generation.
- Physical Home Screen, app-switcher, Settings/search, and appearance-mode presentation remain part of the G12 device checklist.

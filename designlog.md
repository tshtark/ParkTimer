# ParkTimer Icon Design Log

Working doc for iterating the ParkTimer app icon in Apple Icon Composer. Seeded with hard-won learnings from RoundTimer's icon design (4 iterations, shipped April 2026).

## Critical Icon Composer Learnings (from RoundTimer V1)

These are the rules that actually worked after rejecting several iterations. Start here, don't relearn them.

### Liquid Glass behavior
1. **Liquid Glass works best with simple, bold, flat shapes** — the system handles the depth; your artwork should be confident and minimal.
2. **Don't bake effects into artwork** — no pre-rendered shadows, gradients, or highlights. Let Icon Composer add specular/shadow/blur per group.
3. **Static export shows specular as crossing grid lines** — this looks terrible. On real device the specular moves with the gyroscope and feels natural. Don't judge only by static export — test on device.
4. **Simpler is dramatically better with Liquid Glass** — two layers with one focal element each, not five layered pieces.

### Per-group effect tuning (THE big lesson)
5. **Turn Specular OFF on thin/arc elements** — creates crossing line artifacts that look like scratches in static exports.
6. **Turn Translucency OFF on solid brand elements** — your brand mark should be confident, opaque, not ghostly.
7. **Turn Specular/Translucency ON for the center glyph** — frosted-glass depth on the foreground element reads as premium.
8. **Chromatic shadow on the foreground** adds subtle color cohesion without being loud.

### Layout
9. **Keep content ≥100px from canvas edges** — iOS squircle corner mask will clip anything closer. On a 1024 canvas, that's a 16% safe margin.
10. **Thicker is better** — 85px ring at 350px radius reads much stronger than 62px at small icon sizes (29pt home screen). Don't be timid with stroke weight.
11. **Separate depth groups for ring and center element** — creates real glass parallax. Combined layers look flat.
12. **Background color set in Icon Composer, not as an imported layer** — use `fill.solid: "srgb:..."` in `icon.json`.

### Asset preparation
13. **SVG preferred for vector crispness; PNG with transparency for raster** — export layers from Figma/Illustrator.
14. **No alpha channel on the final App Store icon** — the asset catalog handles this, but verify with `sips -g hasAlpha`.
15. **Colored backgrounds outperform pure black/white** — deep tints feel more premium than flat grays.

## Design Principles for Premium Icons

- **ONE strong element, not competing elements** — think Nike swoosh, Strava S-path, iconic simplicity
- **At 29pt (home screen), must be instantly recognizable** — squint test: does it still read?
- **The glass effect adds the premium feel; artwork should be bold/flat**
- **Dark backgrounds work** but consider deep colored tints that match brand
- **Avoid concepts that look like navigation or loading UI** — chevrons read as "navigation arrow", ring-only reads as "loading spinner"

## Reference: RoundTimer icon.json structure

From `RoundTimer/RoundTimerIcon.icon/icon.json` — use as a template:

```json
{
  "fill": {
    "solid": "srgb:0.05098,0.10196,0.05882,1.00000"
  },
  "groups": [
    {
      "layers": [{ "image-name": "play_layer_v3.png", "name": "play_layer_v3" }],
      "shadow": { "kind": "layer-color", "opacity": 0.5 },
      "translucency": { "enabled": true, "value": 0.5 }
    },
    {
      "layers": [{ "glass": false, "image-name": "ring_thick_layer.png", "name": "ring_thick_layer" }],
      "shadow": { "kind": "neutral", "opacity": 0.5 },
      "specular": false,
      "translucency": { "enabled": false, "value": 0.5 }
    }
  ],
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared"
  }
}
```

Shadow kinds: `layer-color` (tinted by layer), `neutral` (grey), `chromatic` (colorful rim).

## ParkTimer Iteration Log

_(To be filled in as we iterate.)_

### Iteration 0 — Placeholder
- Current state: flat `icon_1024.png` (1024×1024, RGB, no alpha) in `Assets.xcassets/AppIcon.appiconset/`
- No Icon Composer `.icon` bundle yet
- No Liquid Glass depth
- **Verdict:** Shipping placeholder only. Needs full redesign before App Store submission.

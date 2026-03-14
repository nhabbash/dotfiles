// Clean CRT — all effects tunable, preserves theme colors
// Border matches terminal background automatically
//
// === TUNE THESE (all 0.0 to 1.0) ===
//
#define CURVATURE       0.48   // barrel distortion: 0 = flat, 0.5 = moderate, 1 = heavy
#define SCAN_INTENSITY  0.55   // scanline darkness: 0 = off, 0.3 = subtle, 0.7 = heavy
#define SCAN_DENSITY    0.4   // scanline spacing: 0 = thick/sparse, 0.5 = balanced, 1 = fine/dense
#define CHROMA_SHIFT    0.25   // RGB color split: 0 = off, 0.1 = subtle, 0.5 = heavy
#define BLOOM           0.58   // glow bleed on bright pixels: 0 = off, 0.3 = soft, 0.7 = dreamy
#define DOT_MATRIX      0.38   // RGB subpixel pattern: 0 = off, 0.2 = subtle, 0.6 = visible
#define VIGNETTE        0.10   // edge darkening: 0 = off, 0.2 = subtle, 0.6 = heavy
#define BRIGHTNESS      0.35   // creative boost only: 0 = dimmer, 0.5 = original, 1 = brighter
                               // (scanline/dot darkening is auto-compensated)
//
// ==================

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Map parameters to internal ranges ---
    float curvature    = CURVATURE * CURVATURE * 0.08;         // quadratic: gentle at low, ramps at high
    float scanStr      = SCAN_INTENSITY * 0.7;                 // linear: 0→0, 1→0.7
    float scanFreq     = iResolution.y * mix(0.25, 1.0, SCAN_DENSITY); // 0.25→1.0 lines per px
    float chromaOff    = CHROMA_SHIFT * CHROMA_SHIFT * 0.005;  // quadratic: subtle at low end
    float bloomStr     = BLOOM * 0.5;                          // linear: 0→0.5
    float bloomRad     = mix(1.0, 4.0, BLOOM);                 // spread grows with amount
    float dotStr       = DOT_MATRIX * 0.5;                     // linear: 0→0.5
    float vigPow       = mix(0.001, 0.35, VIGNETTE * VIGNETTE); // quadratic: subtle ramp
    float bright       = mix(0.85, 1.35, BRIGHTNESS);          // 0→0.85 (dimmer), 0.5→1.1, 1→1.35

    // --- Curvature ---
    vec2 curved = uv * 2.0 - 1.0;
    curved *= 1.0 + dot(curved, curved) * curvature;
    vec2 cuv = curved * 0.5 + 0.5;

    // Outside curved edges: match terminal background
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(texture(iChannel0, vec2(0.0)).rgb, 1.0);
        return;
    }

    // --- Chromatic Aberration ---
    vec3 color;
    if (chromaOff > 0.0) {
        color = vec3(
            texture(iChannel0, cuv + vec2( chromaOff, 0.0)).r,
            texture(iChannel0, cuv).g,
            texture(iChannel0, cuv + vec2(-chromaOff, 0.0)).b
        );
    } else {
        color = texture(iChannel0, cuv).rgb;
    }

    // --- Bloom ---
    if (bloomStr > 0.0) {
        vec3 bloom = vec3(0.0);
        float total = 0.0;
        for (float x = -2.0; x <= 2.0; x += 1.0) {
            for (float y = -2.0; y <= 2.0; y += 1.0) {
                float w = exp(-0.5 * (x*x + y*y) / (bloomRad * bloomRad));
                bloom += texture(iChannel0, cuv + vec2(x, y) / iResolution.xy * bloomRad).rgb * w;
                total += w;
            }
        }
        bloom /= total;
        color += max(bloom - color, vec3(0.0)) * bloomStr;
    }

    // --- Scanlines: soft sine profile within integer period ---
    // fragCoord.y = physical pixels (no curvature distortion)
    // integer period = no Moiré from frequency mismatch
    // smooth sin² profile = no hard-edge interference with text rendering
    float scanCompensation = 1.0;
    if (scanStr > 0.0) {
        float period = floor(mix(2.0, 8.0, 1.0 - SCAN_DENSITY));
        float phase = mod(fragCoord.y, period) / period; // 0..1 per period
        float scanline = 1.0 - scanStr * pow(sin(phase * 3.14159), 2.0);
        color *= scanline;
        scanCompensation = 1.0 / (1.0 - scanStr * 0.5); // sin² averages 0.5
    }

    // --- Dot Matrix (with auto brightness compensation) ---
    // Average of sin dot pattern with intensity d = 1 - d*0.25, compensate similarly
    float dotCompensation = 1.0;
    if (dotStr > 0.0) {
        vec2 dotPos = fragCoord;
        float dot = 1.0 - dotStr * (
            0.5 + 0.5 * sin(dotPos.x * 3.14159) * sin(dotPos.y * 3.14159)
        );
        color *= dot;
        dotCompensation = 1.0 / (1.0 - dotStr * 0.25);
    }

    // --- Vignette ---
    if (vigPow > 0.0) {
        vec2 vig = cuv * (1.0 - cuv);
        color *= clamp(pow(vig.x * vig.y * 15.0, vigPow), 0.0, 1.0);
    }

    // --- Brightness: auto-compensate scan/dot darkening, then apply creative boost ---
    color *= scanCompensation * dotCompensation * bright;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

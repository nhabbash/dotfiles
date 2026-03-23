// crt-lab — generated
// Preset: Studio Clean
#define ROWS           63
#define COLS           123
#define CURVATURE       0.5292
#define SCAN_INTENSITY  0.0800
#define SCAN_DENSITY    0.5000
#define SCAN_SPEED      0.0000
#define SCAN_THICKNESS  0.3800
#define PHOSPHOR_DECAY  0.0000
#define FLICKER_AMP     0.0000
#define CHROMA_SHIFT    0.2000
#define CONVERGENCE     0.1732
#define BLOOM           0.0800
#define BLOOM_RADIUS    0.1000
#define HALATION        0.0400
#define H_SOFTNESS      0.2449
#define VERTICAL_BLEED  0.1732
#define DOT_MATRIX      0.0000
#define EDGE_SOFTNESS   0.2236
#define VIGNETTE        0.0800
#define BRIGHTNESS      0.9400
#define GRAIN_AMP       0.0000
#define JITTER          0.0000
#define PI             3.14159265359



vec3 applyMask(vec2 fragCoord, vec3 color, float amount) {
    if (amount <= 0.0) return color;

    vec3 mask = vec3(1.0);
#ifdef MASK_SHADOW
    float x = mod(fragCoord.x + fragCoord.y * 3.0, 3.0);
    if (x < 1.0) mask = vec3(1.0, 0.80, 0.80);
    else if (x < 2.0) mask = vec3(0.80, 1.0, 0.80);
    else mask = vec3(0.80, 0.80, 1.0);
#endif
#ifdef MASK_GRILLE
    float gx = mod(fragCoord.x, 3.0);
    if (gx < 1.0) mask = vec3(1.0, 0.74, 0.74);
    else if (gx < 2.0) mask = vec3(0.74, 1.0, 0.74);
    else mask = vec3(0.74, 0.74, 1.0);
#endif
#ifdef MASK_SLOT
    float sx = mod(fragCoord.x, 4.0);
    float sy = mod(fragCoord.y, 2.0);
    if (sx < 1.333) mask = vec3(1.0, 0.82, 0.82);
    else if (sx < 2.666) mask = vec3(0.82, 1.0, 0.82);
    else mask = vec3(0.82, 0.82, 1.0);
    mask *= mix(0.88, 1.0, step(1.0, sy));
#endif
    return mix(color, color * mask, amount);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    float curvature      = CURVATURE * CURVATURE * 0.08;
    float scanStr        = SCAN_INTENSITY * 0.7;
    float scanPower      = mix(0.65, 2.4, SCAN_THICKNESS);
    float scrollRate     = sqrt(SCAN_SPEED) * 120.0;
    float phosphorDecay  = sqrt(PHOSPHOR_DECAY) * 8.0;
    float flickAmp       = FLICKER_AMP * 0.12;
    float chromaOff      = CHROMA_SHIFT * CHROMA_SHIFT * 0.005;
    float convergence    = CONVERGENCE * CONVERGENCE * 0.004;
    float bloomStr       = BLOOM;
    float bloomRad       = mix(4.0, 24.0, BLOOM_RADIUS);
    float halationStr    = HALATION * 0.35;
    float hSoftness      = H_SOFTNESS;
    float verticalBleed  = VERTICAL_BLEED;
    float dotStr         = DOT_MATRIX * 0.5;
    float edgeSoft       = EDGE_SOFTNESS;
    float vigPow         = mix(0.001, 0.35, VIGNETTE * VIGNETTE);
    float bright         = mix(0.85, 1.35, BRIGHTNESS);
    float grainAmp       = GRAIN_AMP * 0.10;
    float jitterAmp      = JITTER * JITTER * 1.6;

    vec2 curved = uv * 2.0 - 1.0;
    curved *= 1.0 + dot(curved, curved) * curvature;
    vec2 cuv = curved * 0.5 + 0.5;

    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(texture(iChannel0, vec2(0.0)).rgb, 1.0);
        return;
    }

    vec2 texel = 1.0 / iResolution.xy;
    float centerDist = clamp(length(curved) * 0.85, 0.0, 1.0);
    float rowJitter = sin(iTime * 8.0 + fragCoord.y * 0.03) * jitterAmp * texel.x;
    cuv.x += rowJitter;
    vec2 snapped = (floor(cuv / texel) + 0.5) * texel;
    float sampleSnap = clamp(curvature * 3.0, 0.0, 0.35);
    vec2 sampleUv = mix(cuv, snapped, sampleSnap);

    float conv = convergence * (0.15 + centerDist * centerDist);
    vec2 convShift = vec2(chromaOff + conv, 0.0);

    vec3 baseColor = vec3(
        texture(iChannel0, sampleUv + convShift).r,
        texture(iChannel0, sampleUv).g,
        texture(iChannel0, sampleUv - convShift).b
    );

    float softMix = clamp(hSoftness * 0.75 + edgeSoft * centerDist, 0.0, 0.85);
    if (softMix > 0.0) {
        vec2 hOff = vec2(texel.x * mix(0.8, 3.5, hSoftness + edgeSoft * centerDist), 0.0);
        vec3 hBlur = (
            texture(iChannel0, sampleUv - hOff).rgb * 0.25 +
            baseColor * 0.50 +
            texture(iChannel0, sampleUv + hOff).rgb * 0.25
        );
        baseColor = mix(baseColor, hBlur, softMix);
    }

    float vMix = clamp(verticalBleed * 0.75 + edgeSoft * centerDist * 0.5, 0.0, 0.75);
    if (vMix > 0.0) {
        vec2 vOff = vec2(0.0, texel.y * mix(0.8, 3.0, verticalBleed + edgeSoft * centerDist));
        vec3 vBlur = (
            texture(iChannel0, sampleUv - vOff).rgb * 0.20 +
            baseColor * 0.60 +
            texture(iChannel0, sampleUv + vOff).rgb * 0.20
        );
        baseColor = mix(baseColor, vBlur, vMix);
    }

    vec3 color = baseColor;

    if (bloomStr > 0.0) {
        vec3 bloom = vec3(0.0);
        float total = 0.0;
        for (float x = -3.0; x <= 3.0; x += 1.0) {
            for (float y = -3.0; y <= 3.0; y += 1.0) {
                float w = exp(-0.5 * (x * x + y * y));
                bloom += texture(iChannel0, sampleUv + vec2(x, y) / iResolution.xy * (bloomRad / 3.0)).rgb * w;
                total += w;
            }
        }
        bloom /= total;
        color += max(bloom - color, vec3(0.0)) * bloomStr;
    }

    if (halationStr > 0.0) {
        vec3 halo = vec3(0.0);
        float hTotal = 0.0;
        for (float x = -2.0; x <= 2.0; x += 1.0) {
            for (float y = -2.0; y <= 2.0; y += 1.0) {
                float w = exp(-0.7 * (x * x + y * y));
                halo += texture(iChannel0, sampleUv + vec2(x, y) / iResolution.xy * 2.5).rgb * w;
                hTotal += w;
            }
        }
        halo /= hTotal;
        color += max(halo - color, vec3(0.0)) * halationStr;
    }

    float scanCompensation = 1.0;
    if (scanStr > 0.0) {
        float scrolledY  = fragCoord.y - iTime * scrollRate;
        float period     = floor(mix(2.0, 8.0, 1.0 - SCAN_DENSITY));
        float phase      = mod(scrolledY, period) / period;
        float sineScan   = pow(sin(phase * PI), scanPower);
        float decayNorm  = 1.0 / max(1.0 - exp(-phosphorDecay), 0.001);
        float decayScan  = exp(-phase * phosphorDecay) * (1.0 - exp(-phosphorDecay)) * decayNorm;
        float beam       = mix(sineScan, decayScan, PHOSPHOR_DECAY);
        float scanline   = 1.0 - scanStr * beam;
        color *= scanline;
        scanCompensation = 1.0 / max(1.0 - scanStr * 0.5, 0.001);
    }

    if (flickAmp > 0.0) {
        float slow = 0.5 + 0.5 * sin(iTime * 2.0 * PI * 12.0);
        float fast = 0.5 + 0.5 * sin(iTime * 2.0 * PI * 50.0);
        float flicker = mix(slow, fast, 0.35);
        color *= 1.0 - flickAmp * flicker;
    }

    float dotCompensation = 1.0;
    if (dotStr > 0.0) {
        float lineHeight = iResolution.y / float(ROWS);
        float charWidth  = iResolution.x / float(COLS);
        float dx = sin(fragCoord.x * PI / charWidth);
        float dy = sin(fragCoord.y * PI / lineHeight);
        float dotPattern = 1.0 - dotStr * (0.5 + 0.5 * dx * dy);
        color *= dotPattern;
        dotCompensation = 1.0 / max(1.0 - dotStr * 0.25, 0.001);
    }

    color = applyMask(fragCoord, color, dotStr);

    if (vigPow > 0.0) {
        vec2 vig = cuv * (1.0 - cuv);
        color *= clamp(pow(vig.x * vig.y * 15.0, vigPow), 0.0, 1.0);
    }

    if (grainAmp > 0.0) {
        float gr = fract(sin(dot(fragCoord.xy + iTime * 743.0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
        color += gr * grainAmp;
    }

#ifdef PHOSPHOR_GREEN
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = luma * vec3(0.20, 1.0, 0.28);
#endif
#ifdef PHOSPHOR_AMBER
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = luma * vec3(1.00, 0.78, 0.28);
#endif

    color *= scanCompensation * dotCompensation * bright;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

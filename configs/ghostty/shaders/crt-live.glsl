// crt-lab — generated 2026-03-18 15:16:06
// Preset: Clean
#define ROWS           24
#define COLS           80
#define CURVATURE      0.30
#define SCAN_INTENSITY 0.10
#define SCAN_DENSITY   0.50
#define SCAN_SPEED     0.00
#define PHOSPHOR_DECAY 0.00
#define FLICKER_AMP    0.48
#define CHROMA_SHIFT   0.00
#define BLOOM          0.10
#define BLOOM_RADIUS   0.10
#define DOT_MATRIX     0.00
#define VIGNETTE       0.05
#define BRIGHTNESS     0.45
#define GRAIN_AMP      0.00



void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    float curvature = CURVATURE * CURVATURE * 0.08;
    float scanStr   = SCAN_INTENSITY * 0.7;
    float chromaOff = CHROMA_SHIFT * CHROMA_SHIFT * 0.005;
    float bloomStr  = BLOOM;
    float bloomRad  = mix(4.0, 24.0, BLOOM_RADIUS);
    float dotStr    = DOT_MATRIX * 0.5;
    float vigPow    = mix(0.001, 0.35, VIGNETTE * VIGNETTE);
    float bright    = mix(0.85, 1.35, BRIGHTNESS);
    float grainAmp  = GRAIN_AMP * 0.04;
    float flickAmp  = FLICKER_AMP * 0.04;

    vec2 curved = uv * 2.0 - 1.0;
    curved *= 1.0 + dot(curved, curved) * curvature;
    vec2 cuv = curved * 0.5 + 0.5;
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(texture(iChannel0, vec2(0.0)).rgb, 1.0);
        return;
    }

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

    if (bloomStr > 0.0) {
        vec3 bloom = vec3(0.0);
        float total = 0.0;
        for (float x = -3.0; x <= 3.0; x += 1.0) {
            for (float y = -3.0; y <= 3.0; y += 1.0) {
                float w = exp(-0.5 * (x * x + y * y));
                bloom += texture(iChannel0, cuv + vec2(x, y) / iResolution.xy * (bloomRad / 3.0)).rgb * w;
                total += w;
            }
        }
        bloom /= total;
        color += max(bloom - color, vec3(0.0)) * bloomStr;
    }

    float scanCompensation = 1.0;
    if (scanStr > 0.0) {
        float scrollRate = sqrt(SCAN_SPEED) * 150.0;
        float scrolledY  = fragCoord.y - iTime * scrollRate;
        float period     = floor(mix(2.0, 8.0, 1.0 - SCAN_DENSITY));
        float phase      = mod(scrolledY, period) / period;  // 0..1 per scan period

        float sineScan = pow(sin(phase * PI), 2.0);

        float decayExp  = sqrt(PHOSPHOR_DECAY) * 8.0;
        float decayNorm = 1.0 / max(1.0 - exp(-decayExp), 0.001);  // stability guard
        float decayScan = exp(-phase * decayExp) * (1.0 - exp(-decayExp)) * decayNorm;

        float beamProfile = mix(sineScan, decayScan, PHOSPHOR_DECAY);
        float scanline    = 1.0 - scanStr * beamProfile;
        color *= scanline;
        scanCompensation  = 1.0 / max(1.0 - scanStr * 0.5, 0.001);
    }

    if (flickAmp > 0.0) {
        color *= 1.0 + flickAmp * sin(iTime * 2.0 * PI * 60.0);
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

    if (vigPow > 0.0) {
        vec2 vig = cuv * (1.0 - cuv);
        color *= clamp(pow(vig.x * vig.y * 15.0, vigPow), 0.0, 1.0);
    }

    if (grainAmp > 0.0) {
        float gr = fract(sin(dot(fragCoord.xy + iTime * 743.0,
                                 vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
        color += gr * grainAmp;
    }

#ifdef PHOSPHOR_GREEN
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = luma * vec3(0.20, 1.0, 0.28);
#endif

    color *= scanCompensation * dotCompensation * bright;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

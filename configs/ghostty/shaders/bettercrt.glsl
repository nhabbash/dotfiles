// Simple CRT effect — scanlines + slight curvature, no color tint
// Source: https://github.com/0xhckr/ghostty-shaders/blob/main/bettercrt.glsl
// Modified from: https://www.shadertoy.com/view/WsVSzV
// License: CC BY NC SA 3.0

float warp = 0.25; // curvature amount (0.0 = flat)
float scan = 0.50; // scanline darkness (0.0 = none, 1.0 = heavy)

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 dc = abs(0.5 - uv);
    dc *= dc;

    // warp the fragment coordinates
    uv.x -= 0.5; uv.x *= 1.0 + (dc.y * (0.3 * warp)); uv.x += 0.5;
    uv.y -= 0.5; uv.y *= 1.0 + (dc.x * (0.4 * warp)); uv.y += 0.5;

    // scanline intensity
    float apply = abs(sin(fragCoord.y) * 0.25 * scan);

    // sample and mix with scanlines
    vec3 color = texture(iChannel0, uv).rgb;
    fragColor = vec4(mix(color, vec3(0.0), apply), 1.0);
}

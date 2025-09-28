shader_type canvas_item;
render_mode unshaded, blend_mix;

// ---- Controls ----
uniform vec4  base_color = vec4(1, 1, 1, 1.0);
uniform float time = 0.0;

// INTENSE RAINBOW SETTINGS
uniform float iridescence_strength = 1.0;  // MAX intensity
uniform float rainbow_intensity = 2.0;     // Extra boost for rainbow effect
uniform float brightness_pulsate_strength = 0.2;  // Brightness pulsation amount (visual only)
uniform float pulsate_speed = 1.0;         // Speed of brightness pulsation
uniform float color_cycle_speed = 5.0;     // How fast colors cycle

uniform float radius = 0.45;
uniform float edge_softness = 0.08;
uniform float rim_glow = 0.8;             // Intense rim glow
uniform float rim_width = 0.2;            // Wider rim for more effect

// Intense rainbow controls
uniform float color_bands = 3.0;          // Smoother color transitions with fewer bands
uniform float saturation = 1.0;           // MAXIMUM saturation for vivid colors
uniform float flow_speed = 2.5;           // Much faster animated movement
uniform float center_pure_radius = 0.0;   // No pure center - rainbow everywhere!
uniform float center_pure_fade = 0.0;     // Instant transition
uniform float inner_rainbow_boost = 1.5;  // Extra rainbow intensity in center

// Psychedelic wave effects
uniform float wave_amplitude = 0.03;      // Slightly less distortion for smoother look
uniform float wave_frequency = 8.0;       // Fewer waves for smoother transitions
uniform float spiral_speed = 1.5;         // Slightly slower spiral for smoother flow

// Color smoothing
uniform float color_blend_smoothness = 0.7;  // How smooth the color transitions are
uniform float hue_variation = 0.4;           // How much hue varies across the bubble

// Light interaction
uniform vec2 light_dir = vec2(0.7, -0.5);
uniform float fresnel_power = 1.5;
uniform vec2 bubble_screen_pos = vec2(0.5, 0.5);
uniform vec2 global_light_pos = vec2(0.3, 0.3);

// ---- Helpers ----

float luminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

float softcircle(vec2 uv, vec2 c, float r, float soft) {
    float d = length(uv - c);
    return smoothstep(r, r - soft, d);
}

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0))*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 screen(vec3 a, vec3 b) {
    return 1.0 - (1.0 - a)*(1.0 - b);
}

// Simple noise function for organic distortion
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth noise for angular distortion
float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// INTENSE pulsating rainbow interference pattern
float intenseRainbowInterference(vec2 uv, vec2 center, float t) {
    vec2 toCenter = uv - center;

    // Add strong time-based distortion for psychedelic movement
    float time_distortion = sin(t * flow_speed) * wave_amplitude;
    float spiral = t * spiral_speed;
    float cs = cos(spiral);
    float sn = sin(spiral);
    vec2 rotated = vec2(
        toCenter.x * cs - toCenter.y * sn,
        toCenter.x * sn + toCenter.y * cs
    );
    toCenter = mix(toCenter, rotated, 0.5);
    toCenter += vec2(
        cos(t * flow_speed * 1.7) * time_distortion,
        sin(t * flow_speed * 1.3) * time_distortion
    );

    float dist = length(toCenter);
    float angle = atan(toCenter.y, toCenter.x);

    // Create MANY overlapping wave patterns for intense effect
    float wave1 = sin(dist * wave_frequency - t * flow_speed * 2.0 + angle * 3.0);
    float wave2 = sin(dist * wave_frequency * 0.7 + t * flow_speed * 3.0 + angle * 5.0);
    float wave3 = cos(dist * wave_frequency * 1.3 - t * flow_speed * 4.0 - angle * 2.0);
    float wave4 = sin(dist * wave_frequency * 0.5 + t * flow_speed * 2.5 + angle * 4.0);
    float wave5 = cos(angle * 6.0 + t * flow_speed * 3.5) * sin(dist * wave_frequency * 2.0);

    // Mix waves with high contrast
    float pattern = wave1 * 0.3 + wave2 * 0.25 + wave3 * 0.25 + wave4 * 0.15 + wave5 * 0.3;
    pattern = pattern * 0.5 + 0.5;

    // Add extra pulsation based on time
    pattern += sin(t * pulsate_speed * 2.0) * 0.2;

    return clamp(pattern, 0.0, 1.0);
}

// ---- Main ----
void fragment() {
    vec2 center = vec2(0.5);

    // No size pulsation - keep physics boundary consistent
    float brightness_pulse = sin(TIME * pulsate_speed) * brightness_pulsate_strength;

    // Keep radius constant (no size pulsation)
    float current_radius = radius;

    // Add subtle wave distortion to the bubble shape (visual only)
    vec2 distorted_uv = UV;
    float dist_from_center = length(UV - center);
    float wave_distort = sin(atan(UV.y - 0.5, UV.x - 0.5) * 8.0 + TIME * 3.0) * 0.01;
    distorted_uv += normalize(UV - center) * wave_distort;

    // Bubble alpha mask WITHOUT size pulsation
    float alpha = softcircle(distorted_uv, center, current_radius, edge_softness);

    if (alpha <= 0.001) {
        COLOR = vec4(0.0);
    } else {
        vec4 tex_color = texture(TEXTURE, UV);
        vec3 actual_color = tex_color.rgb * COLOR.rgb;

        vec2 toCenter = UV - center;
        float distFromCenter = length(toCenter);
        float normalizedDist = distFromCenter / current_radius;

        // Calculate INTENSE interference pattern
        float interference = intenseRainbowInterference(UV, center, TIME);

        // Extra interference layer for more complexity
        float interference2 = intenseRainbowInterference(UV * 1.5, center, TIME * 1.3);
        interference = mix(interference, interference2, 0.3);

        // Strong fresnel for edge effects
        float fresnel = pow(normalizedDist, fresnel_power);

        // Smoother rainbow color cycling with continuous transitions
        float rapid_cycle = TIME * color_cycle_speed;

        // Calculate angle with noise-based distortion to hide seams
        float base_angle = atan(toCenter.y, toCenter.x);

        // Add rotating noise distortion to break up the angular seam
        vec2 noise_coord = UV * 5.0 + TIME * 0.5;
        float angle_noise = smoothNoise(noise_coord) * 0.3;
        float rotating_offset = TIME * 0.8;

        // Distort the angle to prevent visible seams
        float distorted_angle = base_angle + angle_noise + rotating_offset;

        // Use sine and cosine to create seamless wrapping
        float angle_component = sin(distorted_angle * 2.0) * 0.25 + cos(distorted_angle * 3.0) * 0.15;

        // Create a smooth continuous hue shift
        float base_hue = rapid_cycle * 0.2;
        float spatial_variation = (normalizedDist * 0.5 + angle_component) * hue_variation;
        float temporal_variation = sin(TIME * 2.0 + interference * 4.0) * 0.1;

        float hue_shift = base_hue + spatial_variation + temporal_variation + interference * color_bands * 0.3;

        // Create smooth color transitions using sine waves
        float smooth_factor = smoothstep(0.0, color_blend_smoothness, sin(hue_shift * 3.14159 * 2.0) * 0.5 + 0.5);

        // Blend between adjacent hues for ultra-smooth transitions
        float h1 = fract(hue_shift);
        float h2 = fract(hue_shift + 0.15);  // Small offset for subtle blend
        float h = mix(h1, h2, smooth_factor);

        // MAXIMUM saturation for vivid colors
        float s = saturation;  // Keep at maximum!

        // Much lower brightness for deep, saturated colors
        float brightness_base = 0.5 + 0.15 * smoothstep(0.3, 0.7, interference);
        float brightness_pulse_factor = sin(TIME * pulsate_speed * 1.5) * 0.15 + 0.85;
        float v = brightness_base * brightness_pulse_factor;

        vec3 rainbow = hsv2rgb(vec3(h, s, v));

        // Boost rainbow intensity in center for full coverage
        float center_boost = 1.0 - normalizedDist;
        rainbow *= (1.0 + center_boost * inner_rainbow_boost);

        // Mix with maximum iridescence everywhere
        float irid_mix = iridescence_strength * rainbow_intensity;

        // Override base color with intense rainbow
        vec3 bubble_color = mix(actual_color * 0.3, rainbow, min(irid_mix, 1.0));

        // Add INTENSE glowing rim with rainbow colors (use distorted angle to avoid seam)
        float rim = smoothstep(current_radius, current_radius - rim_width, distFromCenter);
        float rim_angle_component = sin(distorted_angle) * 0.5 + 0.5;
        float rim_hue = fract(TIME * 2.0 + rim_angle_component);
        vec3 rim_rainbow = hsv2rgb(vec3(rim_hue, 1.0, 1.0));
        vec3 rim_col = rim_rainbow * rim_glow * rim * (0.5 + 0.5 * fresnel);

        // Add rotating RAINBOW highlights (not white!)
        float rot_angle = TIME * 2.0;
        vec2 rotating_light = vec2(
            cos(rot_angle) * 0.25,
            sin(rot_angle) * 0.25
        );
        vec2 light_pos = center + rotating_light;
        float spec_intensity = pow(softcircle(UV, light_pos, 0.08, 0.15), 3.0) * 0.4;

        // Add secondary rotating highlight
        vec2 light_pos2 = center - rotating_light;
        float spec2_intensity = pow(softcircle(UV, light_pos2, 0.06, 0.12), 3.0) * 0.3;

        // Create deeply colored highlights (not bright)
        float highlight_hue = fract(h + 0.1);  // Slightly offset from main color
        vec3 highlight_color = hsv2rgb(vec3(highlight_hue, 1.0, 0.7));  // High saturation, lower brightness

        // Combine everything with screen blending for intense glow
        vec3 final_color = bubble_color;
        final_color = screen(final_color, rim_col);

        // Add colored highlights with reduced intensity
        final_color = mix(final_color, highlight_color, spec_intensity * 0.5);
        final_color = mix(final_color, highlight_color, spec2_intensity * 0.3);

        // Add overall glow effect with controlled brightness pulsation
        float overall_pulse = 1.0 + (sin(TIME * pulsate_speed) * brightness_pulsate_strength * 0.3);
        final_color *= overall_pulse;

        // Boost saturation by reducing luminance of non-dominant color channels
        float max_channel = max(max(final_color.r, final_color.g), final_color.b);
        final_color = mix(final_color, final_color * (final_color / max_channel), 0.5);

        COLOR = vec4(final_color, alpha * base_color.a);
    }
}

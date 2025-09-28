shader_type canvas_item;
render_mode unshaded, blend_mix;

// ---- Controls ----
uniform vec4  base_color = vec4(1, 1, 1, 1.0);
uniform float time = 0.0;
uniform float iridescence_strength = 0.8;

uniform float radius = 0.45;
uniform float edge_softness = 0.06;
uniform float rim_white = 0.2;
uniform float rim_width = 0.12;

// Iridescence controls
uniform float color_bands = 1.0;     // Number of color cycles
uniform float saturation = 0.6;      // Reduced default for softer colors
uniform float flow_speed = 0.3;      // Speed of animated movement
uniform float center_pure_radius = 0.3;  // Radius where only base color shows (0-1)
uniform float center_pure_fade = 0.15;   // How gradual the transition from pure to effects
uniform float center_solid_radius = 0.9;  // How far from center to keep solid (0-1)
uniform float center_fade = 0.1;     // How gradual the transition is
uniform float center_highlight = 0.25;  // Brightness of center highlight (0-1)
uniform float highlight_size = 0.3;    // Size of the bright spot
uniform float highlight_falloff = 2.5; // How quickly it fades (higher = sharper)
uniform float light_color_boost = 2.5;  // How much to boost iridescence on light colors bc it was getting lost


// Light interaction
uniform vec2 light_dir = vec2(0.7, -0.5);  // Simulated light direction
uniform float fresnel_power = 2.5;
uniform vec2 bubble_screen_pos = vec2(0.5, 0.5);
uniform vec2 global_light_pos = vec2(0.3, 0.3);  // Light position in screen space (0-1)
uniform float light_influence = 0.5;  // How much the global light affects the highlight


// ---- Helpers ----

// Calculate luminance (percieved brightness) of a color
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

// Simulate thin-film interference pattern with animated movement
float thinFilmInterference(vec2 uv, vec2 center, float t) {
	
    vec2 toCenter = uv - center;
    
    // Add subtle time-based distortion for organic movement
    float time_distortion = sin(t * flow_speed * 0.5) * 0.02;
    toCenter += vec2(cos(t * flow_speed * 0.7) * time_distortion, sin(t * flow_speed * 0.6) * time_distortion);
    
    // Distance from center
    float dist = length(toCenter);
    
    // Angular component for variation
    float angle = atan(toCenter.y, toCenter.x);
    
    // Create multiple overlapping wave patterns with animated movement
    float wave1 = sin(dist * 8.0 - t * flow_speed * 1.5 + angle * 1.5);
    float wave2 = sin(dist * 5.0 + t * flow_speed * 1.0 + angle * 2.0);   // Re-enabled for more movement
    float wave3 = cos(dist * 11.0 - t * flow_speed * 2.0 - angle * 0.5);
    
    // Mix waves with varying weights
    float pattern = wave1 * 0.3 + wave2 * 0.3 + wave3 * 0.3;
    
    // Apply smoothstep for softer transitions
    pattern = pattern * 0.5 + 0.5;
    return smoothstep(0.2, 0.8, pattern);  // Smooths out harsh edges
}

// ---- Main ----
void fragment() {
    vec2 center = vec2(0.5);
    
    // Bubble alpha mask
    float alpha = softcircle(UV, center, radius, edge_softness);
    
    if (alpha <= 0.001) {
        COLOR = vec4(0.0);
    } else {
        // Get the texture and multiply with incoming COLOR (which contains modulate)
        vec4 tex_color = texture(TEXTURE, UV);
        vec3 actual_color = tex_color.rgb * COLOR.rgb;
        
        vec2 toCenter = UV - center;
        float distFromCenter = length(toCenter);
        float normalizedDist = distFromCenter / radius;
        
        // Calculate interference pattern - use TIME built-in for automatic animation
        float interference = thinFilmInterference(UV, center, TIME);
        
		
		
        // View-dependent effects (Fresnel)
		float fresnel = pow(normalizedDist, fresnel_power) * smoothstep(0.2, 0.6, normalizedDist);        
        
		// Calculate light direction based on bubble's screen position
		vec2 light_dir_screen = normalize(global_light_pos - bubble_screen_pos);

		vec2 local_light_offset = light_dir_screen * 0.2;  // Adjust 0.2 to control offset amount
		
		// Create a more realistic 3D sphere shading for the solid center
		vec2 solid_center = center - local_light_offset * 0.2;  // Reduced from 0.3 for subtlety
		float distFromSolidCenter = length(UV - solid_center);

		// Simulate 3D sphere surface normal
		float sphere_factor = 1.0 - (distFromSolidCenter / center_solid_radius);
		sphere_factor = clamp(sphere_factor, 0.0, 1.0);

		// Use sqrt for more realistic sphere edge falloff (Lambertian-like)
		float sphere_shading = sqrt(sphere_factor);

		// Viewing angle adjustment - less visible at bubble edges
		float view_angle_reduction = 1.0 - (normalizedDist * 0.15);  // Reduced from 0.2

		// Combine sphere shading with smooth transition
		float center_mask = smoothstep(0.0, center_fade, sphere_shading * view_angle_reduction);



		// Use the rotated offset for the light center
		vec2 light_center = center - local_light_offset;

		// Offset the highlight based on where the light is  // Negative because highlight is opposite of light source
		float dist_to_light = length(UV - light_center);
		float norm_light_dist = dist_to_light / radius;

		// Create the light spot
		float center_glow = 1.0 - smoothstep(0.0, highlight_size, norm_light_dist);
		center_glow = pow(center_glow, highlight_falloff);
		
		// Light reflection angle simulation
		
        vec2 normal = normalize(toCenter);
        float light_angle = dot(normal, normalize(light_dir));
        float light_reflection = max(0.0, light_angle);
        light_reflection = pow(light_reflection, 3.0);
        
        // Generate iridescent colors from interference with SMOOTH BLENDING
        float hue_shift = interference * color_bands;
        
        // Smooth the hue transitions using mix between neighboring hues
        float h1 = fract(hue_shift + TIME * flow_speed * 0.1);
        float h2 = fract(hue_shift + TIME * flow_speed * 0.1 + 0.15);  // Offset hue
        float blend_factor = smoothstep(0.3, 0.7, fract(hue_shift * 2.0));
        float h = mix(h1, h2, blend_factor);
        
        // Vary saturation based on viewing angle (reduced for softer colors)
		//and increase for lighter colors (so it shows up)
        float base_luminance_for_sat = luminance(actual_color);  
		float sat_boost = mix(1.0, 1.5, smoothstep(0.5, 0.9, base_luminance_for_sat));
		float s = saturation * (0.4 + 0.4 * fresnel) * (0.7 + 0.3 * interference) * sat_boost;
		s = min(s, 1.0);  // Ensure saturation doesn't exceed 1.0
        
        // Brightness varies with interference and light (narrower range)
        float v = 0.75 + 0.15 * light_reflection + 0.1 * interference;
        
        vec3 iridescent = hsv2rgb(vec3(h, s, v));
        
        // Mix iridescence strength based on fresnel
		float new_center_fade = smoothstep(0.0, 0.6, normalizedDist);
		float irid_mix = iridescence_strength * fresnel * new_center_fade;
		
		// Ensure center stays more opaque
		float center_opacity = 1.0 - smoothstep(0.0, center_solid_radius * 0.8, distFromSolidCenter);
		irid_mix *= (1.0 - center_opacity * 0.7);  // Reduce iridescence in center by up to 70%
		
		//Update: Detect if base color is light and boost iridescence
		float base_luminance = luminance(actual_color);
		float light_boost = mix(1.0, light_color_boost, smoothstep(0.4, 0.8, base_luminance));
		irid_mix *= light_boost;
		irid_mix = min(irid_mix, 1.0);  // Clamp to prevent over-saturation
        
        // Combine base color with iridescence
		vec3 bubble_color;
		if (base_luminance > 0.6) {
		    // For light colors, use multiply-then-add for better contrast
		    vec3 darkened_base = actual_color * (0.7 + 0.3 * (1.0 - interference));
		    bubble_color = mix(darkened_base, iridescent, irid_mix);
		} else {
		    // For darker colors, use standard mixing
		    bubble_color = mix(actual_color, iridescent, irid_mix);
		}

        
        // Add rim lighting
        float rim = smoothstep(radius, radius - rim_width, distFromCenter);
        vec3 rim_col = vec3(1.0) * rim_white * rim * (0.5 + 0.5 * fresnel);
        
		// Add specular highlights based on light direction (with rotation compensation)
		vec2 spec_offset = light_dir * 0.2;

		vec2 light_pos = center - spec_offset;
		float spec = pow(softcircle(UV, light_pos, 0.08, 0.1), 4.0) * 0.6;
        
		// Add center highlight for 3D roundness
		float highlight_reduction = mix(1.0, 0.5, smoothstep(0.5, 0.8, base_luminance));
		vec3 highlight_color = mix(bubble_color, bubble_color * 1.3, center_highlight * center_glow);


		// Final composition with effects
		vec3 effect_color = mix(bubble_color, highlight_color, center_glow);
		effect_color = screen(effect_color, rim_col);
		effect_color += vec3(spec) * (1.0 - irid_mix * 0.5);
		
		// Create pure center mask - inside this radius, only base color shows
		float pure_center_mask = smoothstep(center_pure_radius, center_pure_radius + center_pure_fade, normalizedDist);
		
		// Mix between pure actual color in center and effects outside
		vec3 final_color = mix(actual_color, effect_color, pure_center_mask);
        
        COLOR = vec4(final_color, alpha * base_color.a);
    }
}

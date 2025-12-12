// Blackhole Render
// Using Star Nest by Pablo Roman Andrioli for background


#define iterations 17
#define formuparam 0.53
#define volsteps 20
#define stepsize 0.1
#define zoom   1.000
#define tile   0.850
#define speed  0.003
#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

// Accretion Disk Settings
#define noise_scale 1.0
#define diskDensityV 1.0
#define diskHeight 0.2
#define diskSpeed 0.25

// Blackhole radius
#define blackholeRadius 1.0

// Simplex 3D Noise by Ian McEwan, Ashima Arts
vec4 permute(vec4 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
  const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

  // First corner
  vec3 i = floor(v + dot(v, C.yyy));
  vec3 x0 = v - i + dot(i, C.xxx);

  // Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);

  //  x0 = x0 - 0. + 0.0 * C
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

  // Permutations
  i = mod(i, 289.0);
  vec4 p = permute(permute(permute(i.z + vec4(0.0, i1.z, i2.z, 1.0)) + i.y +
                           vec4(0.0, i1.y, i2.y, 1.0)) +
                   i.x + vec4(0.0, i1.x, i2.x, 1.0));

  // Gradients
  // ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0 / 7.0; // N=7
  vec3 ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z); //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_); // mod(j,N)

  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);

  vec4 s0 = floor(b0) * 2.0 + 1.0;
  vec4 s1 = floor(b1) * 2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);

  // Normalise gradients
  vec4 norm =
      taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  // Mix final noise value
  vec4 m =
      max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
  m = m * m;
  return 42.0 *
         dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

void adiskColor(vec3 pos, inout vec3 color, inout float alpha, float blackholeMass);

// Gravitational lensing acceleration
vec3 accel(float h2, vec3 pos, float mass) {
    float r2 = dot(pos, pos);
    float r5 = pow(r2, 2.5);
    return -1.5 * h2 * pos / r5 * mass;
}

// LookAt matrix
mat3 lookAt(vec3 origin, vec3 target, float roll) {
    vec3 rr = vec3(sin(roll), cos(roll), 0.0);
    vec3 ww = normalize(target - origin);
    vec3 uu = normalize(cross(ww, rr));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

// Lensing ray marcher (returns bent direction and whether it hit the black hole)
vec4 lensRay(vec3 pos, vec3 dir, float blackholeMass, inout vec3 color) {
    float STEP_SIZE = 0.1;
    dir *= STEP_SIZE;
    vec3 h = cross(pos, dir);
    float h2 = dot(h, h);
    bool hitBlackHole = false;
    float alpha = 1.0;
    
    for (int i = 0; i < 300; i++) {
        vec3 acc = accel(h2, pos, blackholeMass);
        dir += acc;
        if (dot(pos, pos) < blackholeRadius * blackholeRadius) {
            hitBlackHole = true;
            break;
        }
        
        adiskColor(pos, color, alpha, blackholeMass);
        pos += dir;
    }
    
    return vec4(normalize(dir), hitBlackHole ? 1.0 : 0.0);
}

// Star Nest by Pablo Roman Andrioli
vec3 starNest(vec3 dir, vec3 from) {
    float s=0.1,fade=1.0;
    vec3 v=vec3(0.0);
    for (int r=0; r<volsteps; r++) {
        vec3 p=from + s*dir*0.5;
        p = abs(vec3(tile)-mod(p,vec3(tile*2.0)));
        float pa,a=pa=0.0;
        for (int i=0; i<iterations; i++) {
            p=abs(p)/dot(p,p)-formuparam;
            a+=abs(length(p)-pa);
            pa=length(p);
        }
        float dm=max(0.0,darkmatter-a*a*0.001);
        a*=a*a;
        if (r>6) fade*=1.0-dm;
        v+=fade;
        v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade;
        fade*=distfading;
        s+=stepsize;
    }
    return mix(vec3(length(v)),v,saturation);
}

// Convert from Cartesian to spherical coordinates
vec3 toSpherical(vec3 p) {
    float rho = sqrt((p.x * p.x) + (p.y * p.y) + (p.z * p.z));
    float theta = atan(p.z, p.x);
    float phi = asin(p.y / rho);
    return vec3(rho, theta, phi);
}

// White to orange gradient function
vec3 diskGradient(float t) {
    // t is expected to be between 0 and 1
    // White (1,1,1) to orange (1, 0.5, 0)
    return vec3(1.0, 1.0 - t * 0.5, 1.0 - t);
}

void adiskColor(vec3 pos, inout vec3 color, inout float alpha, float blackholeMass) {
    float innerRadius = 2.6 * blackholeMass;
    float outerRadius = 12.0 * blackholeMass;

    // Density calculation
    float density = max(0.0, 1.0 - length(pos.xyz / vec3(outerRadius, diskHeight, outerRadius)));
    if (density < 0.001) return;

    density *= pow(1.0 - abs(pos.y) / diskHeight, diskDensityV);
    density *= smoothstep(innerRadius, innerRadius * 1.1, length(pos));
    if (density < 0.001) return;

    vec3 sphericalCoord = toSpherical(pos);
    sphericalCoord.y *= 2.0;
    sphericalCoord.z *= 4.0;

    density *= 1.0 / pow(sphericalCoord.x, 1.0);
    density *= 16000.0;

    // Add noise
    float noise = 1.0;
    for (int i = 0; i < 5; i++) {
        noise *= 0.5 * snoise(sphericalCoord * float(i*i) * noise_scale) + 0.5;
        if (i % 2 == 0) sphericalCoord.y += iTime * diskSpeed;
        else sphericalCoord.y -= iTime* diskSpeed;
    }

    // Apply gradient color
    float t = sphericalCoord.x / outerRadius;
    vec3 dustColor = diskGradient(clamp(t, 0.0, 1.0));

    // Blend with existing color
    color += density * 0.5 * dustColor * alpha * abs(noise);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y;

    float time = iTime * speed + 0.25;
    float blackholeMass = 1.0;

    // Camera
    vec3 camPos = vec3(10.0, 1.0, 10.0);
    vec3 target = vec3(0.0);
    mat3 camMat = lookAt(camPos, target, 0.0);
    vec3 rayDir = normalize(vec3(uv * zoom, 1.0));
    rayDir = camMat * rayDir;

    // Initialize color and do lensing
    vec3 color = vec3(0.0);
    vec4 lensResult = lensRay(camPos, rayDir, blackholeMass, color);
    

    // Only add starfield if we didn't hit the black hole
    if (lensResult.w < 0.5) {
        color += starNest(lensResult.xyz, camPos + time * vec3(2.0, 1.0, -2.0));
    }
    
    fragColor = vec4(color * 0.01, 1.0);
}
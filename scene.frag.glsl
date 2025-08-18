const float PI=3.141592;
const mat2 octave_m=mat2(1.6,1.2,-1.2,1.6);

float hash(float n){
    return fract(sin(n)*43758.5453123);
}

// Function to generate 2D noise, used to create the shape of the clouds.
float noise(vec2 x){
    vec2 p=floor(x);
    vec2 f=fract(x);
    f=f*f*(3.-2.*f);
    float n=p.x+p.y*57.;
    return mix(mix(hash(n+0.),hash(n+1.),f.x),
    mix(hash(n+57.),hash(n+58.),f.x),f.y);
}

// Function to create a cloudy pattern.
float fbm(vec2 p){
    float f=0.;
    f+=.5000*noise(p);
    p*=2.;
    f+=.2500*noise(p);
    p*=2.;
    f+=.1250*noise(p);
    p*=2.;
    f+=.0625*noise(p);
    return f/.9375;// Normalize to 0-1 range
}

// This function draws a single blade of grass with a wave effect.
vec3 blade(vec2 uv,float col,float wave,float layer){
    uv.y+=sin(pow((uv.x-.5),2.)/1.7);
    uv.x-=(uv.y*uv.y)/wave;
    
    float wave_adj=round(uv.x*30.)+layer;
    
    float prand=mod((wave_adj*2347.1923),4.);
    
    wave_adj=prand+(sin(iTime*1.*prand)/5.);
    
    uv.x-=1./(wave_adj+18.2);
    float modded=float(mod((uv.x*30.)+(uv.y/2.),1.));
    
    modded-=uv.y/1.;
    
    modded*=4.;
    
    if(modded>1.){return vec3(0,col*((uv.y+.7)/1.7),0);}
    else{return vec3(0);}
}

// This function draws a transparent grid with adjustable lines.
// It returns a value that can be used to mix colors.
float drawGrid(vec2 uv,float scale,float line_width){
    vec2 grid_uv=uv*scale;
    vec2 grid_lines=fract(grid_uv);
    float grid_val=min(grid_lines.x,grid_lines.y);
    return smoothstep(line_width,line_width+.01,grid_val);
}

float sea_octave(vec2 uv,float choppy){
    uv+=noise(uv);
    vec2 wv=1.-abs(sin(uv));
    vec2 swv=abs(cos(uv));
    wv=mix(wv,swv,wv);
    return pow(1.-pow(wv.x*wv.y,.65),choppy);
}

float getWaterHeight(vec2 uv){
    float freq=.16;
    float amp=.03;// Water height amplitude
    float choppy=4.;
    
    vec2 p=uv;
    p.x*=.75;// Adjust aspect ratio
    
    float d,h=0.;
    float sea_time=iTime*.8;// Control water speed
    
    for(int i=0;i<5;i++){// Fewer iterations for 2D
        d=sea_octave((p+sea_time)*freq,choppy);
        d+=sea_octave((p-sea_time)*freq,choppy);
        h+=d*amp;
        p*=octave_m;
        freq*=1.9;
        amp*=.22;
        choppy=mix(choppy,1.,.2);
    }
    
    return h;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){
    // === 1. Normalized UV coordinates ===
    vec2 uv=fragCoord/iResolution.xy;
    
    // === 2. Define colors for the scene ===
    vec3 skyColor=vec3(.5,.7,.9);// Light blue sky
    vec3 cloudColor=vec3(.95,.95,.95);// White clouds
    
    // === 3. Render the sky and clouds ===
    vec3 finalColor=skyColor;
    vec2 cloudUV=(uv-vec2(.5,.7))*5.;
    cloudUV.x+=iTime*.05;// Make clouds move
    float cloudPattern=fbm(cloudUV);
    finalColor=mix(skyColor,cloudColor,smoothstep(.4,.8,cloudPattern));
    
    // === 4. Render the grass layers on top of the sky ===
    // Adjust the uv by "depth" to give a pseudo 3D effect.
    float depth=(uv.x/-3.)+1.;
    vec2 nuv=uv/depth;
    nuv.x*=2.;
    nuv.y*=10.;
    nuv.y-=4.5;
    
    vec3 grassColor=vec3(0.);
    int layer_count=30;
    
    for(int i=0;i<layer_count;i++){
        nuv.y+=.16;
        nuv.x+=mod(float(i)*4563.2465,.06221);
        nuv.x*=.97;
        nuv.y*=.97;
        float prand=mod((float(i+9))*27464.241,1.);
        float wave_dir=(prand*4.)+12.+(sin((iTime*3.*prand)+(prand*1.))*2.);
        
        vec3 ncol=blade(nuv,(float(i)/-80.)+.9,wave_dir,float(i));
        
        if(ncol!=vec3(0)){
            grassColor=ncol;
        }
    }
    
    // Overlap the grass on the sky.
    if(grassColor!=vec3(0)){
        finalColor=grassColor;
    }
    
    // === 5. Final output ===
    fragColor=vec4(finalColor,1.);
}

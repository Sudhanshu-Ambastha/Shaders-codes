#define NUM_LAYERS 7.
#define Threshold() 0.1
//(0.0+iMouse.y/iResolution.y*1.0)
#define Intensity() 1.5
//(2.0-iMouse.x/iResolution.x*2.0)
#define BlurSize() 3.0
//(6.0-iMouse.x/iResolution.x*6.0)

#define t0 iTime*.2


vec3 palette (float t){
 vec3 a = vec3(0.498, 0.588, 1.128);
 vec3 b = vec3(0.303, 0.388, 0.273);
 vec3 c = vec3(1.763, 0.938, 0.787);
 vec3 d = vec3(-2.982, 1.818, 1.948);
 
 return a + b * cos (6.28318*(c*t+d) );
}

mat2 Rot(float a){
    float s= sin(a), c=cos(a);
    return mat2(c,-s,s,c);
}

float Hash21(vec2 p){
    p = fract(p*vec2(123.34,456.821));
    p += dot(p,p+45.32);
    return fract(p.x*p.y);
}

float Star (vec2 uv, float size, float baseRotation) {
    float d = length(uv);
    float m = 0.
    // inverted circle
    +smoothstep(.12,0.15,d)/7. * (size)
    // glow
    +0.01/d *(size*.5 +.5);
    // circle
    // rotate 45 deg
    uv *= Rot(baseRotation);
    float rays = 0.;
    rays += (max(0.,1.-abs(pow(abs(uv.x),1.8)*uv.y*30000.))) ;
    
    // rotate 45 deg
    uv *= Rot(3.14159/4.);
    rays += (max(0.,1.-abs(uv.x*uv.y* 3000.))) * .7 ;
    m*= smoothstep(1.,0.2,d);
    m+= rays* smoothstep(1.,0.2,d/(size));;
    
    return m;
}

vec3 StarLayer(vec2 uv) {
        vec3 col = vec3(0);

        vec2 gv = fract(uv) -.5;
        vec2 id = floor(uv);
        for(int y=-1;y<=1;y++){
            for(int x=-1;x<=1;x++){
                vec2 offset = vec2(x,y);
                float n = Hash21(id+offset); // random between 0 and 1
                float size = fract (n*149.1)
                * (sin(t0 +n *48.123)*.5+1.);
                float star = Star(-offset + gv-(vec2(n,fract(n*34.))-0.5),smoothstep(.4,1.,size),-3.14159/10.);
                vec3 color = palette(star/3. +t0 + fract(n*9438.7));
                col += star*color;
            }
        }
        return col;
    }

vec4 Bloom (vec2 Coord, in sampler2D Tex, in float MipBias){
	vec2 TexelSize = MipBias/iChannelResolution[0].xy;
    
    vec4  Color = texture(Tex, Coord, MipBias);
    Color += texture(Tex, Coord + vec2(TexelSize.x,0.0), MipBias);    	
    Color += texture(Tex, Coord + vec2(-TexelSize.x,0.0), MipBias);    	
    Color += texture(Tex, Coord + vec2(0.0,TexelSize.y), MipBias);    	
    Color += texture(Tex, Coord + vec2(0.0,-TexelSize.y), MipBias);    	
    Color += texture(Tex, Coord + vec2(TexelSize.x,TexelSize.y), MipBias);    	
    Color += texture(Tex, Coord + vec2(-TexelSize.x,TexelSize.y), MipBias);    	
    Color += texture(Tex, Coord + vec2(TexelSize.x,-TexelSize.y), MipBias);    	
    Color += texture(Tex, Coord + vec2(-TexelSize.x,-TexelSize.y), MipBias);    

    return Color/9.0;

}

vec4 Blend(vec4 color, vec4 highlight){
    return 1.0-(1.0-color)*(1.0-highlight*Intensity()); //Screen Blend Mode
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    float t = t0 *0.1;
    
    vec2 M = 4.*(iMouse.xy-iResolution.xy *.5)/iResolution.y + vec2(sin(t0),cos(t0));
     uv += M*.4;
    vec3 col = vec3(0);
    
    for(float i=0.; i<1.; i+= 1./NUM_LAYERS){
        float depth = fract (i+t);
        float scale = mix(10.,1.,depth);
        col+= StarLayer(uv*scale+i*400.3 -M-t)*
        // fade
        smoothstep(1.,.9,depth)*depth;
    }
    // Output to screen
    //vec2 mappedUV = uv*vec2(0.5,1.)+0.5;
    //vec4 inColor = texture(iChannel0,mappedUV);
    //vec4 Highlight = clamp(Bloom(mappedUV,iChannel0, BlurSize())-Threshold(),0.0,1.0)*1.0/(1.0-Threshold());
    
    //col = col + inColor.xyz;
    //col  = (col+ Blend(inColor, Highlight).xyz);
    //(col+ Blend(inColor, Highlight).xyz)/2.;
    
    fragColor = vec4(col,1.0);
}
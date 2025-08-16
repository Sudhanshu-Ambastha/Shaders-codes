void mainImage(out vec4 fragColor,in vec2 fragCoord){
    // Standard UV setup
    vec2 uv=(fragCoord-.5*iResolution.xy)/iResolution.y;
    
    // Introduce a wave distortion effect based on time
    float time=iTime*.5;
    uv.x+=sin(uv.y*10.+time)*.1;// Ripple the grid horizontally
    uv.y+=cos(uv.x*10.+time)*.1;// Ripple the grid vertically
    
    // Scale the UVs
    uv*=5.;
    vec2 gv=fract(uv)-.5;
    
    // Use a function of time for a continuous color shift
    vec3 animatedColor=vec3(
        sin(iTime*1.)*.5+.5,
        cos(iTime*1.5)*.5+.5,
        sin(iTime*2.)*.5+.5
    );
    
    vec3 col=vec3(0);
    
    // This section applies the animated color to the existing logic
    // The `animatedColor` will be applied to the regions
    if(abs(gv.x)>.48||abs(gv.y)>.48){
        col=animatedColor;
    }else if(abs(gv.x)>.2||abs(gv.y)>.2){
        col=animatedColor*.7;// A slightly darker shade
    }else if(abs(gv.x)>.1||abs(gv.y)>.1){
        col=animatedColor*.5;// An even darker shade
    }else{
        col=animatedColor*.3;// The darkest shade
    }
    
    // Add a circular glowing effect in the center of each cell
    float glow=1.-smoothstep(0.,.4,length(gv));
    col+=glow*vec3(1.);// Add white glow
    
    fragColor=vec4(col,1.);
}
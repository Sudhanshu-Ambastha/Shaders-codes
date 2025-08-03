float Circle(vec2 uv,vec2 p,float r,float blur){
    float d=length(uv-p);
    float c=smoothstep(r,r-blur,d);
    return c;
}

float Smily(vec2 uv,vec2 p,float size){
    uv-=p;
    uv*=size;
    float mask=Circle(uv,vec2(0.,.05),.4,.01);
    mask-=Circle(uv,vec2(-.13,.2),.1,.01);
    mask-=Circle(uv,vec2(.13,.2),.1,.01);
    
    float mouth=Circle(uv,vec2(0.,0.),.3,.02);
    mouth-=Circle(uv,vec2(0.,.1),.3,.02);
    mask-=mouth;
    
    return mask;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){
    vec2 uv=fragCoord.xy/iResolution.xy;
    uv-=.5;
    uv.x*=iResolution.x/iResolution.y;
    
    vec3 col=vec3(0.);
    float mask=Smily(uv,vec2(0.),1.);
    
    col=vec3(1.,1.,0.)*mask;
    fragColor=vec4(col,1.);
}

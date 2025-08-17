#define S smoothstep
#define T iTime*.5

mat2 Rot(float a){
    float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
}

float Feather(vec2 p){
    float d=length(p-vec2(0,clamp(p.y,-.3,.3)));
    float r=mix(.1,.01,S(-.3,.3,p.y));
    float m=S(.01,.0,d-r);
    
    float side=sign(p.x);
    float x=.9*abs(p.x)/r;
    float wave=(1.-x)*sqrt(x)+x*(1.-sqrt(1.-x));
    float y=abs(p.y-wave*.2)*40.+side*56.;
    float id=floor(y+20.);
    float n=fract(sin(id*564.32)*763.);//Random per strand no.
    float shade=mix(.5,1.,n);
    float strandLength=mix(.7,1.,fract(n*34.));
    
    float strand=S(.4,.0,abs(fract(y)-.5)-.3);
    strand*=S(.01,-.2,x-strandLength);
    
    d=length(p-vec2(0,clamp(p.y,-.45,.1)));
    float stem=S(.01,.0,d+p.y*.025);
    
    return max(strand*m*shade,stem);
}

vec3 Transform(vec3 p,float angle){
    p.xz*=Rot(angle);
    p.xy*=Rot(angle*.7);
    return p;
}

vec4 FeatherBall(vec3 ro,vec3 rd,vec3 pos,float angle){
    vec4 col=vec4(0);
    float t=dot(pos-ro,rd);
    vec3 p=ro+rd*t;
    float y=length(pos-p);
    if(y<1.){
        float x=sqrt(1.-y);
        vec3 pF=ro+rd*(t-x)-pos;//front intersection
        pF=Transform(pF,angle);
        vec2 uvF=vec2(atan(pF.x,pF.z),pF.y);//-pi to pi, -1 to 1
        uvF*=vec2(.25,.5);
        float f=Feather(uvF);
        vec4 front=vec4(vec3(f),S(0.,.1,f));
        
        vec3 pB=ro+rd*(t+x)-pos;//back intersection
        pB=Transform(pB,angle);
        vec2 uvB=vec2(atan(pB.x,pB.z),pB.y);//-pi to pi, -1 to 1
        uvB*=vec2(.25,.5);
        float b=Feather(uvB);
        vec4 back=vec4(vec3(b),S(0.,.1,b));
        
        col=mix(back,front,front.a);
    }
    return col;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord){
    vec2 uv=(fragCoord-.5*iResolution.xy)/iResolution.y;
    vec2 M=iMouse.xy/iResolution.xy-.5;
    vec3 bg=vec3(.2,.2,.7)*(uv.y+.5);
    bg+=vec3(1.,.6,.1)*(uv.x+.5);
    
    vec4 col=vec4(bg,0);
    
    // col+=Feather(uv);
    vec3 ro=vec3(0,0,-3);
    vec3 rd=normalize(vec3(uv,1));
    
    for(float i=0.;i<10.;i+=1./10.){
        float x=mix(-8.,8.,fract(i+T*.1))+M.x,
        y=mix(-2.,2.,fract(sin(i*564.3)*4570.3))+M.y,
        z=mix(5.,0.,i),
        a=T+i*563.34;
        
        vec4 feather=FeatherBall(ro,rd,vec3(x,y,z),a);
        feather.rgb*=mix(bg,feather.rgb,mix(.3,1.,i));// Premultiply alpha
        feather.rgb*=sqrt(feather.rgb);// Premultiply alpha
        col=mix(col,feather,feather.a);
    }
    col=pow(col,vec4(.4545));// Gamma correction
    // col.rgb=col.rgb*(1.-col.a)+bg*col.a; // Blend
    
    fragColor=col;
}
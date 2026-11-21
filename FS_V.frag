#version 450
layout(location=0) out vec4 fragColor;
layout(std140, set=0, binding=0) uniform Params {
  vec2 u_wres;
};
layout(set=0, binding=1) uniform sampler2D u_a;

 
void main(){
  vec2 uv=gl_FragCoord.xy/u_wres; float a=0.,b=0.,wa=0.,wb=0.;
  for(int i=-4;i<=4;i++){
    float x=float(i); vec4 t=texture(u_a,uv+vec2(0.,x/u_wres.y));
    float w1=exp(-x*x/1.62), w2=exp(-x*x/5.12);
    a+=(t.r+t.g/255.)*w1; wa+=w1; b+=(t.b+t.a/255.)*w2; wb+=w2;
  }
  a/=wa; b/=wb;
  fragColor=vec4(clamp(.5+(a-b)*12.,0.,1.),b,a,1.);
}
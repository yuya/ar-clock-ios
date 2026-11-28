#version 450
layout(location=0) out vec4 fragColor;
layout(std140, set=0, binding=0) uniform Params {
  vec2 u_src;
  float u_asp;
  float u_mirror;
  vec2 u_wres;
};
layout(set=0, binding=1) uniform sampler2D u_tex;

  
vec2 cover(vec2 uv){
  float rs=u_src.x/u_src.y;
  vec2 s=u_asp>rs?vec2(1.,rs/u_asp):vec2(u_asp/rs,1.);
  uv=(uv-.5)*s+.5;
  if(u_mirror>.5) uv.x=1.-uv.x;
  return uv;
}
float L(vec3 c){return dot(c,vec3(.299,.587,.114));}

vec2 pack(float v){v=clamp(v,0.,.9999)*255.;return vec2(floor(v)/255.,fract(v));}
void main(){
  vec2 uv=gl_FragCoord.xy/u_wres; float a=0.,b=0.,wa=0.,wb=0.;
  for(int i=-4;i<=4;i++){
    float x=float(i), l=L(texture(u_tex,cover(uv+vec2(x/u_wres.x,0.))).rgb);
    float w1=exp(-x*x/1.62), w2=exp(-x*x/5.12);
    a+=l*w1; wa+=w1; b+=l*w2; wb+=w2;
  }
  fragColor=vec4(pack(a/wa),pack(b/wb));
}
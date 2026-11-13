#version 450
layout(location=0) out vec4 fragColor;
layout(std140, set=0, binding=0) uniform Params {
  vec2 u_src;
  float u_asp;
  float u_mirror;
  vec2 u_res;
  float u_t;
  float u_dpr;
  float u_mono;
  float u_look;
  float u_glitch;
  float u_burst;
  float u_lines;
  float u_grain;
  float u_gamma;
  float u_gamt;
  float u_vig;
  float u_old;
  float u_zoom;
  vec3 u_paper;
  vec3 u_ink;
  vec3 u_p0;
  vec3 u_p1;
  vec3 u_p2;
  vec3 u_p3;
};
layout(set=0, binding=1) uniform sampler2D u_tex;
layout(set=0, binding=2) uniform sampler2D u_fx;

  
vec2 cover(vec2 uv){
  float rs=u_src.x/u_src.y;
  vec2 s=u_asp>rs?vec2(1.,rs/u_asp):vec2(u_asp/rs,1.);
  uv=(uv-.5)*s+.5;
  if(u_mirror>.5) uv.x=1.-uv.x;
  return uv;
}
float L(vec3 c){return dot(c,vec3(.299,.587,.114));}
 


float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
vec2 dotCell(vec2 px,float cs){return fract(mat2(.7071,.7071,-.7071,.7071)*px/cs)-.5;}
void main(){
  vec2 uv=gl_FragCoord.xy/u_res, px=gl_FragCoord.xy/u_dpr, uv0=uv;
  uv=(uv-.5)/(1.+u_zoom)+.5;
  float lk=u_look, vig=0.;
  if(lk>5.5){
    // 魚眼：中心を大きく、周辺を強く縮める。あとはフィルタなしと同じに描く
    vec2 p=(uv-.5)*vec2(u_asp,1.); float rm=length(vec2(u_asp,1.))*.5, rn=length(p)/rm;
    p*=.5+.5*rn*rn; uv=p/vec2(u_asp,1.)+.5; lk=0.; vig=smoothstep(.72,1.06,rn)*.9;
  }
  float g=u_glitch, b=u_burst, tt=floor(u_t*14.);
  if(g>0.){
    float band=floor(uv.y*mix(16.,56.,hash(vec2(tt,3.))));
    float ga=u_gamt, gf=mix(.3,1.7,ga);
    if(hash(vec2(band,tt))>1.-(.03+b*.45)*gf) uv.x+=(hash(vec2(band,tt+7.))-.5)*(.07+b*.25)*mix(.45,1.5,ga);
    vec2 blk=floor(uv*vec2(7.,10.));
    if(hash(blk+tt*1.3)>1.-b*.26*gf) uv+=(vec2(hash(blk+1.),hash(blk+2.))-.5)*.2*mix(.5,1.3,ga);
    uv.x+=sin(uv.y*90.+u_t*30.)*.0012*(1.+b*6.)*gf;
  }
  float sh=g*(.004+b*.03)*(.7+.3*sin(u_t*3.))*mix(.5,2.2,u_gamt);
  vec3 cg=texture(u_tex,cover(uv)).rgb, cr=cg, cb=cg;
  if(sh>0.){ cr=texture(u_tex,cover(uv+vec2(sh,0.))).rgb; cb=texture(u_tex,cover(uv-vec2(sh,0.))).rgb; }
  bool mono=u_mono>.5;
  vec3 c=mono?pow(vec3(L(cr),L(cg),L(cb)),vec3(u_gamma)):vec3(cr.r,cg.g,cb.b);
  float l=mono?pow(L(cg),u_gamma):L(cg);
  vec3 col;
  if(lk<.5){
    col=mono?mix(u_ink,u_paper,smoothstep(vec3(.04),vec3(.96),c)):c;
  } else if(lk<1.5 || (lk>2.5 && lk<3.5)){
    vec3 fxv=texture(u_fx,uv).rgb;
    float dog=(fxv.r-.5)/12., tone=mono?pow(fxv.g,u_gamma):fxv.g;
    // 細いペン線：コントラストの弱い所ほど薄く、暗部では少し太らせる
    float line=smoothstep(.0028,.0105,-dog-.0012*tone);
    if(lk<1.5){
      // マンガ：白地に線、ごく暗い所だけベタ、その手前は細かいトーン
      float solid=1.-smoothstep(.085,.15,tone);
      float cs=2.4; vec2 f=dotCell(px,cs); float aa=.9/(cs*u_dpr);
      float r=sqrt(clamp((.34-tone)/.22,0.,1.))*.58;
      float dots=smoothstep(r+aa,r-aa,length(f))*step(.06,r);
      if(mono){
        col=mix(u_paper,u_ink,max(max(line,solid),dots));
        float d=(c.r-c.b)*g; col+=vec3(d,-abs(d)*.3,-d)*1.4;
      } else {
        vec3 wash=mix(vec3(L(c)),c,1.12)*.8+.2;
        col=mix(wash,u_ink,max(line,solid*.92));
      }
    } else {
      // ポップアート：明るさを4色に分け、境目だけ細かい網点でつなぐ
      float x=smoothstep(.07,.93,mono?l:L(c))*3., bandI=floor(min(x,2.999)), fr=x-bandI;
      vec3 lo=bandI<.5?u_p0:(bandI<1.5?u_p1:u_p2), hi=bandI<.5?u_p1:(bandI<1.5?u_p2:u_p3);
      float cs=3.6; vec2 f=dotCell(px,cs); float aa=.9/(cs*u_dpr);
      float r=sqrt(smoothstep(.3,1.,fr))*.66;
      col=mix(lo,hi,smoothstep(r+aa,r-aa,length(f))*step(.04,r));
      col=mix(col,u_ink,line);
    }
  } else if(lk>4.5){
    // ミニチュア：画面中央の帯だけピントを合わせ、上下を強くぼかす。色は濃く、少し明るく
    float R=smoothstep(.07,.42,abs(uv0.y-.5))*13.*u_dpr;
    vec3 a=vec3(0.);
    for(int i=0;i<16;i++){
      float fi=float(i), an=fi*2.39996, rr=sqrt((fi+.5)/16.)*R;
      a+=texture(u_tex,cover(uv+vec2(cos(an),sin(an))*rr/u_res)).rgb;
    }
    a/=16.;
    if(mono) a=vec3(pow(L(a),u_gamma));
    else { float l4=L(a); a=mix(vec3(l4),a,1.55); }
    a=mix(a,smoothstep(vec3(.02),vec3(.95),a),.6)*1.04;
    col=clamp(a,0.,1.);
  } else if(lk>3.5){
    // ビビッド：強めのコントラストと高い彩度。モノクロでは白黒をはっきり分ける
    c=mix(c,smoothstep(vec3(.03),vec3(.97),c),.75);
    if(!mono){ float l3=L(c); c=mix(vec3(l3),c,1.7); c=clamp(c,0.,1.); c=mix(c,c*c*(3.-2.*c),.25); }
    else c=mix(c,c*c*(3.-2.*c),.6);
    col=c;
  } else {
    // フィルム調：浅めの黒、周辺減光。カラーは彩度控えめで影を青緑・明部を暖色に、モノクロは硬めの階調
    if(mono){
      c=smoothstep(vec3(.02),vec3(.98),c); c=mix(c,c*c*(3.-2.*c),.55);
      c=c*vec3(1.,.985,.955)*.94+.035;
    } else {
      c=mix(c,smoothstep(vec3(0.),vec3(1.),c),.38);
      float l2=L(c); c=mix(vec3(l2),c,.8);
      c+=vec3(-.012,.022,.034)*(1.-l2)*(1.-l2);
      c+=vec3(.045,.018,-.04)*l2*l2;
      c.r=pow(max(c.r,0.),.96); c.b=pow(max(c.b,0.),1.05);
      c=c*.93+.04;
    }
    vec2 v=uv0-.5; c*=1.-.42*dot(v,v);
    col=c;
  }
  col*=1.-vig;
  if(u_vig>0.){
    // 周辺減光：画面の中心からの距離で四隅を落とす。強いほど暗い範囲が内側へ広がる
    vec2 q=(uv0-.5)*vec2(u_asp,1.); float rr=length(q)/(length(vec2(u_asp,1.))*.5);
    float fall=smoothstep(mix(.55,.22,u_vig),1.08,rr);
    col*=1.-fall*fall*mix(.55,.97,u_vig)-fall*.12*u_vig;
    col=max(col,0.);
  }
  if(u_old>0.){
    // 古いフィルム：コマごとに場所が変わる黒いゴミ、しばらく居座る縦キズ、明るさのちらつき
    float ft=floor(u_t*16.); vec2 R=u_res/u_dpr;
    float dm=0.;
    for(int i=0;i<7;i++){
      float fi=float(i);
      float on=step(1.-(.3+.62*u_old), hash(vec2(ft,fi*7.3+1.)));
      vec2 c=vec2(hash(vec2(ft+.5,fi+2.)),hash(vec2(fi+5.,ft+.25)))*R;
      float rad=mix(1.6,8.5,pow(hash(vec2(ft,fi+9.)),2.5));
      vec2 d=px-c; d.x*=mix(.55,1.7,hash(vec2(fi,ft+3.)));
      float rough=(hash(floor(px*.8)+ft)-.5)*rad*.6;
      dm=max(dm,on*(1.-smoothstep(rad*.55,rad,length(d)+rough)));
    }
    float sc=0.;
    for(int i=0;i<2;i++){
      float fi=float(i), st=floor(u_t*(1.3+fi*.9));
      float on=step(1.-(.15+.5*u_old), hash(vec2(st,fi+20.)));
      float x=hash(vec2(st,fi+30.))*R.x+sin(px.y*.021+u_t*9.)*1.1+(hash(vec2(ft,fi))-.5)*2.;
      sc=max(sc,on*(1.-smoothstep(.25,1.,abs(px.x-x)))*step(.22,hash(vec2(floor(px.y/46.)+ft,fi))));
    }
    col*=1.+(hash(vec2(ft,77.))-.5)*.16*u_old;
    col=mix(col,vec3(.03),dm*.93); col=mix(col,vec3(.05),sc*.5);
  }
  if(g>0. && hash(vec2(floor(uv.y*9.),tt+11.))>1.-b*.2*u_gamt) col=1.-col;
  if(u_lines>.001){
    vec2 c2=px-u_res/u_dpr*.5; float a=atan(c2.y,c2.x)/6.2832*72.;
    float h=hash(vec2(floor(a),3.)), w=abs(fract(a)-.5);
    float R=(.3+.5*h)*max(u_res.x,u_res.y)/u_dpr*.5*(1.6-min(u_lines,1.));
    col=mix(col,u_ink,step(w,.1+.3*h*h)*smoothstep(R,R+60.,length(c2))*step(.35,h)*min(u_lines*2.,1.));
  }
  float gr=hash(px+fract(u_t)*91.)-.5;
  col+=gr*u_grain*(lk>1.5&&lk<2.5?(1.2-L(col)*.6):1.);
  fragColor=vec4(col,1.);
}
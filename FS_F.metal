#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

struct Params
{
    float2 u_src;
    float u_asp;
    float u_mirror;
    float2 u_res;
    float u_bk;
    float u_lkk;
    float u_sep;
    float u_fish;
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
    float u_bit;
    float u_bitk;
    float u_pix;
    float3 u_paper;
    float3 u_ink;
    float3 u_p0;
    float3 u_p1;
    float3 u_p2;
    float3 u_p3;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

static inline __attribute__((always_inline))
float hash(thread const float2& p)
{
    return fract(sin(dot(p, float2(127.09999847412109375, 311.70001220703125))) * 43758.546875);
}

static inline __attribute__((always_inline))
float2 cover(thread float2& uv, constant Params& _39)
{
    float rs = _39.u_src.x / _39.u_src.y;
    float2 _58;
    if (_39.u_asp > rs)
    {
        _58 = float2(1.0, rs / _39.u_asp);
    }
    else
    {
        _58 = float2(_39.u_asp / rs, 1.0);
    }
    float2 s = _58;
    uv = ((uv - float2(0.5)) * s) + float2(0.5);
    if (_39.u_mirror > 0.5)
    {
        uv.x = 1.0 - uv.x;
    }
    return uv;
}

static inline __attribute__((always_inline))
float L(thread const float3& c)
{
    return dot(c, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
}

static inline __attribute__((always_inline))
float3 ironbow(thread float& t)
{
    t = fast::clamp(t, 0.0, 1.0);
    float3 c = mix(float3(0.0), float3(0.2800000011920928955078125, 0.0, 0.4799999892711639404296875), float3(smoothstep(0.0, 0.2199999988079071044921875, t)));
    c = mix(c, float3(0.85000002384185791015625, 0.07999999821186065673828125, 0.1599999964237213134765625), float3(smoothstep(0.2199999988079071044921875, 0.4799999892711639404296875, t)));
    c = mix(c, float3(1.0, 0.560000002384185791015625, 0.0), float3(smoothstep(0.4799999892711639404296875, 0.699999988079071044921875, t)));
    c = mix(c, float3(1.0, 0.949999988079071044921875, 0.20000000298023223876953125), float3(smoothstep(0.699999988079071044921875, 0.87999999523162841796875, t)));
    return mix(c, float3(1.0), float3(smoothstep(0.87999999523162841796875, 1.0, t)));
}

static inline __attribute__((always_inline))
float3 depthRamp(thread float& t)
{
    t = fast::clamp(t, 0.0, 1.0);
    float3 c = mix(float3(0.0199999995529651641845703125, 0.02999999932944774627685546875, 0.2199999988079071044921875), float3(0.0500000007450580596923828125, 0.25, 0.949999988079071044921875), float3(smoothstep(0.0, 0.25, t)));
    c = mix(c, float3(0.0, 0.89999997615814208984375, 1.0), float3(smoothstep(0.25, 0.5, t)));
    c = mix(c, float3(0.20000000298023223876953125, 1.0, 0.449999988079071044921875), float3(smoothstep(0.5, 0.75, t)));
    return mix(c, float3(1.0, 0.949999988079071044921875, 0.25), float3(smoothstep(0.75, 1.0, t)));
}

static inline __attribute__((always_inline))
float2 dotCell(thread const float2& px, thread const float& cs)
{
    return fract((float2x2(float2(0.707099974155426025390625), float2(-0.707099974155426025390625, 0.707099974155426025390625)) * px) / float2(cs)) - float2(0.5);
}

fragment main0_out main0(constant Params& _39 [[buffer(0)]], texture2d<float> u_tex [[texture(0)]], texture2d<float> u_fx [[texture(1)]], sampler u_texSmplr [[sampler(0)]], sampler u_fxSmplr [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = gl_FragCoord.xy / _39.u_res;
    float2 px = gl_FragCoord.xy / float2(_39.u_dpr);
    float2 uv0 = uv;
    uv = ((uv - float2(0.5)) / float2(1.0 + _39.u_zoom)) + float2(0.5);
    float lk = _39.u_look;
    float vig = 0.0;
    if (_39.u_fish > 0.0)
    {
        float2 p = (uv - float2(0.5)) * float2(_39.u_asp, 1.0);
        float rm = length(float2(_39.u_asp, 1.0)) * 0.5;
        float rn = length(p) / rm;
        p *= mix(1.0, 0.5 + ((0.5 * rn) * rn), _39.u_fish);
        uv = (p / float2(_39.u_asp, 1.0)) + float2(0.5);
        vig = (smoothstep(0.7200000286102294921875, 1.059999942779541015625, rn) * 0.89999997615814208984375) * fast::min(_39.u_fish, 1.0);
    }
    float g = _39.u_glitch;
    float b = _39.u_burst;
    float tt = floor(_39.u_t * 14.0);
    if (g > 0.0)
    {
        float2 param = float2(tt, 3.0);
        float band = floor(uv.y * mix(16.0, 56.0, hash(param)));
        float ga = _39.u_gamt;
        float gf = mix(0.300000011920928955078125, 1.7000000476837158203125, ga);
        float2 param_1 = float2(band, tt);
        if (hash(param_1) > (1.0 - ((0.02999999932944774627685546875 + (b * 0.449999988079071044921875)) * gf)))
        {
            float2 param_2 = float2(band, tt + 7.0);
            uv.x += (((hash(param_2) - 0.5) * (0.070000000298023223876953125 + (b * 0.25))) * mix(0.449999988079071044921875, 1.5, ga));
        }
        float2 blk = floor(uv * float2(7.0, 10.0));
        float2 param_3 = blk + float2(tt * 1.2999999523162841796875);
        if (hash(param_3) > (1.0 - ((b * 0.2599999904632568359375) * gf)))
        {
            float2 param_4 = blk + float2(1.0);
            float2 param_5 = blk + float2(2.0);
            uv += (((float2(hash(param_4), hash(param_5)) - float2(0.5)) * 0.20000000298023223876953125) * mix(0.5, 1.2999999523162841796875, ga));
        }
        uv.x += (((sin((uv.y * 90.0) + (_39.u_t * 30.0)) * 0.00120000005699694156646728515625) * (1.0 + (b * 6.0))) * gf);
    }
    float sh = ((g * (0.0040000001899898052215576171875 + (b * 0.02999999932944774627685546875))) * (0.699999988079071044921875 + (0.300000011920928955078125 * sin(_39.u_t * 3.0)))) * mix(0.5, 2.2000000476837158203125, _39.u_gamt);
    bool _465 = _39.u_bit > 0.5;
    bool _472;
    if (_465)
    {
        _472 = _39.u_pix > 0.5;
    }
    else
    {
        _472 = _465;
    }
    if (_472)
    {
        float2 gr2 = float2(160.0, 160.0 / _39.u_asp);
        uv = (floor(uv * gr2) + float2(0.5)) / gr2;
    }
    float2 param_6 = uv;
    float2 _497 = cover(param_6, _39);
    float3 cg = u_tex.sample(u_texSmplr, _497).xyz;
    float3 cr = cg;
    float3 cb = cg;
    if (sh > 0.0)
    {
        float2 param_7 = uv + float2(sh, 0.0);
        float2 _514 = cover(param_7, _39);
        cr = u_tex.sample(u_texSmplr, _514).xyz;
        float2 param_8 = uv - float2(sh, 0.0);
        float2 _523 = cover(param_8, _39);
        cb = u_tex.sample(u_texSmplr, _523).xyz;
    }
    bool mono = _39.u_mono > 0.5;
    float3 c0 = float3(cr.x, cg.y, cb.z);
    float3 _543;
    if (mono)
    {
        float3 param_9 = cr;
        float3 param_10 = cg;
        float3 param_11 = cb;
        _543 = fast::clamp(mix(c0, powr(float3(L(param_9), L(param_10), L(param_11)), float3(_39.u_gamma)), float3(_39.u_bk)), float3(0.0), float3(1.0));
    }
    else
    {
        _543 = c0;
    }
    float3 c = _543;
    float _575;
    if (mono)
    {
        float3 param_12 = cg;
        float3 param_13 = cg;
        _575 = fast::clamp(mix(L(param_12), powr(L(param_13), _39.u_gamma), _39.u_bk), 0.0, 1.0);
    }
    else
    {
        float3 param_14 = cg;
        _575 = L(param_14);
    }
    float l = _575;
    float3 _598;
    if (mono)
    {
        _598 = fast::clamp(mix(c, mix(_39.u_ink, _39.u_paper, smoothstep(float3(0.039999999105930328369140625), float3(0.959999978542327880859375), c)), float3(_39.u_bk)), float3(0.0), float3(1.0));
    }
    else
    {
        _598 = c;
    }
    float3 nc = _598;
    float3 col;
    if (lk > 6.5)
    {
        float tl = floor(lk + 0.5);
        if (tl < 7.5)
        {
            float3 param_15 = c;
            float param_16 = smoothstep(0.0199999995529651641845703125, 0.980000019073486328125, L(param_15));
            float3 _647 = ironbow(param_16);
            col = _647;
        }
        else
        {
            if (tl < 8.5)
            {
                float sl = 0.800000011920928955078125 + (0.20000000298023223876953125 * cos((6.283199787139892578125 * px.y) / 3.0));
                float ph = mod(px.x, 3.0);
                float3 mk = float3((ph < 1.0) ? 1.0 : 0.5, ((ph >= 1.0) && (ph < 2.0)) ? 1.0 : 0.5, (ph >= 2.0) ? 1.0 : 0.5);
                float fl = (1.0 - (0.02500000037252902984619140625 * sin(_39.u_t * 58.0))) - (0.0199999995529651641845703125 * sin((px.y * 0.01200000010430812835693359375) - (_39.u_t * 2.2000000476837158203125)));
                col = (((c * sl) * mk) * 1.5499999523162841796875) * fl;
                float2 v2 = uv0 - float2(0.5);
                col *= (1.0 - (0.25 * dot(v2, v2)));
            }
            else
            {
                if (tl < 9.5)
                {
                    float2 o = float2(_39.u_dpr) / _39.u_res;
                    float2 param_17 = uv + float2(-o.x, -o.y);
                    float2 _747 = cover(param_17, _39);
                    float3 param_18 = u_tex.sample(u_texSmplr, _747).xyz;
                    float a1 = L(param_18);
                    float2 param_19 = uv + float2(0.0, -o.y);
                    float2 _761 = cover(param_19, _39);
                    float3 param_20 = u_tex.sample(u_texSmplr, _761).xyz;
                    float a2 = L(param_20);
                    float2 param_21 = uv + float2(o.x, -o.y);
                    float2 _777 = cover(param_21, _39);
                    float3 param_22 = u_tex.sample(u_texSmplr, _777).xyz;
                    float a3 = L(param_22);
                    float2 param_23 = uv + float2(-o.x, 0.0);
                    float2 _791 = cover(param_23, _39);
                    float3 param_24 = u_tex.sample(u_texSmplr, _791).xyz;
                    float b1 = L(param_24);
                    float2 param_25 = uv + float2(o.x, 0.0);
                    float2 _804 = cover(param_25, _39);
                    float3 param_26 = u_tex.sample(u_texSmplr, _804).xyz;
                    float b3 = L(param_26);
                    float2 param_27 = uv + float2(-o.x, o.y);
                    float2 _820 = cover(param_27, _39);
                    float3 param_28 = u_tex.sample(u_texSmplr, _820).xyz;
                    float c1 = L(param_28);
                    float2 param_29 = uv + float2(0.0, o.y);
                    float2 _833 = cover(param_29, _39);
                    float3 param_30 = u_tex.sample(u_texSmplr, _833).xyz;
                    float c2 = L(param_30);
                    float2 param_31 = uv + float2(o.x, o.y);
                    float2 _848 = cover(param_31, _39);
                    float3 param_32 = u_tex.sample(u_texSmplr, _848).xyz;
                    float c3 = L(param_32);
                    float gx = ((a3 + (2.0 * b3)) + c3) - ((a1 + (2.0 * b1)) + c1);
                    float gy = ((c1 + (2.0 * c2)) + c3) - ((a1 + (2.0 * a2)) + a3);
                    float e = smoothstep(0.119999997317790985107421875, 0.699999988079071044921875, length(float2(gx, gy)));
                    float3 neon = mix(float3(0.0, 0.85000002384185791015625, 1.0), float3(0.25, 1.0, 0.550000011920928955078125), float3(smoothstep(0.300000011920928955078125, 1.0, e)));
                    col = (c * 0.14000000059604644775390625) + ((neon * e) * 1.35000002384185791015625);
                }
                else
                {
                    float cs = 7.0;
                    float2 cc = (floor(px / float2(cs)) + float2(0.5)) * cs;
                    float2 param_33 = uv + (((cc - px) * _39.u_dpr) / _39.u_res);
                    float2 _931 = cover(param_33, _39);
                    float3 param_34 = u_tex.sample(u_texSmplr, _931).xyz;
                    float dl = L(param_34);
                    float rad = (cs * 0.5) * (0.119999997317790985107421875 + (0.87999999523162841796875 * smoothstep(0.0199999995529651641845703125, 0.949999988079071044921875, dl)));
                    float d = length(px - cc);
                    float aa = smoothstep(rad, rad - 1.0, d);
                    float param_35 = dl;
                    float3 _960 = depthRamp(param_35);
                    col = mix(float3(0.00999999977648258209228515625, 0.014999999664723873138427734375, 0.0500000007450580596923828125), _960, float3(aa));
                }
            }
        }
    }
    else
    {
        if (lk < 0.5)
        {
            col = nc;
        }
        else
        {
            bool _972 = lk < 1.5;
            bool _983;
            if (!_972)
            {
                _983 = (lk > 2.5) && (lk < 3.5);
            }
            else
            {
                _983 = _972;
            }
            if (_983)
            {
                float3 fxv = u_fx.sample(u_fxSmplr, uv).xyz;
                float dog = (fxv.x - 0.5) / 12.0;
                float _1000;
                if (mono)
                {
                    _1000 = powr(fxv.y, _39.u_gamma);
                }
                else
                {
                    _1000 = fxv.y;
                }
                float tone = _1000;
                float line = smoothstep(0.002799999900162220001220703125, 0.010499999858438968658447265625, (-dog) - (0.00120000005699694156646728515625 * tone));
                if (lk < 1.5)
                {
                    float solid = 1.0 - smoothstep(0.085000000894069671630859375, 0.1500000059604644775390625, tone);
                    float cs_1 = 2.400000095367431640625;
                    float2 param_36 = px;
                    float param_37 = cs_1;
                    float2 f = dotCell(param_36, param_37);
                    float aa_1 = 0.89999997615814208984375 / (cs_1 * _39.u_dpr);
                    float r = sqrt(fast::clamp((0.3400000035762786865234375 - tone) / 0.2199999988079071044921875, 0.0, 1.0)) * 0.579999983310699462890625;
                    float dots = smoothstep(r + aa_1, r - aa_1, length(f)) * step(0.0599999986588954925537109375, r);
                    if (mono)
                    {
                        col = mix(_39.u_paper, _39.u_ink, float3(fast::max(fast::max(line, solid), dots)));
                        float d_1 = (c.x - c.z) * g;
                        col += (float3(d_1, (-abs(d_1)) * 0.300000011920928955078125, -d_1) * 1.39999997615814208984375);
                    }
                    else
                    {
                        float3 param_38 = c;
                        float3 wash = (mix(float3(L(param_38)), c, float3(1.12000000476837158203125)) * 0.800000011920928955078125) + float3(0.20000000298023223876953125);
                        col = mix(wash, _39.u_ink, float3(fast::max(line, solid * 0.920000016689300537109375)));
                    }
                }
                else
                {
                    float _1129;
                    if (mono)
                    {
                        _1129 = l;
                    }
                    else
                    {
                        float3 param_39 = c;
                        _1129 = L(param_39);
                    }
                    float x = smoothstep(0.070000000298023223876953125, 0.930000007152557373046875, _1129) * 3.0;
                    float bandI = floor(fast::min(x, 2.999000072479248046875));
                    float fr = x - bandI;
                    float3 _1152;
                    if (bandI < 0.5)
                    {
                        _1152 = _39.u_p0;
                    }
                    else
                    {
                        float3 _1161;
                        if (bandI < 1.5)
                        {
                            _1161 = _39.u_p1;
                        }
                        else
                        {
                            _1161 = _39.u_p2;
                        }
                        _1152 = _1161;
                    }
                    float3 lo = _1152;
                    float3 _1176;
                    if (bandI < 0.5)
                    {
                        _1176 = _39.u_p1;
                    }
                    else
                    {
                        float3 _1184;
                        if (bandI < 1.5)
                        {
                            _1184 = _39.u_p2;
                        }
                        else
                        {
                            _1184 = _39.u_p3;
                        }
                        _1176 = _1184;
                    }
                    float3 hi = _1176;
                    float cs_2 = 3.599999904632568359375;
                    float2 param_40 = px;
                    float param_41 = cs_2;
                    float2 f_1 = dotCell(param_40, param_41);
                    float aa_2 = 0.89999997615814208984375 / (cs_2 * _39.u_dpr);
                    float r_1 = sqrt(smoothstep(0.300000011920928955078125, 1.0, fr)) * 0.660000026226043701171875;
                    col = mix(lo, hi, float3(smoothstep(r_1 + aa_2, r_1 - aa_2, length(f_1)) * step(0.039999999105930328369140625, r_1)));
                    col = mix(col, _39.u_ink, float3(line));
                }
            }
            else
            {
                if (lk > 4.5)
                {
                    float R = (smoothstep(0.070000000298023223876953125, 0.4199999868869781494140625, abs(uv0.y - 0.5)) * 13.0) * _39.u_dpr;
                    float3 a = float3(0.0);
                    for (int i = 0; i < 16; i++)
                    {
                        float fi = float(i);
                        float an = fi * 2.399960041046142578125;
                        float rr = sqrt((fi + 0.5) / 16.0) * R;
                        float2 param_42 = uv + ((float2(cos(an), sin(an)) * rr) / _39.u_res);
                        float2 _1293 = cover(param_42, _39);
                        a += u_tex.sample(u_texSmplr, _1293).xyz;
                    }
                    a /= float3(16.0);
                    if (mono)
                    {
                        float3 param_43 = a;
                        a = float3(powr(L(param_43), _39.u_gamma));
                    }
                    else
                    {
                        float3 param_44 = a;
                        float l4 = L(param_44);
                        a = mix(float3(l4), a, float3(1.5499999523162841796875));
                    }
                    a = mix(a, smoothstep(float3(0.0199999995529651641845703125), float3(0.949999988079071044921875), a), float3(0.60000002384185791015625)) * 1.03999996185302734375;
                    col = fast::clamp(a, float3(0.0), float3(1.0));
                }
                else
                {
                    if (lk > 3.5)
                    {
                        c = mix(c, smoothstep(float3(0.02999999932944774627685546875), float3(0.9700000286102294921875), c), float3(0.75));
                        if (!mono)
                        {
                            float3 param_45 = c;
                            float l3 = L(param_45);
                            c = mix(float3(l3), c, float3(1.7000000476837158203125));
                            c = fast::clamp(c, float3(0.0), float3(1.0));
                            c = mix(c, (c * c) * (float3(3.0) - (c * 2.0)), float3(0.25));
                        }
                        else
                        {
                            c = mix(c, (c * c) * (float3(3.0) - (c * 2.0)), float3(0.60000002384185791015625));
                        }
                        col = c;
                    }
                    else
                    {
                        if (mono)
                        {
                            c = smoothstep(float3(0.0199999995529651641845703125), float3(0.980000019073486328125), c);
                            c = mix(c, (c * c) * (float3(3.0) - (c * 2.0)), float3(0.550000011920928955078125));
                            c = ((c * float3(1.0, 0.98500001430511474609375, 0.954999983310699462890625)) * 0.939999997615814208984375) + float3(0.0350000001490116119384765625);
                        }
                        else
                        {
                            c = mix(c, smoothstep(float3(0.0), float3(1.0), c), float3(0.37999999523162841796875));
                            float3 param_46 = c;
                            float l2 = L(param_46);
                            c = mix(float3(l2), c, float3(0.800000011920928955078125));
                            c += ((float3(-0.01200000010430812835693359375, 0.02199999988079071044921875, 0.034000001847743988037109375) * (1.0 - l2)) * (1.0 - l2));
                            c += ((float3(0.04500000178813934326171875, 0.017999999225139617919921875, -0.039999999105930328369140625) * l2) * l2);
                            c.x = powr(fast::max(c.x, 0.0), 0.959999978542327880859375);
                            c.z = powr(fast::max(c.z, 0.0), 1.0499999523162841796875);
                            c = (c * 0.930000007152557373046875) + float3(0.039999999105930328369140625);
                        }
                        float2 v = uv0 - float2(0.5);
                        c *= (1.0 - (0.4199999868869781494140625 * dot(v, v)));
                        col = c;
                    }
                }
            }
        }
    }
    if (lk > 0.5)
    {
        col = fast::clamp(mix(nc, col, float3(_39.u_lkk)), float3(0.0), float3(1.0));
    }
    if (_39.u_sep > 0.5)
    {
        float3 param_47 = col;
        float sl_1 = fast::clamp(L(param_47), 0.0, 1.0);
        float3 _1512;
        if (sl_1 < 0.5)
        {
            _1512 = mix(float3(0.100000001490116119384765625, 0.064999997615814208984375, 0.039999999105930328369140625), float3(0.60000002384185791015625, 0.449999988079071044921875, 0.300000011920928955078125), float3(sl_1 * 2.0));
        }
        else
        {
            _1512 = mix(float3(0.60000002384185791015625, 0.449999988079071044921875, 0.300000011920928955078125), float3(0.980000019073486328125, 0.930000007152557373046875, 0.810000002384185791015625), float3((sl_1 * 2.0) - 1.0));
        }
        float3 sp = _1512;
        col = fast::clamp(mix(col, sp, float3(_39.u_bk)), float3(0.0), float3(1.0));
    }
    col *= (1.0 - vig);
    if (_39.u_vig > 0.0)
    {
        float2 q = (uv0 - float2(0.5)) * float2(_39.u_asp, 1.0);
        float rr_1 = length(q) / (length(float2(_39.u_asp, 1.0)) * 0.5);
        float fall = smoothstep(mix(0.550000011920928955078125, 0.2199999988079071044921875, _39.u_vig), 1.08000004291534423828125, rr_1);
        col *= ((1.0 - ((fall * fall) * mix(0.550000011920928955078125, 0.9700000286102294921875, _39.u_vig))) - ((fall * 0.119999997317790985107421875) * _39.u_vig));
        col = fast::max(col, float3(0.0));
    }
    if (_39.u_old > 0.0)
    {
        float ft = floor(_39.u_t * 16.0);
        float2 R_1 = _39.u_res / float2(_39.u_dpr);
        float dm = 0.0;
        for (int i_1 = 0; i_1 < 7; i_1++)
        {
            float fi_1 = float(i_1);
            float2 param_48 = float2(ft, (fi_1 * 7.30000019073486328125) + 1.0);
            float on = step(1.0 - (0.300000011920928955078125 + (0.62000000476837158203125 * _39.u_old)), hash(param_48));
            float2 param_49 = float2(ft + 0.5, fi_1 + 2.0);
            float2 param_50 = float2(fi_1 + 5.0, ft + 0.25);
            float2 c_1 = float2(hash(param_49), hash(param_50)) * R_1;
            float2 param_51 = float2(ft, fi_1 + 9.0);
            float rad_1 = mix(1.60000002384185791015625, 8.5, powr(hash(param_51), 2.5));
            float2 d_2 = px - c_1;
            float2 param_52 = float2(fi_1, ft + 3.0);
            d_2.x *= mix(0.550000011920928955078125, 1.7000000476837158203125, hash(param_52));
            float2 param_53 = floor(px * 0.800000011920928955078125) + float2(ft);
            float rough = ((hash(param_53) - 0.5) * rad_1) * 0.60000002384185791015625;
            dm = fast::max(dm, on * (1.0 - smoothstep(rad_1 * 0.550000011920928955078125, rad_1, length(d_2) + rough)));
        }
        float sc = 0.0;
        for (int i_2 = 0; i_2 < 2; i_2++)
        {
            float fi_2 = float(i_2);
            float st = floor(_39.u_t * (1.2999999523162841796875 + (fi_2 * 0.89999997615814208984375)));
            float2 param_54 = float2(st, fi_2 + 20.0);
            float on_1 = step(1.0 - (0.1500000059604644775390625 + (0.5 * _39.u_old)), hash(param_54));
            float2 param_55 = float2(st, fi_2 + 30.0);
            float2 param_56 = float2(ft, fi_2);
            float x_1 = ((hash(param_55) * R_1.x) + (sin((px.y * 0.02099999971687793731689453125) + (_39.u_t * 9.0)) * 1.10000002384185791015625)) + ((hash(param_56) - 0.5) * 2.0);
            float2 param_57 = float2(floor(px.y / 46.0) + ft, fi_2);
            sc = fast::max(sc, (on_1 * (1.0 - smoothstep(0.25, 1.0, abs(px.x - x_1)))) * step(0.2199999988079071044921875, hash(param_57)));
        }
        float2 param_58 = float2(ft, 77.0);
        col *= (1.0 + (((hash(param_58) - 0.5) * 0.1599999964237213134765625) * _39.u_old));
        col = mix(col, float3(0.02999999932944774627685546875), float3(dm * 0.930000007152557373046875));
        col = mix(col, float3(0.0500000007450580596923828125), float3(sc * 0.5));
    }
    bool _1828 = g > 0.0;
    bool _1848;
    if (_1828)
    {
        float2 param_59 = float2(floor(uv.y * 9.0), tt + 11.0);
        _1848 = hash(param_59) > (1.0 - ((b * 0.20000000298023223876953125) * _39.u_gamt));
    }
    else
    {
        _1848 = _1828;
    }
    if (_1848)
    {
        col = float3(1.0) - col;
    }
    if (_39.u_lines > 0.001000000047497451305389404296875)
    {
        float2 c2_1 = px - ((_39.u_res / float2(_39.u_dpr)) * 0.5);
        float a_1 = (precise::atan2(c2_1.y, c2_1.x) / 6.283199787139892578125) * 72.0;
        float2 param_60 = float2(floor(a_1), 3.0);
        float h = hash(param_60);
        float w = abs(fract(a_1) - 0.5);
        float R_2 = ((((0.300000011920928955078125 + (0.5 * h)) * fast::max(_39.u_res.x, _39.u_res.y)) / _39.u_dpr) * 0.5) * (1.60000002384185791015625 - fast::min(_39.u_lines, 1.0));
        col = mix(col, _39.u_ink, float3(((step(w, 0.100000001490116119384765625 + ((0.300000011920928955078125 * h) * h)) * smoothstep(R_2, R_2 + 60.0, length(c2_1))) * step(0.3499999940395355224609375, h)) * fast::min(_39.u_lines * 2.0, 1.0)));
    }
    float2 param_61 = px + float2(fract(_39.u_t) * 91.0);
    float gr = hash(param_61) - 0.5;
    float _1961;
    if ((lk > 1.5) && (lk < 2.5))
    {
        float3 param_62 = col;
        _1961 = 1.2000000476837158203125 - (L(param_62) * 0.60000002384185791015625);
    }
    else
    {
        _1961 = 1.0;
    }
    col += float3((gr * _39.u_grain) * _1961);
    if (_39.u_bit > 0.5)
    {
        float3 pre = col;
        float2 _1987;
        if (_39.u_pix > 0.5)
        {
            _1987 = floor(uv0 * float2(160.0, 160.0 / _39.u_asp));
        }
        else
        {
            _1987 = floor(px / float2(2.0));
        }
        float2 bp = _1987;
        float bx = mod(bp.x, 4.0);
        float by = mod(bp.y, 4.0);
        float bi = mod(((bx * 5.0) + (by * 3.0)) + (mod(floor(bx / 2.0) + floor(by / 2.0), 2.0) * 8.0), 16.0);
        float thr = (bi + 0.5) / 16.0;
        if (_39.u_bit < 1.5)
        {
            float3 param_63 = col;
            float3 _2052;
            if (L(param_63) > (0.5 + (((thr - 0.5) * _39.u_bitk) * 1.14999997615814208984375)))
            {
                _2052 = _39.u_paper;
            }
            else
            {
                _2052 = _39.u_ink;
            }
            col = _2052;
        }
        else
        {
            float3 param_64 = col;
            float v_1 = fast::clamp(L(param_64) + (((thr - 0.5) * _39.u_bitk) * 0.4000000059604644775390625), 0.0, 0.999000012874603271484375);
            float k = floor(v_1 * 4.0);
            float3 _2082;
            if (k < 1.0)
            {
                _2082 = float3(0.05900000035762786865234375, 0.2199999988079071044921875, 0.05900000035762786865234375);
            }
            else
            {
                float3 _2090;
                if (k < 2.0)
                {
                    _2090 = float3(0.1879999935626983642578125, 0.384000003337860107421875, 0.1879999935626983642578125);
                }
                else
                {
                    _2090 = select(float3(0.607999980449676513671875, 0.736999988555908203125, 0.05900000035762786865234375), float3(0.545000016689300537109375, 0.675000011920928955078125, 0.05900000035762786865234375), bool3(k < 3.0));
                }
                _2082 = _2090;
            }
            col = _2082;
        }
        col = fast::clamp(mix(pre, col, float3(_39.u_bk)), float3(0.0), float3(1.0));
    }
    out.fragColor = float4(col, 1.0);
    return out;
}


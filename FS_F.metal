#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float2 u_src;
    float u_asp;
    float u_mirror;
    float2 u_res;
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
float2 cover(thread float2& uv, constant Params& _32)
{
    float rs = _32.u_src.x / _32.u_src.y;
    float2 _51;
    if (_32.u_asp > rs)
    {
        _51 = float2(1.0, rs / _32.u_asp);
    }
    else
    {
        _51 = float2(_32.u_asp / rs, 1.0);
    }
    float2 s = _51;
    uv = ((uv - float2(0.5)) * s) + float2(0.5);
    if (_32.u_mirror > 0.5)
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
float2 dotCell(thread const float2& px, thread const float& cs)
{
    return fract((float2x2(float2(0.707099974155426025390625), float2(-0.707099974155426025390625, 0.707099974155426025390625)) * px) / float2(cs)) - float2(0.5);
}

fragment main0_out main0(constant Params& _32 [[buffer(0)]], texture2d<float> u_tex [[texture(0)]], texture2d<float> u_fx [[texture(1)]], sampler u_texSmplr [[sampler(0)]], sampler u_fxSmplr [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = gl_FragCoord.xy / _32.u_res;
    float2 px = gl_FragCoord.xy / float2(_32.u_dpr);
    float2 uv0 = uv;
    uv = ((uv - float2(0.5)) / float2(1.0 + _32.u_zoom)) + float2(0.5);
    float lk = _32.u_look;
    float vig = 0.0;
    if (lk > 5.5)
    {
        float2 p = (uv - float2(0.5)) * float2(_32.u_asp, 1.0);
        float rm = length(float2(_32.u_asp, 1.0)) * 0.5;
        float rn = length(p) / rm;
        p *= (0.5 + ((0.5 * rn) * rn));
        uv = (p / float2(_32.u_asp, 1.0)) + float2(0.5);
        lk = 0.0;
        vig = smoothstep(0.7200000286102294921875, 1.059999942779541015625, rn) * 0.89999997615814208984375;
    }
    float g = _32.u_glitch;
    float b = _32.u_burst;
    float tt = floor(_32.u_t * 14.0);
    if (g > 0.0)
    {
        float2 param = float2(tt, 3.0);
        float band = floor(uv.y * mix(16.0, 56.0, hash(param)));
        float ga = _32.u_gamt;
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
        uv.x += (((sin((uv.y * 90.0) + (_32.u_t * 30.0)) * 0.00120000005699694156646728515625) * (1.0 + (b * 6.0))) * gf);
    }
    float sh = ((g * (0.0040000001899898052215576171875 + (b * 0.02999999932944774627685546875))) * (0.699999988079071044921875 + (0.300000011920928955078125 * sin(_32.u_t * 3.0)))) * mix(0.5, 2.2000000476837158203125, _32.u_gamt);
    float2 param_6 = uv;
    float2 _379 = cover(param_6, _32);
    float3 cg = u_tex.sample(u_texSmplr, _379).xyz;
    float3 cr = cg;
    float3 cb = cg;
    if (sh > 0.0)
    {
        float2 param_7 = uv + float2(sh, 0.0);
        float2 _396 = cover(param_7, _32);
        cr = u_tex.sample(u_texSmplr, _396).xyz;
        float2 param_8 = uv - float2(sh, 0.0);
        float2 _405 = cover(param_8, _32);
        cb = u_tex.sample(u_texSmplr, _405).xyz;
    }
    bool mono = _32.u_mono > 0.5;
    float3 _416;
    if (mono)
    {
        float3 param_9 = cr;
        float3 param_10 = cg;
        float3 param_11 = cb;
        _416 = powr(float3(L(param_9), L(param_10), L(param_11)), float3(_32.u_gamma));
    }
    else
    {
        _416 = float3(cr.x, cg.y, cb.z);
    }
    float3 c = _416;
    float _446;
    if (mono)
    {
        float3 param_12 = cg;
        _446 = powr(L(param_12), _32.u_gamma);
    }
    else
    {
        float3 param_13 = cg;
        _446 = L(param_13);
    }
    float l = _446;
    float3 col;
    if (lk < 0.5)
    {
        float3 _466;
        if (mono)
        {
            _466 = mix(_32.u_ink, _32.u_paper, smoothstep(float3(0.039999999105930328369140625), float3(0.959999978542327880859375), c));
        }
        else
        {
            _466 = c;
        }
        col = _466;
    }
    else
    {
        bool _488 = lk < 1.5;
        bool _499;
        if (!_488)
        {
            _499 = (lk > 2.5) && (lk < 3.5);
        }
        else
        {
            _499 = _488;
        }
        if (_499)
        {
            float3 fxv = u_fx.sample(u_fxSmplr, uv).xyz;
            float dog = (fxv.x - 0.5) / 12.0;
            float _516;
            if (mono)
            {
                _516 = powr(fxv.y, _32.u_gamma);
            }
            else
            {
                _516 = fxv.y;
            }
            float tone = _516;
            float line = smoothstep(0.002799999900162220001220703125, 0.010499999858438968658447265625, (-dog) - (0.00120000005699694156646728515625 * tone));
            if (lk < 1.5)
            {
                float solid = 1.0 - smoothstep(0.085000000894069671630859375, 0.1500000059604644775390625, tone);
                float cs = 2.400000095367431640625;
                float2 param_14 = px;
                float param_15 = cs;
                float2 f = dotCell(param_14, param_15);
                float aa = 0.89999997615814208984375 / (cs * _32.u_dpr);
                float r = sqrt(fast::clamp((0.3400000035762786865234375 - tone) / 0.2199999988079071044921875, 0.0, 1.0)) * 0.579999983310699462890625;
                float dots = smoothstep(r + aa, r - aa, length(f)) * step(0.0599999986588954925537109375, r);
                if (mono)
                {
                    col = mix(_32.u_paper, _32.u_ink, float3(fast::max(fast::max(line, solid), dots)));
                    float d = (c.x - c.z) * g;
                    col += (float3(d, (-abs(d)) * 0.300000011920928955078125, -d) * 1.39999997615814208984375);
                }
                else
                {
                    float3 param_16 = c;
                    float3 wash = (mix(float3(L(param_16)), c, float3(1.12000000476837158203125)) * 0.800000011920928955078125) + float3(0.20000000298023223876953125);
                    col = mix(wash, _32.u_ink, float3(fast::max(line, solid * 0.920000016689300537109375)));
                }
            }
            else
            {
                float _647;
                if (mono)
                {
                    _647 = l;
                }
                else
                {
                    float3 param_17 = c;
                    _647 = L(param_17);
                }
                float x = smoothstep(0.070000000298023223876953125, 0.930000007152557373046875, _647) * 3.0;
                float bandI = floor(fast::min(x, 2.999000072479248046875));
                float fr = x - bandI;
                float3 _670;
                if (bandI < 0.5)
                {
                    _670 = _32.u_p0;
                }
                else
                {
                    float3 _679;
                    if (bandI < 1.5)
                    {
                        _679 = _32.u_p1;
                    }
                    else
                    {
                        _679 = _32.u_p2;
                    }
                    _670 = _679;
                }
                float3 lo = _670;
                float3 _694;
                if (bandI < 0.5)
                {
                    _694 = _32.u_p1;
                }
                else
                {
                    float3 _702;
                    if (bandI < 1.5)
                    {
                        _702 = _32.u_p2;
                    }
                    else
                    {
                        _702 = _32.u_p3;
                    }
                    _694 = _702;
                }
                float3 hi = _694;
                float cs_1 = 3.599999904632568359375;
                float2 param_18 = px;
                float param_19 = cs_1;
                float2 f_1 = dotCell(param_18, param_19);
                float aa_1 = 0.89999997615814208984375 / (cs_1 * _32.u_dpr);
                float r_1 = sqrt(smoothstep(0.300000011920928955078125, 1.0, fr)) * 0.660000026226043701171875;
                col = mix(lo, hi, float3(smoothstep(r_1 + aa_1, r_1 - aa_1, length(f_1)) * step(0.039999999105930328369140625, r_1)));
                col = mix(col, _32.u_ink, float3(line));
            }
        }
        else
        {
            if (lk > 4.5)
            {
                float R = (smoothstep(0.070000000298023223876953125, 0.4199999868869781494140625, abs(uv0.y - 0.5)) * 13.0) * _32.u_dpr;
                float3 a = float3(0.0);
                for (int i = 0; i < 16; i++)
                {
                    float fi = float(i);
                    float an = fi * 2.399960041046142578125;
                    float rr = sqrt((fi + 0.5) / 16.0) * R;
                    float2 param_20 = uv + ((float2(cos(an), sin(an)) * rr) / _32.u_res);
                    float2 _812 = cover(param_20, _32);
                    a += u_tex.sample(u_texSmplr, _812).xyz;
                }
                a /= float3(16.0);
                if (mono)
                {
                    float3 param_21 = a;
                    a = float3(powr(L(param_21), _32.u_gamma));
                }
                else
                {
                    float3 param_22 = a;
                    float l4 = L(param_22);
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
                        float3 param_23 = c;
                        float l3 = L(param_23);
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
                        float3 param_24 = c;
                        float l2 = L(param_24);
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
    col *= (1.0 - vig);
    if (_32.u_vig > 0.0)
    {
        float2 q = (uv0 - float2(0.5)) * float2(_32.u_asp, 1.0);
        float rr_1 = length(q) / (length(float2(_32.u_asp, 1.0)) * 0.5);
        float fall = smoothstep(mix(0.550000011920928955078125, 0.2199999988079071044921875, _32.u_vig), 1.08000004291534423828125, rr_1);
        col *= ((1.0 - ((fall * fall) * mix(0.550000011920928955078125, 0.9700000286102294921875, _32.u_vig))) - ((fall * 0.119999997317790985107421875) * _32.u_vig));
        col = fast::max(col, float3(0.0));
    }
    if (_32.u_old > 0.0)
    {
        float ft = floor(_32.u_t * 16.0);
        float2 R_1 = _32.u_res / float2(_32.u_dpr);
        float dm = 0.0;
        for (int i_1 = 0; i_1 < 7; i_1++)
        {
            float fi_1 = float(i_1);
            float2 param_25 = float2(ft, (fi_1 * 7.30000019073486328125) + 1.0);
            float on = step(1.0 - (0.300000011920928955078125 + (0.62000000476837158203125 * _32.u_old)), hash(param_25));
            float2 param_26 = float2(ft + 0.5, fi_1 + 2.0);
            float2 param_27 = float2(fi_1 + 5.0, ft + 0.25);
            float2 c_1 = float2(hash(param_26), hash(param_27)) * R_1;
            float2 param_28 = float2(ft, fi_1 + 9.0);
            float rad = mix(1.60000002384185791015625, 8.5, powr(hash(param_28), 2.5));
            float2 d_1 = px - c_1;
            float2 param_29 = float2(fi_1, ft + 3.0);
            d_1.x *= mix(0.550000011920928955078125, 1.7000000476837158203125, hash(param_29));
            float2 param_30 = floor(px * 0.800000011920928955078125) + float2(ft);
            float rough = ((hash(param_30) - 0.5) * rad) * 0.60000002384185791015625;
            dm = fast::max(dm, on * (1.0 - smoothstep(rad * 0.550000011920928955078125, rad, length(d_1) + rough)));
        }
        float sc = 0.0;
        for (int i_2 = 0; i_2 < 2; i_2++)
        {
            float fi_2 = float(i_2);
            float st = floor(_32.u_t * (1.2999999523162841796875 + (fi_2 * 0.89999997615814208984375)));
            float2 param_31 = float2(st, fi_2 + 20.0);
            float on_1 = step(1.0 - (0.1500000059604644775390625 + (0.5 * _32.u_old)), hash(param_31));
            float2 param_32 = float2(st, fi_2 + 30.0);
            float2 param_33 = float2(ft, fi_2);
            float x_1 = ((hash(param_32) * R_1.x) + (sin((px.y * 0.02099999971687793731689453125) + (_32.u_t * 9.0)) * 1.10000002384185791015625)) + ((hash(param_33) - 0.5) * 2.0);
            float2 param_34 = float2(floor(px.y / 46.0) + ft, fi_2);
            sc = fast::max(sc, (on_1 * (1.0 - smoothstep(0.25, 1.0, abs(px.x - x_1)))) * step(0.2199999988079071044921875, hash(param_34)));
        }
        float2 param_35 = float2(ft, 77.0);
        col *= (1.0 + (((hash(param_35) - 0.5) * 0.1599999964237213134765625) * _32.u_old));
        col = mix(col, float3(0.02999999932944774627685546875), float3(dm * 0.930000007152557373046875));
        col = mix(col, float3(0.0500000007450580596923828125), float3(sc * 0.5));
    }
    bool _1301 = g > 0.0;
    bool _1321;
    if (_1301)
    {
        float2 param_36 = float2(floor(uv.y * 9.0), tt + 11.0);
        _1321 = hash(param_36) > (1.0 - ((b * 0.20000000298023223876953125) * _32.u_gamt));
    }
    else
    {
        _1321 = _1301;
    }
    if (_1321)
    {
        col = float3(1.0) - col;
    }
    if (_32.u_lines > 0.001000000047497451305389404296875)
    {
        float2 c2 = px - ((_32.u_res / float2(_32.u_dpr)) * 0.5);
        float a_1 = (precise::atan2(c2.y, c2.x) / 6.283199787139892578125) * 72.0;
        float2 param_37 = float2(floor(a_1), 3.0);
        float h = hash(param_37);
        float w = abs(fract(a_1) - 0.5);
        float R_2 = ((((0.300000011920928955078125 + (0.5 * h)) * fast::max(_32.u_res.x, _32.u_res.y)) / _32.u_dpr) * 0.5) * (1.60000002384185791015625 - fast::min(_32.u_lines, 1.0));
        col = mix(col, _32.u_ink, float3(((step(w, 0.100000001490116119384765625 + ((0.300000011920928955078125 * h) * h)) * smoothstep(R_2, R_2 + 60.0, length(c2))) * step(0.3499999940395355224609375, h)) * fast::min(_32.u_lines * 2.0, 1.0)));
    }
    float2 param_38 = px + float2(fract(_32.u_t) * 91.0);
    float gr = hash(param_38) - 0.5;
    float _1436;
    if ((lk > 1.5) && (lk < 2.5))
    {
        float3 param_39 = col;
        _1436 = 1.2000000476837158203125 - (L(param_39) * 0.60000002384185791015625);
    }
    else
    {
        _1436 = 1.0;
    }
    col += float3((gr * _32.u_grain) * _1436);
    out.fragColor = float4(col, 1.0);
    return out;
}


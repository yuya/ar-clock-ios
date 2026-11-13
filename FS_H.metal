#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float2 u_src;
    float u_asp;
    float u_mirror;
    float2 u_wres;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

static inline __attribute__((always_inline))
float2 cover(thread float2& uv, constant Params& _27)
{
    float rs = _27.u_src.x / _27.u_src.y;
    float2 _46;
    if (_27.u_asp > rs)
    {
        _46 = float2(1.0, rs / _27.u_asp);
    }
    else
    {
        _46 = float2(_27.u_asp / rs, 1.0);
    }
    float2 s = _46;
    uv = ((uv - float2(0.5)) * s) + float2(0.5);
    if (_27.u_mirror > 0.5)
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
float2 pack(thread float& v)
{
    v = fast::clamp(v, 0.0, 0.99989998340606689453125) * 255.0;
    return float2(floor(v) / 255.0, fract(v));
}

fragment main0_out main0(constant Params& _27 [[buffer(0)]], texture2d<float> u_tex [[texture(0)]], sampler u_texSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = gl_FragCoord.xy / _27.u_wres;
    float a = 0.0;
    float b = 0.0;
    float wa = 0.0;
    float wb = 0.0;
    for (int i = -4; i <= 4; i++)
    {
        float x = float(i);
        float2 param = uv + float2(x / _27.u_wres.x, 0.0);
        float2 _148 = cover(param, _27);
        float3 param_1 = u_tex.sample(u_texSmplr, _148).xyz;
        float l = L(param_1);
        float w1 = exp(((-x) * x) / 1.62000000476837158203125);
        float w2 = exp(((-x) * x) / 5.11999988555908203125);
        a += (l * w1);
        wa += w1;
        b += (l * w2);
        wb += w2;
    }
    float param_2 = a / wa;
    float2 _193 = pack(param_2);
    float param_3 = b / wb;
    float2 _198 = pack(param_3);
    out.fragColor = float4(_193, _198);
    return out;
}


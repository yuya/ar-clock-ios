#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float2 u_wres;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

fragment main0_out main0(constant Params& _17 [[buffer(0)]], texture2d<float> u_a [[texture(0)]], sampler u_aSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = gl_FragCoord.xy / _17.u_wres;
    float a = 0.0;
    float b = 0.0;
    float wa = 0.0;
    float wb = 0.0;
    for (int i = -4; i <= 4; i++)
    {
        float x = float(i);
        float4 t = u_a.sample(u_aSmplr, (uv + float2(0.0, x / _17.u_wres.y)));
        float w1 = exp(((-x) * x) / 1.62000000476837158203125);
        float w2 = exp(((-x) * x) / 5.11999988555908203125);
        a += ((t.x + (t.y / 255.0)) * w1);
        wa += w1;
        b += ((t.z + (t.w / 255.0)) * w2);
        wb += w2;
    }
    a /= wa;
    b /= wb;
    out.fragColor = float4(fast::clamp(0.5 + ((a - b) * 12.0), 0.0, 1.0), b, a, 1.0);
    return out;
}


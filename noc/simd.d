module noc.simd;

// TODO(stefanos): Consider making backwards versions

// NOTE - IMPORTANT(stefanos): It's important to use
// DMD's load/storeUnaligned when compiling with DMD (i.e. core.simd versions)
// for correct code generation.
import core.simd: float4, int4;
version (LDC)
{
    import ldc.simd: loadUnaligned, storeUnaligned;
}
else
version (DigitalMars)
{
    import core.simd: void16, loadUnaligned, storeUnaligned;
}
else
{
    static assert(0, "Version not supported");
}

// TODO(stefanos): Is there a way to make them @safe?
// (The problem is that for LDC, they could take int* or float* pointers
// but the cast to void16 for DMD is necessary anyway).

/// Integer ///

void store32i_sse(void *dest, int4 reg)
{
    version (LDC)
    {
        storeUnaligned!int4(reg, cast(int*)dest);
        storeUnaligned!int4(reg, cast(int*)(dest+0x10));
    }
    else
    {
        storeUnaligned(cast(void16*)dest, reg);
        storeUnaligned(cast(void16*)(dest+0x10), reg);
    }
}

void store16i_sse(void *dest, int4 reg)
{
    version (LDC)
    {
        storeUnaligned!int4(reg, cast(int*)dest);
    }
    else
    {
        storeUnaligned(cast(void16*)dest, reg);
    }
}

// TODO(stefanos): Can we broadcast an int in a float4? That would be useful
// because then we would use only the float versions.
void broadcast_int(ref int4 xmm, int v)
{
    xmm[0] = v;
    xmm[1] = v;
    xmm[2] = v;
    xmm[3] = v;
}

/// FLOAT ///

void store16f_sse(void *dest, float4 reg)
{
    version (LDC)
    {
        storeUnaligned!float4(reg, cast(float*)dest);
    }
    else
    {
        storeUnaligned(cast(void16*)dest, reg);
    }
}

float4 load16f_sse(const(void) *src)
{
    version (LDC)
    {
        return loadUnaligned!(float4)(cast(const(float) *)src);
    }
    else
    {
        return loadUnaligned(cast(void16*)src);
    }
}

/*
void _store128fp_sse(void *d, const(void) *s)
{
    _mm_prefetch!(0)(s+0x1a0);
    _mm_prefetch!(0)(s+0x280);
    store128f_sse(d, s);
}
*/

void lstore128f_sse(void *d, const(void) *s)
{
    float4 xmm0 = load16f_sse(cast(const float*)s);
    float4 xmm1 = load16f_sse(cast(const float*)(s+16));
    float4 xmm2 = load16f_sse(cast(const float*)(s+32));
    float4 xmm3 = load16f_sse(cast(const float*)(s+48));
    float4 xmm4 = load16f_sse(cast(const float*)(s+64));
    float4 xmm5 = load16f_sse(cast(const float*)(s+80));
    float4 xmm6 = load16f_sse(cast(const float*)(s+96));
    float4 xmm7 = load16f_sse(cast(const float*)(s+112));

    store16f_sse(cast(float*)d, xmm0);
    store16f_sse(cast(float*)(d+16), xmm1);
    store16f_sse(cast(float*)(d+32), xmm2);
    store16f_sse(cast(float*)(d+48), xmm3);
    store16f_sse(cast(float*)(d+64), xmm4);
    store16f_sse(cast(float*)(d+80), xmm5);
    store16f_sse(cast(float*)(d+96), xmm6);
    store16f_sse(cast(float*)(d+112), xmm7);
}

void lstore64f_sse(void *d, const(void) *s)
{
    float4 xmm0 = load16f_sse(cast(const float*)s);
    float4 xmm1 = load16f_sse(cast(const float*)(s+16));
    float4 xmm2 = load16f_sse(cast(const float*)(s+32));
    float4 xmm3 = load16f_sse(cast(const float*)(s+48));

    store16f_sse(cast(float*)d, xmm0);
    store16f_sse(cast(float*)(d+16), xmm1);
    store16f_sse(cast(float*)(d+32), xmm2);
    store16f_sse(cast(float*)(d+48), xmm3);
}

void lstore32f_sse(void *d, const(void) *s)
{
    float4 xmm0 = load16f_sse(cast(const float*)s);
    float4 xmm1 = load16f_sse(cast(const float*)(s+16));
    store16f_sse(cast(float*)d, xmm0);
    store16f_sse(cast(float*)(d+16), xmm1);
}

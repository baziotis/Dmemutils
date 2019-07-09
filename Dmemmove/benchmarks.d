/*
Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

import std.datetime.stopwatch;
import Dmemmove: Dmemmove;
import S_struct;
import std.random;
import std.stdio;
import core.stdc.string;
import std.traits;

static string genTests()
{
    import std.conv : text;
    string res;
    foreach (i; 1..100)
    {
        res ~= "test!("~text(i)~");\n";
    }
    return res;
}

static string getStaticTests()
{
    import std.conv : text;
    string res;
    foreach (i; 1..65)
    {
        res ~= "testStaticType!(S!"~text(i)~");\n";
    }
    return res;
}

struct S(size_t Size)
{
    ubyte[Size] x;
}

void main(string[] args)
{
    // For performing benchmarks
    writeln("size(bytes) Cmemmove(GB/s) Dmemmove(GB/s)");
    mixin(getStaticTests());
    mixin(genTests());
    test!(500);
    test!(700);
    test!(3434);
    test!(7128);
    test!(13908);
    test!(16343);
    test!(27897);
    test!(32344);
    test!(46830);

    test!(512);
    test!(1024);
    test!(2048);
    test!(4096);
    test!(16368);
    test!(32768);
    test!(65536);
}

// From a very good Chandler Carruth video on benchmarking: https://www.youtube.com/watch?v=nXaxk27zwlk
void escape(void* p)
{
    version(LDC)
    {
        import ldc.llvmasm;
        __asm("", "r,~{memory}", p);
    }
    version(GNU)
    {
        asm { "" : : "g" p : "memory"; }
    }
}

void Cmemmove(ref ubyte[] dst, const ref ubyte[] src)
{
    import core.stdc.string: memmove;
    assert(dst.length == src.length);
    pragma(inline, true)
    memmove(dst.ptr, src.ptr, dst.length);
}

void Cmemmove(T)(T *dst, const T *src)
{
    import core.stdc.string: memmove;
    pragma(inline, true)
    memmove(dst, src, T.sizeof);
}

Duration benchmark(alias f)(ref ubyte[] dst, const ref ubyte[] src, ulong *bytesCopied)
{
    assert(dst.length == src.length);
    size_t iterations = 2^^20 / dst.length;
    Duration result;

    auto swt = StopWatch(AutoStart.yes);
    swt.reset();
    while(swt.peek().total!"msecs" < 5)
    {
        auto sw = StopWatch(AutoStart.yes);
        sw.reset();
        foreach (_; 0 .. iterations)
        {
            escape(cast(void*)dst.ptr);   // So optimizer doesn't remove code
            f(dst, src);
            escape(cast(void*)src.ptr);   // So optimizer doesn't remove code
        }
        result += sw.peek();
        *bytesCopied += (iterations * dst.length);
    }

    return result;
}

Duration benchmark(T, alias f)(ref T dst, const ref T src, ulong *bytesCopied)
{
    size_t iterations = 2^^20 / T.sizeof;
    Duration result;

    auto swt = StopWatch(AutoStart.yes);
    swt.reset();
    while(swt.peek().total!"msecs" < 5)
    {
        auto sw = StopWatch(AutoStart.yes);
        sw.reset();
        foreach (_; 0 .. iterations)
        {
            escape(cast(void*)&dst);   // So optimizer doesn't remove code
            f(&dst, &src);
            escape(cast(void*)&src);   // So optimizer doesn't remove code
        }
        result += sw.peek();
        *bytesCopied += (iterations * T.sizeof);
    }

    return result;
}


pragma(inline, false)
void initStatic(T)(T *v)
{
    static if (is(T == float))
    {
        *v = uniform(0.0f, 9_999_999.0f);
    }
    else static if (is(T == double))
    {
        *v = uniform(0.0, 9_999_999.0);
    }
    else static if (is(T == real))
    {
        *v = uniform(0.0L, 9_999_999.0L);
    }
    else
    {
        auto m = (cast(ubyte*)v)[0 .. T.sizeof];
        for(int i = 0; i < m.length; i++)
        {
            m[i] = uniform!byte;
        }
    }
}

pragma(inline, false)
void testStaticType(T)()
{
    T d, s;
    initStatic!(T)(&d);
    initStatic!(T)(&s);

    ulong bytesCopied1;
    ulong bytesCopied2;
    immutable d1 = benchmark!(T, Cmemmove)(d, s, &bytesCopied1);

    immutable d2 = benchmark!(T, Dmemmove)(d, s, &bytesCopied2);

    auto secs1 = (cast(double)(d1.total!"nsecs")) / 1_000_000_000.0;
    auto secs2 = (cast(double)(d2.total!"nsecs")) / 1_000_000_000.0;
    auto GB1 = (cast(double)bytesCopied1) / 1_000_000_000.0;
    auto GB2 = (cast(double)bytesCopied2) / 1_000_000_000.0;
    auto GBperSec1 = GB1 / secs1;
    auto GBperSec2 = GB2 / secs2;
    writeln(T.sizeof, " ", GBperSec1, " ", GBperSec2, " - Static type: ", T.stringof);
}



void init(ref ubyte[] v)
{
    for(int i = 0; i < v.length; i++)
    {
        v[i] = uniform!ubyte;
    }
}


void test(size_t n)()
{
    ubyte[100000] buf1;
    ubyte[100000] buf2;

    // TODO(stefanos): This should be a static foreach
    //for (int j = 0; j < 3; ++j)
    int j = 1;
    {
        double TotalGBperSec1 = 0.0;
        double TotalGBperSec2 = 0.0;
        enum alignments = 32;

        foreach(i; 0..alignments)
        {
            ubyte[] p = buf1[i..i+n];
            ubyte[] q;

            // Relatively aligned
            if (j == 0)
            {
                q = buf2[i..i+n];
            }
            else {
                // src forward
                if (j == 1)
                {
                    q = buf1[i+n/2..i+n/2+n];
                    // dst forward
                }
                else
                {
                    q = p;
                    p = buf1[i+n/2..i+n/2+n];
                }
            }

            ulong bytesCopied1;
            ulong bytesCopied2;
            init(q);
            init(p);
            immutable d1 = benchmark!(Cmemmove)(p, q, &bytesCopied1);

            init(q);
            init(p);
            immutable d2 = benchmark!(Dmemmove)(p, q, &bytesCopied2);

            auto secs1 = (cast(double)(d1.total!"nsecs")) / 1_000_000_000.0;
            auto secs2 = (cast(double)(d2.total!"nsecs")) / 1_000_000_000.0;
            auto GB1 = (cast(double)bytesCopied1) / 1_000_000_000.0;
            auto GB2 = (cast(double)bytesCopied2) / 1_000_000_000.0;
            auto GBperSec1 = GB1 / secs1;
            auto GBperSec2 = GB2 / secs2;
            TotalGBperSec1 += GBperSec1;
            TotalGBperSec2 += GBperSec2;
        }
        write(n, " ", TotalGBperSec1 / alignments, " ", TotalGBperSec2 / alignments);
        if (j == 0) {
            writeln(" - Relatively aligned");
        } else if (j == 1) {
            writeln(" - src forward");
        } else {
            writeln(" - dst forward");
        }
    }
}

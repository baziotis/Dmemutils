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

import Dmemset: Dmemset;
import std.stdio;

struct S(size_t Size)
{
    ubyte[Size] x;
}

static string genTests()
{
    string res;
    import std.conv : text;
    // NOTE(stefanos): static foreach would be ideal here but GDC doesn't support it.
    // I could not avoid GDC trying (and failing) to compile the static foreach
    // even with versioning.
    foreach(i; 1..33)
    {
        res ~= "testDynamicArray!(ubyte)(5, "~text(i)~");
                testStaticArray!(ubyte, "~text(i)~")(5);";
    }
    return res;
}

void main(string[] args)
{
    testStaticArray!(ubyte, 32)(5);
    testStaticType!(byte)(5);
    testStaticType!(ubyte)(5);
    testStaticType!(short)(5);
    testStaticType!(ushort)(5);
    testStaticType!(int)(5);
    testStaticType!(uint)(5);
    testStaticType!(long)(5);
    testStaticType!(ulong)(5);
    testStaticType!(float)(5);
    testStaticType!(double)(5);
    testStaticType!(real)(5);
    testDynamicArray!(ubyte)(5, 3);
    mixin(genTests());
    testDynamicArray!(ubyte)(5, 32);
    testStaticArray!(ubyte, 32)(5);
    testDynamicArray!(ubyte)(5, 100);
    testStaticArray!(ubyte, 100)(5);
    testDynamicArray!(ubyte)(5, 500);
    testStaticArray!(ubyte, 500)(5);
    testDynamicArray!(ubyte)(5, 700);
    testStaticArray!(ubyte, 700)(5);
    testDynamicArray!(ubyte)(5, 3434);
    testStaticArray!(ubyte, 3434)(5);
    testDynamicArray!(ubyte)(5, 7128);
    testStaticArray!(ubyte, 7128)(5);
    testDynamicArray!(ubyte)(5, 13908);
    testStaticArray!(ubyte, 13908)(5);
    testDynamicArray!(ubyte)(5, 16343);
    testStaticArray!(ubyte, 16343)(5);
    testDynamicArray!(ubyte)(5, 27897);
    testStaticArray!(ubyte, 27897)(5);
    testDynamicArray!(ubyte)(5, 32344);
    testStaticArray!(ubyte, 32344)(5);
    testDynamicArray!(ubyte)(5, 46830);
    testStaticArray!(ubyte, 46830)(5);
    testDynamicArray!(ubyte)(5, 64349);
    testStaticArray!(ubyte, 64349)(5);

    testStaticType!(S!20)(5);
    testStaticType!(S!200)(5);
    testStaticType!(S!2000)(5);
}

void verifyArray(T)(int j, const ref T[] a, const ubyte v)
{
    const ubyte *p = cast(const ubyte *) a.ptr;
    for(size_t i = 0; i < a.length * T.sizeof; i++)
    {
        assert(p[i] == v);
    }
}

void verifyStaticType(T)(const ref T t, const ubyte v)
{
    const ubyte *p = cast(const ubyte *) &t;
    for(size_t i = 0; i < T.sizeof; i++)
    {
        assert(p[i] == v);
    }
}

// NOTE(stefanos): Escaping the pointers is not needed, the compiler doesn't optimize it away.
// My best guess is that this is because of the verification (i.e. if the operation is not done,
// an assert will fire and does not satisfy correctness).

void testDynamicArray(T)(const ubyte v, size_t n)
{
    writeln("Test dynamic array (type, size): (", T.stringof, ", ", n, ")");
    T[] buf;
    buf.length = n + 32;

    enum alignments = 32;
    size_t len = n;

    foreach(i; 0..alignments)
    {
        auto d = buf[i..i+n];

        Dmemset(d, v);
        verifyArray(i, d, v);
    }
}

void testStaticArray(T, size_t n)(const ubyte v)
{
    writeln("Test static array (type, size): (", T.stringof, ", ", n, ")");
    T[n + 32] buf;

    enum alignments = 32;
    size_t len = n;

    foreach(i; 0..alignments)
    {
        auto d = buf[i..i+n];

        Dmemset(d, v);
        verifyArray(i, d, v);
    }
}

void testStaticType(T)(const ubyte v) {
    writeln("Test static type: ", T.stringof);
    T t;
    Dmemset(t, v);
    verifyStaticType(t, v);
}

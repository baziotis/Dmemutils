# Dmemcmp

This is part of my [Google Summer of Code project](https://summerofcode.withgoogle.com/organizations/6103365956665344/#5475582328963072), _Independency of D from the C Standard Library_.

It is a public repository for the work on the `memcmp()` replacement.

## Compile and Run

The `run.d` takes 2 command-line options. One is what suite to run and the other is the compiler of choice (currently
only DMD and LDC).

`rdmd run tests|benchmarks ldc|gdc|dmd`

_Note_: Currently only the 'tests' option is supported.

### Run the test suite
With the option `tests`. This suites verifies that `Dmemcmp` works correctly.

Refer to the `run.d` file for more info and `tests.d` to see the test suite code.

### Run the benchmark suite
With the option `benchmarks`. This suite benchmarks `Dmemcmp` against `memcmp()` of the C Standard Library.

Refer to the `run.d` file for more info and `benchmarks.d` to see the benchmark suite code.

## Compiler choice
You can choose to compile with LDC or DMD.

### LDC
This will compile with `-O3`.

### DMD
This will compile with `rdmd` and `-O -inline`.

### Contact Info

E-mail: sdi1600105@di.uoa.gr

If you are involved in D, you can also ping me on Slack (Stefanos Baziotis), or post in the dlang forum thread above.

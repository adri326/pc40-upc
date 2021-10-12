# PC40 UPC Project

This project is for the PC40 class ("Parallelized computing") and is written in [Unified Parallel C](https://en.wikipedia.org/wiki/Unified_Parallel_C).

## Compilation and installation

To compile and use it, you will need to install `upc-runtime`.
You can [follow Berkeley Lab's instructions](https://upc.lbl.gov/) or [use my own install scripts](https://gist.github.com/adri326/8566e4fedd209b7a05647ee0d016a2e6) to get it.
If you wish to compile the code offline, you will need to also install `upc-translator`, for which you can follow [my instructions](https://gist.github.com/adri326/8566e4fedd209b7a05647ee0d016a2e6) or [head to the official repository](https://bitbucket.org/berkeleylab/upc-translator).

Once you have a way to compile `upc`, you will also need `GNU Make` and `git`.

```sh
# Clone the repository
git clone https://github.com/adri326/pc40-upc
cd pc40-upc

# Build and hope for the best
make -j
```

If you only have `gcc`, then you will need to replace the last line by `make -j CC=/usr/bin/gcc`.
Additionally, if your C compiler does not support `c99` by default, you will need to add `CFLAGS="-std=c99"` as a parameter to make.

All of the executables will be built and exported to the `build/` directory.
Refer to the [report](./report.tex) for information on what each do.

To run the executables exported by `upcc`, you will need to run `upcrun -q build/EXECUTABLE`.

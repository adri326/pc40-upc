#include <upc_relaxed.h>
#include <upc_collective.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <stdbool.h>
#include <stdlib.h>
#include "settings.h"

shared double dTmax_g;

void init(shared[] double* grid, shared[] double* new_grid, size_t n) {
    for (size_t i = 0; i < n+2; i++) {
        for (size_t j = 0; j < n+2; j++) {
            grid[i * (n+2) + j] = 0.0;
            new_grid[i * (n+2) + j] = 0.0;
        }
    }

    for (size_t j = 1; j < n+1; j++) {
        grid[j] = 1.0;
        new_grid[j] = 1.0;
    }
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        if (MYTHREAD == 0) fprintf(stderr, "Error: expected two arguments, got %d\n", argc);
        exit(1);
    }

    size_t n = atoi(argv[1]);

    shared[] double* dTmax = upc_all_alloc(1, THREADS);
    shared[] double* ptr = upc_all_alloc((n+2) * (n+2) / THREADS, (n+2) * (n+2));
    shared[] double* new_ptr = upc_all_alloc((n+2) * (n+2) / THREADS, (n+2) * (n+2));

    // Handy way to access ptr from now on
    #define ptr_get(x, y) ptr[(x) * (n+2) + (y)]

    if (MYTHREAD == 0) {
        init(ptr, new_ptr, n);
    }

    upc_barrier;
    bool finished = false;
    int n_iter = 0;

    clock_t begin = clock();
    do {
        dTmax[MYTHREAD] = 0.0;
        size_t i = (n+2) * MYTHREAD / THREADS;
        if (i == 0) i = 1;
        size_t imax = (n+2) * (MYTHREAD + 1) / THREADS;
        if (imax > n+1) imax = n+1;

        for (; i < imax; i++) {
            for (size_t j = 1; j <= n; j++) {
                double T = 0.25 * (ptr_get(i+1, j) + ptr_get(i-1, j) + ptr_get(i, j-1) + ptr_get(i, j+1));
                double dT = fabs(T - ptr_get(i, j));
                new_ptr[i * (n+2) + j] = T;
                if (dTmax[MYTHREAD] < dT) dTmax[MYTHREAD] = dT;
            }
        }

        upc_all_reduceD(&dTmax_g, dTmax, UPC_MAX, THREADS, 1, NULL, UPC_IN_ALLSYNC | UPC_OUT_ALLSYNC);

        if (dTmax_g < EPSILON) {
            finished = true;
        } else {
            shared[] double* tmp = ptr;
            ptr = new_ptr;
            new_ptr = tmp;
        }
        n_iter++;
        // upc_barrier;
    } while (!finished);
    clock_t end = clock();

    if (MYTHREAD == 0) {
        double seconds = (double)(end - begin) / CLOCKS_PER_SEC;
        printf("%d iterations in %.3lf sec\n", n_iter, seconds);
        printf("Took %.3lf ms/iter\n", seconds * 1000.0 / n_iter);
    }
}

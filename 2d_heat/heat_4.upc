#include <upc_relaxed.h>
#include <bupc_collectivev.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <stdbool.h>
#include "settings.h"

#if ((N+2) % THREADS) != 0
#error N+2 must be divisible by THREADS
#endif

// Change blocksize to (N+2)^2 / THREADS?
#define BLOCKSIZE ((N+2) * (N+2) / THREADS)
// #define BLOCKSIZE ((N+2) * THREADS)
#define LOCALWIDTH ((N+2) / THREADS)
#define LOCALSIZE (LOCALWIDTH * sizeof(double) * (N+2))

shared[BLOCKSIZE] double grid[N+2][N+2];
shared[BLOCKSIZE] double new_grid[N+2][N+2];
shared double dTmax[THREADS];

void init() {
    for (size_t j = 1; j < N+1; j++) {
        grid[0][j] = 1.0;
        new_grid[0][j] = 1.0;
    }
}

int main() {
    shared[BLOCKSIZE] double (*ptr)[N+2] = grid;
    shared[BLOCKSIZE] double (*new_ptr)[N+2] = new_grid;
    double (*ptr_priv)[N+2] = malloc(LOCALSIZE);
    double (*new_ptr_priv)[N+2] = malloc(LOCALSIZE);

    if (MYTHREAD == 0) {
        init();
    }

    upc_barrier;

    upc_memget(ptr_priv, &grid[LOCALWIDTH * MYTHREAD], LOCALSIZE);
    upc_memget(new_ptr_priv, &new_grid[LOCALWIDTH * MYTHREAD], LOCALSIZE);

    bool finished = false;
    int n_iter = 0;

    clock_t begin = clock();
    do {
        double dTmax = 0.0;

        size_t o = LOCALWIDTH * MYTHREAD;
        size_t i = 0;

        // Local block start
        if (i + o > 0) {
            for (size_t j = 1; j <= N; j++) {
                double T = 0.25 * (ptr_priv[i+1][j] + ptr[o+i-1][j] + ptr_priv[i][j-1] + ptr_priv[i][j+1]);
                // printf("%zu+%zu %zu: %lf\n", o, i, j, T);
                double dT = fabs(T - ptr_priv[i][j]);
                new_ptr_priv[i][j] = T;
                if (dTmax < dT) dTmax = dT;
            }
        }

        // Local block middle
        for (i += 1; i < LOCALWIDTH - 1; i++) {
            for (size_t j = 1; j <= N; j++) {
                double T = 0.25 * (ptr_priv[i+1][j] + ptr_priv[i-1][j] + ptr_priv[i][j-1] + ptr_priv[i][j+1]);
                // printf("%zu+%zu %zu: %lf\n", o, i, j, T);
                double dT = fabs(T - ptr_priv[i][j]);
                new_ptr_priv[i][j] = T;
                if (dTmax < dT) dTmax = dT;
            }
        }

        // Local block end
        if (i + o < N + 1) {
            for (size_t j = 1; j <= N; j++) {
                double T = 0.25 * (ptr[o+i+1][j] + ptr_priv[i-1][j] + ptr_priv[i][j-1] + ptr_priv[i][j+1]);
                // printf("%zu+%zu %zu: %lf\n", o, i, j, T);
                double dT = fabs(T - ptr_priv[i][j]);
                new_ptr_priv[i][j] = T;
                if (dTmax < dT) dTmax = dT;
            }
        }

        // printf("%d: %lf\n", MYTHREAD, dTmax);

        // upc_barrier;

        // Update ptr_priv and new_ptr_priv
        upc_memput(&new_ptr[LOCALWIDTH * MYTHREAD], new_ptr_priv, LOCALSIZE);

        // printf("%lf %lf\n", new_ptr_priv[1][1], new_ptr[o+1][1]);

        // Implicit barrier here:
        double dTmax_g = bupc_allv_reduce_all(double, dTmax, UPC_MAX);

        if (dTmax_g < EPSILON) {
            finished = true;
        } else {
            // Swap ptr and new_ptr
            shared[BLOCKSIZE] double (*ptr_tmp)[N+2] = ptr;
            ptr = new_ptr;
            new_ptr = ptr_tmp;

            double (*ptr_tmp_priv)[N+2] = ptr_priv;
            ptr_priv = new_ptr_priv;
            new_ptr_priv = ptr_tmp_priv;
        }
        n_iter++;
        // upc_barrier;
    } while (!finished);
    clock_t end = clock();

    if (MYTHREAD == 0) {
        double seconds = (double)(end - begin) / CLOCKS_PER_SEC;
        printf("%d iterations in %.3lf sec\n", n_iter, seconds);
    }
}

#include <upc_relaxed.h>
#include <bupc_collectivev.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <stdbool.h>
#include "settings.h"

#define BLOCKSIZE ((N+2) * (N+2) / THREADS)

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

    if (MYTHREAD == 0) {
        init();
    }

    upc_barrier;
    bool finished = false;
    int n_iter = 0;

    clock_t begin = clock();
    do {
        double dTmax = 0.0;

        if (n_iter % 2 == 0) {
            ptr = grid;
            new_ptr = new_grid;
        } else {
            ptr = new_grid;
            new_ptr = grid;
        }

        for (size_t i = 1; i <= N; i++) {
            upc_forall (size_t j = 1; j <= N; j++; &grid[i][j]) {
                double T = 0.25 * (ptr[i+1][j] + ptr[i-1][j] + ptr[i][j-1] + ptr[i][j+1]);
                double dT = fabs(T - ptr[i][j]);
                new_ptr[i][j] = T;
                if (dTmax < dT) dTmax = dT;
            }
        }

        // printf("%d: %lf\n", MYTHREAD, dTmax);

        double dTmax_g = bupc_allv_reduce_all(double, dTmax, UPC_MAX);

        if (dTmax_g < EPSILON) {
            finished = true;
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

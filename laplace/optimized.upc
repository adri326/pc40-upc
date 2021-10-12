#include <upc.h>
#include <bupc_collectivev.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>
#include "settings.h"

#define LEN DESIRED_LEN // = TOTALSIZE * THREADS
#define MAX_ITER ITERATIONS

void init();
void iteration();
void copy_array();

shared[BLOCKSIZE] double x_new[LEN];
shared[BLOCKSIZE] double x[LEN];
shared[BLOCKSIZE] double b[LEN];
shared double diff[THREADS];
// shared double diffmax;

int main() {
    init();

    size_t iter = 0;

    while (true) {
        diff[MYTHREAD] = 0;

        iteration();

        double my_diff = diff[MYTHREAD];
        double diffmax = bupc_allv_reduce(double, my_diff, -1, UPC_MAX);
        // Implied upc_barrier;

        if (diffmax <= EPSILON) break;
        if (++iter > MAX_ITER) break;

        copy_array();
    }

    // upc_lock_free(diffmax_lock);


    if (MYTHREAD == 0) {
        double mean_squared = 0.0;
        if (DISPLAY) {
            printf("| b      | x      | x_new  |\n");
            printf("| :----- | :----- | :----- |\n");
            for (size_t i = 0; i < LEN; i++) {
                printf("| %1.4lf | %1.4lf | %1.4lf |\n", b[i], x[i], x_new[i]);
            }
        }
        for (size_t i = 0; i < LEN; i++) mean_squared += (x_new[i] - x[i]) * (x_new[i] - x[i]);
        printf("\nIterations: %d\n", ITERATIONS);
        printf("Mean squared difference: %1.4lf\n", mean_squared / LEN);
    }
}

void init() {
    if (MYTHREAD == 0) {
        srand(time(0));
        for (size_t i = 0; i < LEN; i++) {
            b[i] = 0;
            x[i] = (double)rand() / RAND_MAX;
            x_new[i] = 0;
        }
        for (size_t n = 0; n < THREADS; n++) {
            diff[n] = 0;
        }
        // diffmax = 0;

        x[0] = 0;
        x[LEN - 1] = 0;
        b[1] = 1;
        b[LEN - 2] = 1;
    }
    upc_barrier;
}

void handle_diff(double d) {
    if (d < 0.0) d = -d;
    if (diff[MYTHREAD] < d) diff[MYTHREAD] = d;
}

void iteration() {
    upc_forall (size_t i = 1; i < LEN - 1; i++; &x_new[i]) {
        x_new[i] = 0.5 * (x[i-1] + x[i+1] + b[i]);
        handle_diff(x_new[i] - x[i]);
    }

    // Border values are left null
    // if (MYTHREAD == 0) {
    //     x_new[0] = x[0];
    //     handle_diff(x_new[0] - x[0]);
    // }
    // if (MYTHREAD == THREADS - 1) {
    //     x_new[LEN - 1] = x[LEN - 1];
    //     handle_diff(x_new[LEN - 1] - x[LEN - 1]);
    // }

    // upc_barrier;
}

void copy_array() {
    upc_forall (size_t i = 0; i < LEN; i++; &x_new[i]) {
        x[i] = x_new[i];
    }

    upc_barrier;
}

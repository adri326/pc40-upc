#include <upc_relaxed.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "settings.h"

#define LEN DESIRED_LEN

void init();
void iteration();
void copy_array();

shared double x_new[LEN];
shared double x[LEN];
shared double b[LEN];

int main() {
    init();

    clock_t begin = clock();
    for (size_t n = 0; n < ITERATIONS; n++) {
        iteration();
        if (n != ITERATIONS - 1) copy_array();
    }
    clock_t end = clock();

    if (MYTHREAD == 0) {
        double diff = (double)(end - begin) / CLOCKS_PER_SEC / ITERATIONS;
        double mean_squared = 0.0;
        if (DISPLAY) {
            printf("| b      | x      | x_new  | diff    |\n");
            printf("| :----- | :----- | :----- | :------ |\n");
            for (size_t i = 0; i < LEN; i++) {
                printf("| %1.4lf | %1.4lf | %1.4lf | % 1.4lf |\n", b[i], x[i], x_new[i], x_new[i] - x[i]);
            }
        }
        for (size_t i = 0; i < LEN; i++) mean_squared += (x_new[i] - x[i]) * (x_new[i] - x[i]);
        printf("\nIterations: %d\n", ITERATIONS);
        printf("Mean squared difference: %1.4lf\n", mean_squared / LEN);
        printf("Took %.2lfms/iter!\n", diff * 1000);
    }
}

void init() {
    if (MYTHREAD == 0) {
        srand(time(0));
        for (size_t i = 0; i < LEN; i++) {
            b[i] = (double)rand() / RAND_MAX;
            x[i] = (double)rand() / RAND_MAX;
            x_new[i] = 0;
        }
    }
    upc_barrier;
}

void iteration() {
    size_t i = MYTHREAD;
    if (MYTHREAD == 0) {
        i += THREADS;
        x_new[0] = x[0];
    }

    for (; i < LEN - 1; i += THREADS) {
        x_new[i] = 0.5 * (x[i-1] + x[i+1] + b[i]);
    }

    if (MYTHREAD == THREADS - 1) x_new[LEN - 1] = x[LEN - 1];

    upc_barrier;
}

void copy_array() {
    for (size_t i = MYTHREAD; i < LEN; i += THREADS) {
        x[i] = x_new[i];
    }
    upc_barrier;
}

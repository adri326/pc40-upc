#include <stdio.h>
#include <math.h>
#include <sys/time.h>
#include <stdbool.h>
#include "settings.h"

double grid[N+2][N+2], new_grid[N+2][N+2];

void initialize(void) {
    int j;

    /* Heat one side of the solid */
    for (j=1; j<N+1; j++) {
        grid[0][j] = 1.0;
        new_grid[0][j] = 1.0;
    }
}

int main(void) {
    struct timeval ts_start, ts_end;
    double dTmax, dT, time;
    int i, j, k, l;
    bool finished = false;
    double T;
    int n_iter = 0;

    initialize();

    /* Set the precision wanted */
    finished = 0;

    /* and start the timed section */
    gettimeofday(&ts_start, NULL);

    do {
        dTmax = 0.0;
        for (i=1; i<N+1; i++) {
            for (j=1; j<N+1; j++) {
                T = 0.25 *
                    (grid[i+1][j] + grid[i-1][j] +
                     grid[i][j-1] + grid[i][j+1]); /* stencil */
                dT = T - grid[i][j]; /* local variation */
                new_grid[i][j] = T;
                if (dTmax < fabs(dT)) dTmax = fabs(dT); /* max variation in this iteration */
            }
        }
        if (dTmax < EPSILON) { // is the precision reached good enough ?
            finished = true;
        } else { // It isn't: preparing for a new iteration
            for (k=0; k<N+2; k++) {
                for (l=0; l<N+2; l++) {
                    grid[k][l] = new_grid[k][l];
                }
            }
        }
        n_iter++;
    } while (!finished);

    gettimeofday(&ts_end, NULL); /* end the timed section */

    /* compute the execution time */
    time = ts_end.tv_sec + (ts_end.tv_usec / 1000000.0);
    time -= ts_start.tv_sec + (ts_start.tv_usec / 1000000.0);

    printf("%d iterations in %.3lf sec\n", n_iter, time);
    printf("Took %.3lf ms/iter\n", time * 1000.0 / n_iter);

    return 0;
}

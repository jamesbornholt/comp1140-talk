#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

int max1(int x, int y) {
    if (x > y)
        return x;
    else
        return y;
}

int max2(int x, int y) {
    int r;
    asm( "movl %1, %%edx;"
         "subl %2, %2;"
         "sbbl %%ecx, %%ecx;"
         "xorl %2, %%edx;"
         "andl %%edx, %%ecx;"
         "xorl %1, %%ecx;"
         "movl %%ecx, %0"
        : "=r" (r)
        : "r" (x), "r" (y)
        : "%edx", "%ecx");
    return r;
}

int main(int argc, char **argv) {
    int N = 100000000;
    if (argc > 1)
        N = atoi(argv[1]);

    int *args = calloc(2*N, sizeof(int));
    for (int i = 0; i < 2*N; i++)
        args[i] = rand();

    struct timeval tv;
    long t1, t2, t3;
    int count = 1;

    gettimeofday(&tv, NULL);
    t1 = ((unsigned long long)tv.tv_sec * 1000000) + tv.tv_usec;

    for (int i = 0; i < 2*N; i+=2)
        count &= max1(args[i], args[i+1]);

    gettimeofday(&tv, NULL);
    t2 = ((unsigned long long)tv.tv_sec * 1000000) + tv.tv_usec;

    for (int i = 0; i < 2*N; i+=2)
        count &= max2(args[i], args[i+1]);

    gettimeofday(&tv, NULL);
    t3 = ((unsigned long long)tv.tv_sec * 1000000) + tv.tv_usec;

    printf("N: %d\n", count + N);
    printf("with `if`: %.3fs\n", (t2 - t1)/1000000.0);
    printf("  no `if`: %.3fs\n", (t3 - t2)/1000000.0);
}


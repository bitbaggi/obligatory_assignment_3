//
// Copyright (c) 2026 Pascal Keßler - All rights reserved.
//
#include <stdio.h>
#include <stdlib.h>

#include "graphhelper.h"

void read_graph(const char* filename, struct Edge** edges, int* n, int* e)
{
    FILE* fptr = fopen(filename, "r");
    fscanf(fptr, "%d", n);
    fscanf(fptr, "%d", e);
    *edges = (Edge*)malloc(*e * sizeof(struct Edge));
    for (int i = 0; i < *e; i++)
    {
        struct Edge edge;
        fscanf(fptr, "%d", &edge.src);
        fscanf(fptr, "%d", &edge.dest);
        fscanf(fptr, "%d", &edge.weight);
        (*edges)[i] = edge;
    }
}

// compare two arrays for equality
void verify(int** bf_dist, int** fw_dist, int nodeCount)
{
    int errors = 0;
    for (int i = 0; i < nodeCount; i++)
        for (int j = 0; j < nodeCount; j++)
            if (bf_dist[i][j] != fw_dist[i][j])
            {
                printf("Error at [%d][%d]: BF=%d, FW=%d\n",
                    i, j, bf_dist[i][j], fw_dist[i][j]);
                errors++;
            }

    if (errors == 0)
        printf("Correct \n");
    else
        printf("%d errors\n", errors);
}

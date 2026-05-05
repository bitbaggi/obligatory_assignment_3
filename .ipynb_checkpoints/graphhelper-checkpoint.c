//
// Copyright (c) 2026 Pascal Keßler - All rights reserved.
//
#include <stdio.h>
#include <stdlib.h>

#include "graphhelper.h"

void read_graph(const char* filename, struct Edge** edges, int* n, int* e)
{
    printf("Start - Read file content into graph structure\n");
    FILE* fptr = fopen(filename, "r");
    if (!fptr)
    {
        printf("Tried to read %s", filename);
        perror("Error opening file");
        exit(1);
    }

    char line[256];
    do
    {
        if (!fgets(line, sizeof(line), fptr))
        {
            printf("Error reading file\n");
            exit(1);
        }
    }
    while (line[0] == '%');

    int rows, cols;
    if (sscanf(line, "%d %d", &rows, &cols) != 2)
    {
        printf("Error reading matrix size\n");
        exit(1);
    }
    *n = rows;
    *e = cols;
    *edges = (struct Edge*) malloc(*e * sizeof(struct Edge));
    if (!*edges)
    {
        printf("Memory allocation failed\n");
        exit(1);
    }

    for (int i = 0; i < *e; i++)
    {
        int u, v, w = 1;
        if (fscanf(fptr, "%d %d %d", &u, &v, &w) < 2)
        {
            printf("Error reading edge %d\n", i);
            exit(1);
        }
        (*edges)[i].src = u;
        (*edges)[i].dest = v;
        (*edges)[i].weight = w;
    }

    fclose(fptr);
    printf("End - Read file content into graph structure\n");
}

void writeResults(const int n, const int e, const double elapsedTime, const char* filename)
{
    FILE* resultFile = fopen(filename, "a");
    fprintf(resultFile, "%d  %d  %f\n", n, e, elapsedTime);
    fclose(resultFile);
}

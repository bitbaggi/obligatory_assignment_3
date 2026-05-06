//
// Copyright (c) 2026 Pascal Keßler - All rights reserved.
//

#include <stdio.h>
#include <time.h>

#include "edge.h"
#include "bellmanford.c"
#include "graphhelper.c"

int run(int argc, char* argv[], struct Edge* edges, int n, int e)
{
    printf("Start - Allocate Memory\n");
    // Allocate memory for the distance array on host machine
    const size_t size = (size_t)n * (size_t)n;
    int* dist_data = malloc(size * sizeof(int));
    int** dist = malloc(n * sizeof(int*));
    if (dist_data == NULL || dist == NULL)
    {
        printf("Problem with allocating memory\n");
        free(dist_data);
        free(dist);
        return 0;
    }
    for (int i = 0; i < n; i++)
    {
        dist[i] = dist_data + i * n;
    }
    printf("End - Allocate Memory\n");

    printf("Start - BellmanFord Algorithm\n");
    const clock_t start = clock();
    for (int i = 0; i < n; i++)
    {
        bellmanFord(dist[i], edges, i, n, e);
    }
    printf("End - BellmanFord Algorithm\n");

    const float elapsedTime = (float)(clock() - start) / (CLOCKS_PER_SEC / 1000);
    printf("Took %f ms\n", elapsedTime);

    // Verify correctness
    printf("Start - Verification\n");
    for (int src = 0; src < n; src++)
    {
        for (int i = 0; i < e; i++)
        {
            const int u = edges[i].src;
            const int v = edges[i].dest;
            if (dist[src][u] != INT_MAX &&
                dist[src][v] > dist[src][u] + edges[i].weight)
            {
                printf("Triangle inequality violated!\n");
            }
        }
    }
    printf("End - Verification\n");
    printf("Correct!\n");

    free(dist);
    free(dist_data);

    writeResults(n, e, elapsedTime, argc >= 3 ? argv[2] : "results_parallel_all.txt");
}

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        printf("Please add an argument for the graph file\n");
        return 1;
    }
    // Read in the graph file
    struct Edge* edges;
    int n, e;
    read_graph(argv[1], &edges, &n, &e);

    int runs = 0;
    if (argc == 3)
        runs = atoi(argv[2]);
    else if (argc == 4)
        runs = atoi(argv[3]);
    else runs = 3;

    for (int i = 0; i < runs; i++)
    {
        printf("# # # # # Start run %d # # # # #\n", i);
        run(argc, argv, edges, n, e);
        printf("# # # # # End run %d # # # # #\n", i);
    }

    free(edges);
    return 0;
}

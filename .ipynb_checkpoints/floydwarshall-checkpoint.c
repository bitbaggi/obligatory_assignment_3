//
// Copyright (c) 2026 Pascal Keßler - All rights reserved.
//
#include <limits.h>

#include "floydwarshall.h"

/**
 * floydWarshall algorithm to determine shortest paths to all nodes
 * -> only to verify my code and result i
 */
void floydWarshall(int** dist, const struct Edge* edges, const int nodes, const int edgeCount)
{
    for (int i = 0; i < nodes; i++)
        for (int j = 0; j < nodes; j++)
            dist[i][j] = i == j ? 0 : INT_MAX;

    for (int k = 0; k < edgeCount; k++)
        if (dist[edges[k].src][edges[k].dest] > edges[k].weight)
            dist[edges[k].src][edges[k].dest] = edges[k].weight;

    for (int k = 0; k < nodes; k++)
        for (int i = 0; i < nodes; i++)
            for (int j = 0; j < nodes; j++)
                if (dist[i][k] != INT_MAX && dist[k][j] != INT_MAX)
                    if (dist[i][j] > dist[i][k] + dist[k][j])
                        dist[i][j] = dist[i][k] + dist[k][j];
}

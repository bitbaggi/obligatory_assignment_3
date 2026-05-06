//
// Copyright (c) 2026 Pascal Keßler - All rights reserved.
//
#include <limits.h>
#include <stdio.h>

#include "bellmanford.h"

/**
 * Process one step of bellman ford, iterate once over all edges and check if there is a new/shorter path
 * @return if something changed on this step
 */
short bellmanFord_step(int* dist, const struct Edge* edges, const int edgeCount)
{
    short changed = 0;
    for (int i = 0; i < edgeCount; i++)
    {
        const struct Edge* e = edges + i;
        if (dist[e->src] != INT_MAX && dist[e->dest] > dist[e->src] + e->weight)
        {
            dist[e->dest] = dist[e->src] + e->weight;
            changed = 1;
        }
    }
    return changed;
}

/**
 * Runs bellmanford for a single source and calculates distance for all possible/reachable nodes
 */
void bellmanFord(int* dist, const struct Edge* edges, const int src, const int nodes, const int edgeCount)
{
    for (int i = 0; i < nodes; i++)
    {
        dist[i] = INT_MAX;
    }
    dist[src] = 0;

    for (int i = 0; i < nodes - 1; i++)
    {
        if (!bellmanFord_step(dist, edges, edgeCount))
            break; // if nothing changes in a step we can break the loop, bcs their could not be any change anymore
    }
    if (bellmanFord_step(dist, edges, edgeCount))
    {
        printf("There is a negative cycle\n");
        for (int i = 0; i < nodes; i++)
            printf("Node '%d' has dist '%d' to src '%d'\n", i, dist[i], src);
    }
}

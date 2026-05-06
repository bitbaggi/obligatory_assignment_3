#include <stdio.h>
#include "edge.h"
#include "graphhelper.c"
#include <sys/time.h>

__global__ void bellmanford_init(int n, int* d_dist_data){
    int src = blockIdx.x;
    int* d_dist   = d_dist_data   + src * n;

    for (int i = threadIdx.x; i < n; i += blockDim.x)
        d_dist[i]   = INT_MAX;

    d_dist[src] = 0;
}

__device__ bool bellmanford_step(int edge_count, Edge* d_edges, int* d_dist)
{
    bool changed = false;
    for (int i = 0; i < edge_count; i++)
    {
        const struct Edge* e = d_edges + i;
        if (d_dist[e->src] != INT_MAX && d_dist[e->dest] > d_dist[e->src] + e->weight)
        {
            d_dist[e->dest] = d_dist[e->src] + e->weight;
            changed = true;
        }
    }
    return changed;
}
__global__  void bellmanford_node(int n, int e, Edge* d_edges, int* d_dist_data)
{
    int src = blockIdx.x;
    int* d_dist   = d_dist_data   + src * n;
    for (int i = 0; i < n-1; i++)
       if (!bellmanford_step(e, d_edges, d_dist))
           break;
    if (bellmanford_step(e, d_edges, d_dist))
        printf("There is a negative cycle\n");
}

int run(int argc, char* argv[], struct Edge* edges, int n, int e)
{

    printf("Start - Allocate Memory\n");
    // Allocate memory for the distance array on host machine
    int* dist_data;
    cudaMallocHost((void**)&dist_data,   (size_t)n * n * sizeof(int));
    printf("End - Allocate Memory\n");

	// Meassure time with cuda
    cudaEvent_t start, stop;
    float elapsedTime;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start,0);

    // Allocate memory and copy data

    printf("Start - Copy data to device\n");
    struct Edge* d_edges;
    cudaMalloc((void **)&d_edges, (size_t)e * sizeof(struct Edge));
    cudaMemcpy(d_edges, edges, e * sizeof(struct Edge), cudaMemcpyHostToDevice);
    printf("End - Copy data to device\n");

    printf("Start - Allocate dist data on device\n");
    // Using one big array in global space to fill and copy back at the end.
    int* d_dist_data;
    cudaMalloc((void **) &d_dist_data, (size_t) n * n * sizeof(int));
    printf("End - Allocate dist data on device\n");

    printf("Start - parallel bellman ford\n");
    bellmanford_init<<<1,n>>>(n, d_dist_data);
    bellmanford_node<<<1,n>>>(n, e, d_edges, d_dist_data);
    printf("End - parallel bellman ford\n");

    printf("Start - Copy data from device\n");
    cudaMemcpy(dist_data, d_dist_data, n*n*sizeof(int),cudaMemcpyDeviceToHost);
    printf("End - Copy data from device\n");

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&elapsedTime, start,stop);
    printf("Elapsed time : %f ms\n" , elapsedTime);

    cudaFree(d_dist_data);
    cudaFree(d_edges);

    int** dist = (int**) malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++)
        dist[i] = dist_data + i * n;

    printf("Start - Verification\n");
    // Verify correctness
    for (int src = 0; src < n; src++) {
        for (int i = 0; i < e; i++) {
            const int u = edges[i].src;
            const int v = edges[i].dest;
            if (dist[src][u] != INT_MAX && dist[src][v] > dist[src][u] + edges[i].weight) {
                printf("Triangle inequality violated!\n");
            }
        }
    }
    printf("End - Verification\n");
    printf("Correct!\n");

    free(dist);
    cudaFreeHost(dist_data);
    writeResults(n, e, elapsedTime, argc >= 3 ? argv[2] : "results_parallel_node.txt");


    return 0;
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
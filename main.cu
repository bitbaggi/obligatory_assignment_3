#include <stdio.h>
#include "edge.h"
#include "graphhelper.c"
#include "floydwarshall.c"
#include <sys/time.h>


__device__ int bellmanford_step(int n, int edge_count, Edge* d_edges, int* d_dist, int* d_parent)
{
    short changed = 0;
    for (int i = 0; i < edge_count; i++)
    {
        const struct Edge e = d_edges[i];
        if (d_dist[e.src] != INT_MAX && d_dist[e.dest] > d_dist[e.src] + e.weight)
        {
            d_dist[e.dest] = d_dist[e.src] + e.weight;
            d_parent[e.dest] = e.src;
            changed = 1;
        }
    }
    return changed;
}
__global__  void bellmanford_node(int n, int e, Edge* d_edges, int* d_dist_data, int* d_parent_data)
{
    int src = threadIdx.x + blockIdx.x * blockDim.x;
    int* d_dist = d_dist_data + src * n;
    int* d_parent = d_parent_data + src * n;
    for (int i = 0; i < n; i++)
    {
        d_dist[i] = INT_MAX;
        d_parent[i] = -1;
    }
    d_dist[src] = 0;
    d_parent[src] = -1;

    for (int i = 0; i < n-1; i++)
       if (bellmanford_step(n, e, d_edges, d_dist, d_parent) == 0)
           break;
    if (bellmanford_step(n, e, d_edges, d_dist, d_parent) != 0)
        printf("There is a negative cycle\n");
}

int main(void)
{
    // Read in the graph file
    struct Edge* edges;
    int n, e;
    read_graph("graph2.mtx", &edges, &n, &e);

    // Allocate memory for the distance and parenting arrays on host machine
    int* dist_data = (int*)malloc(n * n * sizeof(int));
    int* parent_data = (int*)malloc(n * n * sizeof(int));
    
    // TODO: Start timing here
    cudaEvent_t start, stop;
    float elapsedTime;

    cudaEventCreate(&start);
    cudaEventRecord(start,0);

    // Allocate memory and copy data

    struct Edge* d_edges;
    cudaMalloc((void **)&d_edges, e * sizeof(struct Edge));
    cudaMemcpy(d_edges, edges, e * sizeof(struct Edge), cudaMemcpyHostToDevice);

    // Using one big array in global space to fill and copy back at the end.
    int* d_dist_data;
    int* d_parent_data;
    cudaMalloc((void **) &d_dist_data, n * n * sizeof(int));
    cudaMalloc((void **) &d_parent_data, n * n * sizeof(int));

    bellmanford_node<<<1,n>>>(n, e, d_edges, d_dist_data, d_parent_data);

    cudaDeviceSynchronize();
    cudaMemcpy(dist_data, d_dist_data, n*n*sizeof(int),cudaMemcpyDeviceToHost);
    cudaMemcpy(parent_data, d_parent_data, n*n*sizeof(int),cudaMemcpyDeviceToHost );


    cudaEventCreate(&stop);
    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&elapsedTime, start,stop);
    printf("Elapsed time : %f ms\n" ,elapsedTime);
    // TODO: Stop Timing here

    int** dist = (int**) malloc(n * sizeof(int*));
    int** parent = (int**) malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++)
    {
        dist[i] = dist_data + i * n;
        parent[i] = parent_data + i * n;
    }


    // Allocate memory for floydwarshall
    int* fw_dist_data = (int*) malloc(n * n * sizeof(int));
    int** fw_dist = (int**) malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++)
        fw_dist[i] = fw_dist_data + i * n;

    // run floydwarshall as a correctness check
    floydWarshall(fw_dist, edges, n, e);
    verify(dist, fw_dist, n);

    return 0;
}

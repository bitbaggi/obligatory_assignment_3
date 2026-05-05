#include <stdio.h>
#include "edge.h"
#include "graphhelper.c"
#include <sys/time.h>

__global__ void bellmanford_init(int n, int* d_dist_data){
    int src = blockIdx.x;
    int* d_dist   = d_dist_data   + src * n;

    for (int i = threadIdx.x; i < n; i += blockDim.x)
        d_dist[i]   = INT_MAX;

    if (threadIdx.x == 0) d_dist[src] = 0;
}

__global__ void bellmanford_edge(int n, int e, Edge* d_edges, int* d_dist_data, int* d_changed){
	int src = blockIdx.x;
    int* d_dist = d_dist_data + src * n;

    for (int edgeId = threadIdx.x; edgeId < e; edgeId += blockDim.x) {
        const struct Edge* edge = d_edges + edgeId;
        if (d_dist[edge->src] != INT_MAX &&
            d_dist[edge->dest] > d_dist[edge->src] + edge->weight)
        {
            atomicMin(&d_dist[edge->dest], d_dist[edge->src] + edge->weight);
            atomicOr(d_changed, 1);
        }
    }
}

int run(int argc, char* argv[])
{
    if (argc < 2)
    {
        printf("Please add an argument for the graph and file\n");
        return 1;
    }
    // Read in the graph file
    struct Edge* edges;
    int n, e;
    read_graph(argv[1], &edges, &n, &e);

    printf("Start - Allocate Memory\n");
    // Allocate memory for the distance arrays on host machine
    int* dist_data;
	cudaMallocHost((void**)&dist_data,   (size_t)n * n * sizeof(int));
	int changed = 0;
    printf("End - Allocate Memory\n");

	// calculate max thread amount, cuda not allows higher amount of threads than 1024 per block
	int threads_e = (e < 1024) ? e : 1024;
	int threads_n = (n < 1024) ? n : 1024;

	// Meassure time with cuda
    cudaEvent_t start, stop;
    float elapsedTime;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start,0);

    // Allocate memory and copy data
	int* d_changed;
	cudaMalloc((void **) &d_changed, sizeof(int));

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
	// STEP 1: init arrays on device
	bellmanford_init<<<n, threads_n>>>(n, d_dist_data);

	// STEP 2: run the relaxation
	changed = 1;
	for(int i = 0; i < n - 1; i++){
		changed = 0;
		cudaMemcpy(d_changed, &changed, sizeof(int), cudaMemcpyHostToDevice);
		bellmanford_edge<<<n, threads_e>>>(n, e, d_edges, d_dist_data, d_changed);
    	cudaDeviceSynchronize();
		cudaMemcpy(&changed, d_changed, sizeof(int), cudaMemcpyDeviceToHost);
		if (!changed) break;
	}

	// STEP 3: check for negative cylce
	changed = 0;
	cudaMemcpy(d_changed, &changed, sizeof(int), cudaMemcpyHostToDevice);
	bellmanford_edge<<<n, threads_e>>>(n, e, d_edges, d_dist_data, d_changed);
	cudaDeviceSynchronize();
	cudaMemcpy(&changed, d_changed, sizeof(int), cudaMemcpyDeviceToHost);
	if (changed) printf("Negative cycle\n");
    printf("End - parallel bellman ford\n");

    printf("Start - Copy data from device\n");
	// STEP 4: copy the results back to host
    cudaMemcpy(dist_data, d_dist_data, n * n * sizeof(int), cudaMemcpyDeviceToHost);
    printf("End - Copy data from device\n");

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&elapsedTime, start, stop);
    printf("Elapsed time : %f ms\n" ,elapsedTime);
    // TODO: Stop Timing here

	cudaFree(d_dist_data);
	cudaFree(d_edges);
	cudaFree(d_changed);

    int** dist = (int**) malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++)
        dist[i] = dist_data + i * n;

    printf("Start - Verification\n");
    // Verify correctness
    for (int src = 0; src < n; src++) {
        for (int i = 0; i < e; i++) {
            const int u = edges[i].src;
            const int v = edges[i].dest;
            if (dist[src][u] != INT_MAX &&
                dist[src][v] > dist[src][u] + edges[i].weight) {
                printf("Triangle inequality violated!\n");
            }
        }
    }
    printf("End - Verification\n");
    printf("Correct!\n");

	free(dist);
	cudaFreeHost(dist_data);

    writeResults(n, e, elapsedTime, argc >= 3 ? argv[2] : "results_parallel_all.txt");
    return 0;
}



int main(int argc, char* argv[])
{
    int runs = 0;
    if (argc == 3)
        runs = atoi(argv[2]);
    else if (argc == 4)
        runs = atoi(argv[3]);
    else runs = 3;

    for (int i = 0; i < runs; i++)
    {
        run(argc, argv);
    }
    return 0;
}
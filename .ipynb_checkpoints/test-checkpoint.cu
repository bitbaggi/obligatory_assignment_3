#include <stdio.h>
__global__ void kernel(const int *da, int *db) {
	int tid =threadIdx.x + blockIdx.x * blockDim.x;
	db[tid] = da[tid] + 10;
}

int main(void) {

	int * p;
	int * q;
	int * dev_p;
	int * dev_q;
	int ns = 64;
	int size = ns * sizeof(int);

	/* Allocate p as zero-copy write-combined memory */
    cudaHostAlloc(&p, size,
	   cudaHostAllocWriteCombined | cudaHostAllocMapped);

	/* Allocate q as zero-copy memory (not write-combined) */
	cudaHostAlloc(&q, size, cudaHostAllocMapped);

	/* Initialize p */
	for (int i = 0; i < ns; i++){ p[i] = i + 1; }

	/* Get the device pointers for p and q */
	cudaHostGetDevicePointer(&dev_p, p, 0);
	cudaHostGetDevicePointer(&dev_q, q, 0);

	kernel<<<ns/2, ns>>>(dev_p, dev_q); // Launch the kernel
	cudaDeviceSynchronize();

	for (int i = 0; i < ns; i++){ printf("q[%d] = %d\n", i, q[i]); }

	return 0;
}
%%cu
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda.h>

__global__ void bitonic_sort(int *in, int j, int i) {
    int index = threadIdx.x + blockDim.x * blockIdx.x;
    int i2 = pow(2,i);
    int j2 = pow(2,j-1); 

    int step_length = i2 / j2;
    int shift = step_length / 2;
    int temp;

    if(index % step_length < shift){
        if((index / i2) % 2 == 0){
            if(in[index] > in[index+shift]){
                temp = in[index];
                in[index] = in[index+shift];
                in[index+shift] = temp; 
            }
        }
        else if(in[index] < in[index+shift]) {
            temp = in[index];
            in[index] = in[index+shift];
            in[index+shift] = temp;
        }
        __syncthreads();
    }
}
int main(void){
    int *a;
    int *d_a;
    int blocks = 2;
    int threads =8;
    int numThreadBlock = blocks * threads;
    int old=-1 ; 
    
    int limit = log2(numThreadBlock);
    
    int ch=2;
    int power = 1;
    int b =0;
    while(numThreadBlock > ch){
        power = power + 1;
        b = power;
        ch = pow(2, power);
    }
    if(limit != b ){
        old = numThreadBlock;
        numThreadBlock = pow(2,b);
        limit = b;        
        }
   
    int size = sizeof(int) * numThreadBlock;
    cudaMalloc( (void**) &d_a, size);
    int newIndexeis = numThreadBlock; 
    if (old != -1)
      numThreadBlock = old;
    printf("old %d new %d\n",numThreadBlock, newIndexeis);
    a = (int*) malloc(size);
    
    srand(time(NULL));
    int i;
    int check_index_full=-1;
    
    for ( i=0;i<numThreadBlock;i++) {
      a[i] = (rand() % (15 - 1 + 5)) + 5;
      check_index_full = i;
    }
    if ( (old-1) == check_index_full ){
        for(i=check_index_full+1;i<newIndexeis;i++){
            a[i] = 1;
        }
    }
    numThreadBlock = newIndexeis;
    printf("Before\n");
    for (i=0;i<numThreadBlock;i++) {
      printf("index %d number %d\n", i, a[i]);
    }

    // host to device
    cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);

    int step=1, stage; 
    printf("\nlimit%d\n", limit);
   
    while( step <= limit){
        for(stage=1; stage<=step; stage++)
            bitonic_sort<<<blocks,threads>>>(d_a, stage, step);
        step+=1;
    }
        

    // divice to host
    cudaMemcpy(a, d_a, size, cudaMemcpyDeviceToHost);

    printf("-------------\nAfter\n");
    for (i=0;i<numThreadBlock;i++) {
      printf("index %d number %d\n", i, a[i]);
    }

    free(a);
    cudaFree(d_a); 
}


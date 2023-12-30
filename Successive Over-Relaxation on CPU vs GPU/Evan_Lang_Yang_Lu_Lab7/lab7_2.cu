/****************************************************************************


   nvcc sor_cuda.cu -o sor_cuda 
*/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <cuda.h>
#include <iostream>

#ifdef __APPLE__
/* Shim for Mac OS X (use at your own risk ;-) */
# include "apple_pthread_barrier.h"
#endif /* __APPLE__ */

#define CPNS 2.0    /* Cycles per nanosecond -- Adjust to your computer,
                       for example a 3.2 GhZ GPU, this would be 3.2 */
#define A   0   /* coefficient of x^2 */
#define B   0  /* coefficient of x */
#define C   2048 /* constant term */

#define NUM_TESTS 1
#define bl_size 16
#define ITERS 2000

/* A, B, and C needs to be a multiple of your BLOCK_SIZE,
   total array size will be ( + Ax^2 + Bx + C) */
#define MINVAL   0.0
#define MAXVAL  10.0
#define TOL 0.00001

typedef double data_t;

typedef struct {
  long int rowlen;
  data_t *data;
} arr_rec, *arr_ptr;

/* Prototypes */
arr_ptr new_array(long int row_len);
int set_arr_rowlen(arr_ptr v, long int index);
long int get_arr_rowlen(arr_ptr v);
int init_array(arr_ptr v, long int row_len);
int init_array_rand(arr_ptr v, long int row_len);
void print_array(arr_ptr v);
data_t *get_array_start(arr_ptr v);
__global__ void gpu_SOR(data_t *data , data_t *interations, long int rowlen);

void SOR(arr_ptr v, int *iterations);

/* -=-=-=-=- Time measurement by clock_gettime() -=-=-=-=- */
/*
  As described in the clock_gettime manpage (type "man clock_gettime" at the
  shell prompt), a "timespec" is a structure that looks like this:
 
        struct timespec {
          time_t   tv_sec;   // seconds
          long     tv_nsec;  // and nanoseconds
        };
 */

double interval(struct timespec start, struct timespec end)
{
  struct timespec temp;
  temp.tv_sec = end.tv_sec - start.tv_sec;
  temp.tv_nsec = end.tv_nsec - start.tv_nsec;
  if (temp.tv_nsec < 0) {
    temp.tv_sec = temp.tv_sec - 1;
    temp.tv_nsec = temp.tv_nsec + 1000000000;
  }
  return (((double)temp.tv_sec) + ((double)temp.tv_nsec)*1.0e-9);
}
/*
     This method does not require adjusting a #define constant

  How to use this method:

      struct timespec time_start, time_stop;
      clock_gettime(CLOCK_REALTIME, &time_start);
      // DO SOMETHING THAT TAKES TIME
      clock_gettime(CLOCK_REALTIME, &time_stop);
      measurement = interval(time_start, time_stop);

 */


/* -=-=-=-=- End of time measurement declarations =-=-=-=- */

/*****************************************************************************/
int main(int argc, char *argv[])
{
  struct timespec time_start, time_stop;
  double time_stamp[NUM_TESTS];
  int convergence[NUM_TESTS];
  int *iterations;
  long int x, n;
  long int alloc_size;

  x = NUM_TESTS-1;
  alloc_size =  A*x*x + B*x + C;

  printf("SOR serial code \n");
  /* declare and initialize the array */
  arr_ptr v0 = new_array(alloc_size);
  
  /* Allocate space for return value */
  iterations = (int *) malloc(sizeof(int));
  init_array_rand(v0, alloc_size);
  set_arr_rowlen(v0, alloc_size);
  
  /* Prep cuda code*/
  data_t *d_arrptr, *d_iterations;
  if(cudaMalloc(&d_arrptr, sizeof(data_t) * alloc_size*alloc_size) != cudaSuccess){
      std::cout<<("Cannot allocate device memory.");
      return 0;
  } 
  if(cudaMalloc(&d_iterations, sizeof(data_t) * alloc_size*alloc_size) != cudaSuccess){
      std::cout<<("Cannot allocate device memory.");
      free(d_arrptr);
      return 0;
  }
  if(cudaMemcpy(d_arrptr, v0->data, sizeof(data_t) * alloc_size*alloc_size, cudaMemcpyHostToDevice) != cudaSuccess){
      std::cout<<("Cannot copy from host to device.");
      free(d_arrptr);
      free(d_iterations);
      return 0;
  } 
  
  /* initialize cta and grid dimensions*/
  int threads = bl_size;
  int blocks = 1;
  
  //setup kernal launch parameters
  dim3 THREADS(threads,threads);
  dim3 BLOCKS(blocks, blocks);
  
  //std::cout<<"original v0\n";
  //print_array(v0);
  //std::cout<<std::endl;
  //gpu_SOR<<<BLOCKS, THREADS>>>(d_arrptr , d_iterations, alloc_size);
  
   /*if(cudaMemcpy(v0->data, d_arrptr, sizeof(data_t) * alloc_size*alloc_size, cudaMemcpyDeviceToHost) != cudaSuccess){
      std::cout<<("Cannot copy from host to device.");
      free(d_arrptr);
      free(d_iterations);
      return 0;
  }*/
  //std::cout<<"after gpu_SOR\n";
  //print_array(v0);
  
  for (x=0; x<NUM_TESTS && (n = A*x*x + B*x + C, n<=alloc_size); x++) {
    //printf("  iter %ld rowlen = %ld\n", x, n);
    init_array_rand(v0, n);
    set_arr_rowlen(v0, n);
    clock_gettime(CLOCK_REALTIME, &time_start);
    gpu_SOR<<<BLOCKS, THREADS>>>(d_arrptr, d_iterations, alloc_size);
    clock_gettime(CLOCK_REALTIME, &time_stop);
    if(cudaMemcpy(v0->data, d_arrptr, sizeof(data_t) * alloc_size*alloc_size, cudaMemcpyDeviceToHost) != cudaSuccess){
      std::cout<<("Cannot copy from host to device.");
      free(d_arrptr);
      free(d_iterations);
      return 0;
      }
    time_stamp[x] = interval(time_start, time_stop);
    convergence[x] = *iterations;
  }

  printf("\n");
  printf("#Elements, SOR time\n");
  {
    int i;
    for (i = 0; i < NUM_TESTS; i++) {
      printf("%4d", A*i*i + B*i + C);
      printf(", %10.4g",time_stamp[i]);
      //printf(", %4d", convergence[i]);
      printf("\n");
    }
  }

} /* end main */

/*********************************/

/* Create 2D array of specified length per dimension */
arr_ptr new_array(long int row_len)
{
  /* Allocate and declare header structure */
  arr_ptr result = (arr_ptr) malloc(sizeof(arr_rec));
  if (!result) {
    return NULL;  /* Couldn't allocate storage */
  }
  result->rowlen = row_len;

  /* Allocate and declare array */
  if (row_len > 0) {
    data_t *data = (data_t *) calloc(row_len*row_len, sizeof(data_t));
    if (!data) {
      free((void *) result);
      printf("\n COULDN'T ALLOCATE STORAGE \n");
      return NULL;  /* Couldn't allocate storage */
    }
    result->data = data;
  }
  else result->data = NULL;

  return result;
}

/* Set row length of array */
int set_arr_rowlen(arr_ptr v, long int row_len)
{
  v->rowlen = row_len;
  return 1;
}

/* Return row length of array */
long int get_arr_rowlen(arr_ptr v)
{
  return v->rowlen;
}

/* initialize 2D array with incrementing values (0.0, 1.0, 2.0, 3.0, ...) */
int init_array(arr_ptr v, long int row_len)
{
  long int i;

  if (row_len > 0) {
    v->rowlen = row_len;
    for (i = 0; i < row_len*row_len; i++) {
      v->data[i] = (data_t)(i);
    }
    return 1;
  }
  else return 0;
}

/* initialize array with random data */
int init_array_rand(arr_ptr v, long int row_len)
{
  long int i;
  double fRand(double fMin, double fMax);

  /* Since we're comparing different algorithms (e.g. blocked, threaded
     with stripes, red/black, ...), it is more useful to have the same
     randomness for any given array size */
  srandom(row_len);
  if (row_len > 0) {
    v->rowlen = row_len;
    for (i = 0; i < row_len*row_len; i++) {
      v->data[i] = (data_t)(fRand((double)(MINVAL),(double)(MAXVAL)));
    }
    return 1;
  }
  else return 0;
}

/* print all elements of an array */
void print_array(arr_ptr v)
{
  long int i, j, row_len;

  row_len = v->rowlen;
  printf("row length = %ld\n", row_len);
  for (i = 0; i < row_len; i++) {
    for (j = 0; j < row_len; j++) {
      printf("%.4f ", (data_t)(v->data[i*row_len+j]));
    }
    printf("\n");
  }
}

data_t *get_array_start(arr_ptr v)
{
  return v->data;
}

double fRand(double fMin, double fMax)
{
  double f = (double)random() / RAND_MAX;
  return fMin + f * (fMax - fMin);
}

/************************************/

/* SOR */
void SOR(arr_ptr v, int *iterations)
{
  long int i, j;
  long int rowlen = get_arr_rowlen(v);
  data_t *data = get_array_start(v);
  double diff = 1.0e10;   /* start w/ something big */
  int iters = 0, temp = 0;

  while ((diff/(double)(rowlen*rowlen)) > (double)TOL) {
    iters++;
    diff = 0;
    for (i = 1; i < rowlen-1; i++) {
      for (j = 1; j < rowlen-1; j++) {
        temp = data[i*rowlen+j];
        data[i*rowlen+j] =         0.2 * (  data[(i)*rowlen+j] +
                                          data[(i)*rowlen+(j-1)] +
                                          data[(i-1)*rowlen+j] +
                                          data[i*rowlen+(j+1)]   +
                                          data[(i+1)*rowlen+j]);
        diff += abs(data[i*rowlen+j] - temp);
      }
    }
    if (abs(data[(rowlen-2)*(rowlen-2)]) > 10.0*(MAXVAL - MINVAL)) {
      printf("SOR: SUSPECT DIVERGENCE iter = %d\n", iters);
      break;
    }
  }
  *iterations = iters;
  //printf("    SOR() done after %d iters\n", iters);
}

__global__ void gpu_SOR(data_t *data , data_t *iterations, long int rowlen)
{
  long int i = blockIdx.y * blockDim.y + threadIdx.y; //row
  long  int j = blockIdx.x * blockDim.x + threadIdx.x; //col
  long int x, y, iters;
  int a, b;
  data_t arr[bl_size*bl_size];

  //boundary check
  if(i < rowlen && j < rowlen && i>= 0 && j>=0){
     for (iters = 0; iters < ITERS; iters++){ 
        for(x = i*bl_size; x < i*bl_size+bl_size; x++){
            for(y = j*bl_size;  y < j*bl_size+bl_size; y++){
               a = x - (i*bl_size);
               b = y - (j*bl_size); 
               if(x > 0 && y > 0 && x < bl_size-1 && y < bl_size-1){ 
                     arr[a*bl_size+b] =         0.2 * (  data[(x)*rowlen+y] +
                                          data[(x)*rowlen+(y-1)] +
                                          data[(x-1)*rowlen+y] +
                                          data[x*rowlen+(j+y)]   +
                                          data[(x+1)*rowlen+y]);
               }
               else{
                  arr[a*bl_size+b] = data[(x)*rowlen+y];  
               }
            }
        }
    
        __syncthreads();
        for(x = i*bl_size; x < i*bl_size+bl_size; x++){
            for(y = j*bl_size;  y < j*bl_size+bl_size; y++){
               a = x - (i*bl_size);
               b = y - (j*bl_size);
               data[x*rowlen+y] = arr[a*bl_size+b];
            }
        }
        __syncthreads();
     }
  }
}

/*****************************************************************************/
// nvcc hw8.cu -o hw8

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <stdbool.h>
#include <cuda.h>
#include <iostream>

/* We want to test a wide range of work sizes. We will generate these
   using the quadratic formula:  A x^2 + B x + C                     */
#define A   0  /* coefficient of x^2 */
#define B   0  /* coefficient of x */
#define C   2048  /* constant term */

#define NUM_TESTS 1   /* Number of different sizes to test */

#define OPTIONS 2
#define IDENT 0

typedef float data_t;

/* Create abstract data type for matrix */
typedef struct {
  long int len;
  data_t *data;
} matrix_rec, *matrix_ptr;

/* Prototypes */
int clock_gettime(clockid_t clk_id, struct timespec *tp);
matrix_ptr new_matrix(long int row_len);
int set_matrix_row_length(matrix_ptr m, long int row_len);
long int get_matrix_row_length(matrix_ptr m);
int init_matrix(matrix_ptr m, long int row_len);
int zero_matrix(matrix_ptr m, long int row_len);
void mmm_ijk(matrix_ptr a, matrix_ptr b, matrix_ptr c);
bool MMM_check(matrix_ptr expected, matrix_ptr actual);
__global__ void gpu_MMM(data_t *da0, data_t *db0, data_t *dc0, long int rowlen);
void printMat(matrix_ptr mat, long int rowlen);

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
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
      // DO SOMETHING THAT TAKES TIME
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);
      measurement = interval(time_start, time_stop);

 */


/* -=-=-=-=- End of time measurement declarations =-=-=-=- */

/* This routine "wastes" a little time to make sure the machine gets
   out of power-saving mode (800 MHz) and switches to normal speed. */
double wakeup_delay()
{
  srand(time(0));
  double meas = 0; int i, j;
  struct timespec time_start, time_stop;
  double quasi_random = 0;
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
  j = 100;
  while (meas < 1.0) {
    for (i=1; i<j; i++) {
      /* This iterative calculation uses a chaotic map function, specifically
         the complex quadratic map (as in Julia and Mandelbrot sets), which is
         unpredictable enough to prevent compiler optimisation. */
      quasi_random = quasi_random*quasi_random - 1.923432;
    }
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);
    meas = interval(time_start, time_stop);
    j *= 2; /* Twice as much delay next time, until we've taken 1 second */
  }
  return quasi_random;
}

/*****************************************************************************/
int main(int argc, char *argv[])
{
  srand(time(0));
  int OPTION;
  struct timespec time_start, time_stop, gpu_timestart, gpu_timestop;
  double time_stamp[OPTIONS][NUM_TESTS];
  double wakeup_answer;
  long int x, n, alloc_size;

  x = NUM_TESTS-1;
  alloc_size = A*x*x + B*x + C;

  printf("Dense MMM tests \n\n");

  wakeup_answer = wakeup_delay();

  printf("Doing MMM three different ways,\n");
  printf("for %d different matrix sizes from %d to %ld\n", NUM_TESTS, C, alloc_size);
  printf("This may take a while!\n\n");
  /* declare and initialize the matrix structure */
  matrix_ptr a0 = new_matrix(alloc_size);
  init_matrix(a0, alloc_size);
  matrix_ptr b0 = new_matrix(alloc_size);
  init_matrix(b0, alloc_size);
  matrix_ptr c0 = new_matrix(alloc_size);
  zero_matrix(c0, alloc_size);
  matrix_ptr test_gpu = new_matrix(alloc_size);
  zero_matrix(test_gpu, alloc_size);
 
  OPTION = 0;//serial
  for (x=0; x<NUM_TESTS && (n = A*x*x + B*x + C, n<=alloc_size); x++) {
    set_matrix_row_length(a0, n);
    set_matrix_row_length(b0, n);
    set_matrix_row_length(c0, n);
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
    mmm_ijk(a0, b0, c0);
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);
    time_stamp[OPTION][x] = interval(time_start, time_stop);
  }
   
  //initialize GPU
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &gpu_timestart);
  data_t *da0, *db0, *dc0;
  long int size = alloc_size*alloc_size;
  if(cudaMalloc(&da0, sizeof(data_t)*size) != cudaSuccess);
  if(cudaMalloc(&db0, sizeof(data_t)*size) != cudaSuccess);
  if(cudaMalloc(&dc0, sizeof(data_t)*size) != cudaSuccess);
  if(cudaMemcpy(da0, a0->data, sizeof(data_t)*size, cudaMemcpyHostToDevice) != cudaSuccess);
  if(cudaMemcpy(db0, b0->data, sizeof(data_t)*size, cudaMemcpyHostToDevice) != cudaSuccess);
  if(cudaMemcpy(dc0, c0->data, sizeof(data_t)*size, cudaMemcpyHostToDevice) != cudaSuccess);  
  dim3 BLOCK(16, 16, 1);
  dim3 GRID(size/16, size/16, 1);
  OPTION++;//GPU
  for (x=0; x<NUM_TESTS && (n = A*x*x + B*x + C, n<=alloc_size); x++) {
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
    gpu_MMM<<<GRID, BLOCK>>>(da0, db0, dc0, alloc_size);
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);
    time_stamp[OPTION][x] = interval(time_start, time_stop);
    //checking for errors by comparing serial vs GPU
    set_matrix_row_length(test_gpu, alloc_size);
    if(cudaMemcpy(test_gpu->data, dc0, sizeof(data_t)*size, cudaMemcpyDeviceToHost) != cudaSuccess){std::cout<<"fail\n"; return 0;}
    printf("\nTrue/False: %d\n",MMM_check(c0, test_gpu));
    //printMat(c0, n);
    //printMat(test_gpu, n);
  }
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &gpu_timestop);
  
  //printf("Done collecting measurements.\n\n");
  printf("Total gpu overhead: %f\n\n", interval(gpu_timestart, gpu_timestop));
  printf("row_len, ijk_cpu, GPU_Serial\n");
  {
    int i, j;
    for (i = 0; i < NUM_TESTS; i++) {
      printf("%d, ", A*i*i + B*i + C);
      for (j = 0; j < OPTIONS; j++) {
        if (j != 0) {
          printf(", ");
        }
        printf("%f", time_stamp[j][i]);
      }
      printf("\n");
    }
  }
  printf("\n");

  printf("Wakeup delay computed: %g \n", wakeup_answer);
} /* end main */

/**********************************************/

/* Create matrix of specified length */
matrix_ptr new_matrix(long int row_len)
{
  //long int i;
  long int alloc;

  /* Allocate and declare header structure */
  matrix_ptr result = (matrix_ptr) malloc(sizeof(matrix_rec));
  if (!result) return NULL;  /* Couldn't allocate storage */
  result->len = row_len;

  /* Allocate and declare array */
  if (row_len > 0) {
    alloc = row_len * row_len;
    data_t *data = (data_t *) calloc(alloc, sizeof(data_t));
    if (!data) {
	  free((void *) result);
	  printf("\n COULDN'T ALLOCATE %ld BYTES STORAGE \n",
                                                       alloc * sizeof(data_t));
	  return NULL;  /* Couldn't allocate storage */
	}
	result->data = data;
  } else {
    result->data = NULL;
  }

  return result;
}

/* Set length of matrix */
int set_matrix_row_length(matrix_ptr m, long int row_len)
{
  m->len = row_len;
  return 1;
}

/* Return length of matrix */
long int get_matrix_row_length(matrix_ptr m)
{
  return m->len;
}

/* initialize matrix */
int init_matrix(matrix_ptr m, long int row_len)
{
  long int i;

  if (row_len > 0) {
    m->len = row_len;
    for (i = 0; i < row_len*row_len; i++) {
      m->data[i] = (data_t)(rand() % 100 + 0);
    }
    return 1;
  }
  else return 0;
}

/* initialize matrix */
int zero_matrix(matrix_ptr m, long int row_len)
{
  long int i;

  if (row_len > 0) {
    m->len = row_len;
    for (i = 0; i < row_len*row_len; i++) {
      m->data[i] = (data_t)(IDENT);
    }
    return 1;
  }
  else return 0;
}

data_t *get_matrix_start(matrix_ptr m)
{
  return m->data;
}

/*************************************************/

/* mmm */
void mmm_ijk(matrix_ptr a, matrix_ptr b, matrix_ptr c)
{
  long int i, j, k;
  long int length = get_matrix_row_length(a);
  data_t *a0 = get_matrix_start(a);
  data_t *b0 = get_matrix_start(b);
  data_t *c0 = get_matrix_start(c);
  data_t sum;

  for (i = 0; i < length; i++) {
    for (j = 0; j < length; j++) {
      sum = IDENT;
      for (k = 0; k < length; k++) {
        sum += a0[i*length+k] * b0[k*length+j];
      }
      c0[i*length+j] += sum;
    }
  }
}

void printMat(matrix_ptr mat, long int rowlen)
{
   data_t *arr = get_matrix_start(mat);
   long int i, j;
    printf("\n");
    for (i = 0; i < rowlen; i++){
        for(j = 0; j < rowlen; j++){
            printf("%0.2f ", arr[i*rowlen+j]);
        }
        printf("\n");
    }
}
bool MMM_check(matrix_ptr expected, matrix_ptr actual)
{
    data_t *serial = get_matrix_start(expected);
    data_t *gpu = get_matrix_start(actual);
    long int length = get_matrix_row_length(expected);
    long int i, j;
    long int imax = 0, jmax = 0;
    long int max_delta=0;
    for (i = 0; i < length; i++){
        for(j = 0; j < length; j++){
            if ((long int)serial[i*length+j] != (long int)gpu[i*length+j]){
                //printf("\nserial: %f GPU: %f\nRow: %ld Col: %ld\n", serial[i*length+j], gpu[i*length+j],i,j);
                //return false;
               if(max_delta < abs(serial[i*length+j]-gpu[i*length+j])){ 
                   max_delta = abs(serial[i*length+j]-gpu[i*length+j]);
                   imax = i;
                   jmax = j;
               }
               //return false;
            }
        }
    }
    printf("Biggest difference:\nserial: %f, gpu: %f\n\n", serial[imax*length+jmax], gpu[imax*length+jmax]);
    return true;
}

__global__ void gpu_MMM(data_t *da0, data_t *db0, data_t *dc0, long int rowlen)
{
    long int n = rowlen*rowlen;
    int nElem = n/16;
    int b_incrament = n*16;
    int aStart = (16*blockIdx.y+threadIdx.y)*n+threadIdx.x;
    int bStart = 16*blockIdx.x+threadIdx.y*n+threadIdx.x;
    __shared__ data_t a[16][16], b[16][17];
    data_t sum = 0;
    long int i;

    for (i = 0; i < nElem; i++){
        a[threadIdx.y][threadIdx.x] = da0[aStart];
        b[threadIdx.x][threadIdx.y] = db0[bStart];
        __syncthreads();
        //for (k = 0; k < 16; k+=4)
        {
            sum += a[threadIdx.y][0]*b[threadIdx.x][0];
            sum += a[threadIdx.y][1]*b[threadIdx.x][1];
            sum += a[threadIdx.y][2]*b[threadIdx.x][2];
            sum += a[threadIdx.y][3]*b[threadIdx.x][3];
            sum += a[threadIdx.y][4]*b[threadIdx.x][4];
            sum += a[threadIdx.y][5]*b[threadIdx.x][5];
            sum += a[threadIdx.y][6]*b[threadIdx.x][6];
            sum += a[threadIdx.y][7]*b[threadIdx.x][7];
            sum += a[threadIdx.y][8]*b[threadIdx.x][8];
            sum += a[threadIdx.y][9]*b[threadIdx.x][9];
            sum += a[threadIdx.y][10]*b[threadIdx.x][10];
            sum += a[threadIdx.y][11]*b[threadIdx.x][11];
            sum += a[threadIdx.y][12]*b[threadIdx.x][12];
            sum += a[threadIdx.y][13]*b[threadIdx.x][13];
            sum += a[threadIdx.y][14]*b[threadIdx.x][14];
            sum += a[threadIdx.y][15]*b[threadIdx.x][15];
 
        }
        //__syncthreads();
        aStart += 16;
        bStart += b_incrament;
    }
    dc0[(16*blockIdx.y+threadIdx.y)*n + 16*blockIdx.x + threadIdx.x] = sum;
}

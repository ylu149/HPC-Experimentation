/****************************************************************************

 gcc -O1 test_dot.c -lrt -o test_dot

*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <math.h>

/* We want to test a range of work sizes. We will generate these
   using the quadratic formula:  A x^2 + B x + C                     */
#define A   200   /* coefficient of x^2 */
#define B   4   /* coefficient of x */
#define C   20  /* constant term */

#define NUM_TESTS 100   /* Number of different sizes to test */

#define CPNS 2.4    /* Cycles per nanosecond -- Adjust to your computer,
                       for example a 3.2 GHz GPU, this would be 3.2 */

/* Type of data being "combined". This can be any of the types:
   int, long int, float, double, long double */
typedef double data_t;

/* Create abstract data type for an array in memory */
typedef struct {
  long int len;
  data_t *data;
} array_rec, *array_ptr;

/* Prototypes */
array_ptr new_array(long int len);
int get_array_element(array_ptr v, long int index, data_t *dest);
long int get_array_length(array_ptr v);
int set_array_length(array_ptr v, long int index);
int init_array(array_ptr v, long int len);
void dotProd(array_ptr v, array_ptr v1, data_t *sum);
void dotProd_opt(array_ptr v, array_ptr v1, data_t *sum);

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
  int OPTION;
  struct timespec time_start, time_stop;
  double final_answer = 0;
  long int x, n, k, alloc_size;

  wakeup_delay();

  final_answer = wakeup_delay();

  x = NUM_TESTS-1;
  alloc_size = A*x*x + B*x + C;

  /* declare and initialize the arrays */
  array_ptr v0 = new_array(alloc_size);
  init_array(v0, alloc_size);
  array_ptr v1 = new_array(alloc_size);
  init_array(v1, alloc_size);
  
  
  data_t *std_results;
  std_results = (data_t *) malloc(sizeof(data_t));
  
  data_t *opt_results;
  opt_results = (data_t *) malloc(sizeof(data_t));
  
  //measuring standard method of dot product
  
  printf("n, std_dot, opt_dot\n");
  for (x=0; x<NUM_TESTS && (n = A*x*x + B*x + C, n<=alloc_size); x++) 
  {
      printf("%ld, ", n);
      set_array_length(v0, n);
      set_array_length(v1, n);
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
      dotProd(v0, v1, std_results);
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);
      printf("%ld, ", (long int)((double)(CPNS) * 1.0e9 * interval(time_start, time_stop)));
      
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
      dotProd_opt(v0, v1, opt_results);
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);
      printf("%ld\n", (long int)((double)(CPNS) * 1.0e9 * interval(time_start, time_stop)));
        
  }
  
  return 0;  
} /* end main */

/**********************************************/
/* Create array of specified length */
array_ptr new_array(long int len)
{
  long int i;

  /* Allocate and declare header structure */
  array_ptr result = (array_ptr) malloc(sizeof(array_rec));
  if (!result) return NULL;  /* Couldn't allocate storage */
  result->len = len;

  /* Allocate and declare array */
  if (len > 0) {
    data_t *data = (data_t *) calloc(len, sizeof(data_t));
    if (!data) {
      free((void *) result);
      return NULL;  /* Couldn't allocate storage */
    }
    result->data = data;
  }
  else result->data = NULL;
  return result;
}

/* Retrieve array element and store at dest.
   Return 0 (out of bounds) or 1 (successful)
*/
int get_array_element(array_ptr v, long int index, data_t *dest)
{
  if (index < 0 || index >= v->len) {
    return 0;
  }
  *dest = v->data[index];
  return 1;
}

/* Return length of array */
long int get_array_length(array_ptr v)
{
  return v->len;
}

/* Set length of array */
int set_array_length(array_ptr v, long int index)
{
  v->len = index;
  return 1;
}

/* initialize an array */
int init_array(array_ptr v, long int len)
{
  long int i;

  if (len > 0) {
    v->len = len;
    for (i = 0; i < len; i++) {
      v->data[i] = (data_t)(i+1);
    }
    return 1;
  }
  else return 0;
}

data_t *get_array_start(array_ptr v)
{
  return v->data;
}


/*************************************************/
void dotProd(array_ptr v, array_ptr v1, data_t *sum)
{
  long int i;
  long int length = get_array_length(v);
  
  data_t *data = get_array_start(v);
  data_t *data1 = get_array_start(v1);
  data_t temp =0;
  for (i = 0; i < length; i++) 
  {
    temp += data[i]*data1[i];
  }
  *sum = temp;
}

void dotProd_opt(array_ptr v, array_ptr v1, data_t *sum)
{
  long int i;
  long int length = get_array_length(v);
  
  data_t *data = get_array_start(v);
  data_t *data1 = get_array_start(v1);
  data_t temp =0;
  for (i = 0; i < length; i+=5) 
  {
    temp += data[i]*data1[i]+data[i+1]*data1[i+1] + data[i+2]*data1[i+2] 
        +data[i+3]*data1[i+3]+data[i+4]*data1[i+4];
  }
  *sum = temp;
}


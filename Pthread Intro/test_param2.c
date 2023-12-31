/*************************************************************************

  gcc -pthread test_param2.c -o test_param2 -std=gnu99

 */

#include <stdio.h>
#include <stdlib.h>

#include <pthread.h>

#define NUM_THREADS 10
/********************/
void *work(void *i)
{
  long int k;
  int f = *((int*)(i));  // get the value being pointed to
  int *g = (int*)(i);    // get the pointer itself 
  if(f>=10){pthread_exit(NULL);} 
  /* busy work */
  k = 0;
  for (long j=0; j < 10000000; j++) {
    k += j;
  }
  /* printf("Hello World from %lu with value %d\n", pthread_self(), f); */
  printf("in work(): f=%2d, k=%ld, *g=%d\n", f, k, *g);
  pthread_exit(NULL);
}

/*************************************************************************/
int main(int argc, char *argv[])
{
  long k, t;
  pthread_t id[NUM_THREADS];

  for (t = 0; t < NUM_THREADS; ++t) {
    if (pthread_create(&id[t], NULL, work, (void *)(&t))) {
      printf("ERROR creating the thread\n");
      exit(19);
    }
  }

  /* busy work */
  k = 0;
  for (long j=0; j < 100000000; j++) {
    k += j;
  }

  printf("k=%ld\n", k);
  printf("After creating the threads.  My id is %lx, t = %d\n",
                                                 (long)pthread_self(), t);

  return(0);

} /* end main */

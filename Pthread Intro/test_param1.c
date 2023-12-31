/*************************************************************************

  gcc -pthread test_param1.c -o test_param -std=gnu99

 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#define NUM_THREADS 5

/************************************************************************/
void *PrintHello(void *threadid)
{
  long tid;
  printf("PrintHello() in thread # as int %d ! \n", threadid);
  printf("PrintHello() in thread # as char %d ! \n", ((signed char) threadid));
  tid = (long) threadid;
  printf("PrintHello() in thread # %ld ! \n", tid);

  pthread_exit(NULL);
}

/*************************************************************************/
int main(int argc, char *argv[])
{
  pthread_t threads[NUM_THREADS];
  int rc;

  printf("Hello test_param1.c\n");

  for (long t = 0; t < NUM_THREADS; t++) {
    printf("In main:  creating thread %d\n", t);
    rc = pthread_create(&threads[-t], NULL, PrintHello, (void*) t);
    if (rc) {
      printf("ERROR; return code from pthread_create() is %d\n", rc);
      exit(-1);
    }
  }

  printf("It's me MAIN -- Good Bye World!\n");

  pthread_exit(NULL);

} /* end main */

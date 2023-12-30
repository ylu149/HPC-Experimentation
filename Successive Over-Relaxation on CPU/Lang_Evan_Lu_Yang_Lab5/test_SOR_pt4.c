#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <pthread.h>
#include <stdbool.h>
#include <time.h>

#define TOL 0.00001
#define NUMTHREADS 4
#define CPNS 2.4
#define A   8   /* coefficient of x^2 */
#define B   16  /* coefficient of x */
#define C   32  /* constant term */
#define NUM_TESTS 1
#define OPTIONS 4
#define Rowlen 1800
#define OMEGA 1.5

typedef double data_t;
data_t data[Rowlen*Rowlen];
data_t sol[Rowlen*Rowlen];
data_t A_ready[Rowlen*Rowlen];
pthread_mutex_t lock;
long int test = 0, iters = 0;
void serial_SOR();
void printStuff(data_t arr[]);
void *thread_sor();
void setupbool();
void setupdiff();
void reset_sol();
void threadSetup();
void *thread_sorji();
void threadSetupji();
double interval(struct timespec start, struct timespec end);

int main(int argc, char *argv[])
{
    struct timespec time_start, time_stop;
    long int x, n, alloc_size = A*x*x + B*x + C;
    srand(time(0));
    setupdiff();
    reset_sol();
    printf("Rowlen, Cycles\n");
    //serial code
    
    //printStuff(sol);
    for (x=0; x<NUM_TESTS; x++) {
            
        clock_gettime(CLOCK_REALTIME, &time_start);
        test = 0;
        serial_SOR();
        clock_gettime(CLOCK_REALTIME, &time_stop);
        
    }
    //printStuff(sol);
    printf("%d, %10.4g, Serial \n", Rowlen,  interval(time_start, time_stop));

    //parallel code
    for (x = 0; x<NUM_TESTS; x++) {
        iters = 0;
        setupbool();
        reset_sol();
        clock_gettime(CLOCK_REALTIME, &time_start);
        threadSetup();
        clock_gettime(CLOCK_REALTIME, &time_stop);
    }
    printf("%d, %10.4g, Threaded ij \n", Rowlen,  interval(time_start, time_stop));
    //printStuff(sol);

    //Threaded Ji
    for (x = 0; x<NUM_TESTS; x++) {
        iters = 0;
        setupbool();
        reset_sol();
        clock_gettime(CLOCK_REALTIME, &time_start);
        threadSetupji();
        clock_gettime(CLOCK_REALTIME, &time_stop);
    }
    
    printf("%d, %10.4g, Threaded ji \n", Rowlen,  interval(time_start, time_stop));
    //printStuff(sol);
    return 0;
}

void serial_SOR()
{
  data_t total_change = Rowlen*Rowlen, change;
  long int i, j;

  while ((total_change/(double)(Rowlen*Rowlen)) > (double)TOL) {
    test++;
    total_change = 0;
    for (i = 1; i < Rowlen-1; i++) {
      for (j = 1; j < Rowlen-1; j++) {
        change = data[i*Rowlen+j] - .25 * (data[(i-1)*Rowlen+j] +
                                          data[(i+1)*Rowlen+j] +
                                          data[i*Rowlen+j+1] +
                                          data[i*Rowlen+j-1]);
        data[i*Rowlen+j] -= change * OMEGA;
        if (change < 0){
          change = -change;
        }
        total_change += change;
      }
    }
    //printf("Diff: %f\n", total_change);
  }
}

void printStuff(data_t arr[])
{
    printf("\n");
    long int i, j;
    for (i = 0; i < Rowlen; i++) {
      for (j = 0; j < Rowlen; j++) {
          printf("%0.1f ", arr[i*Rowlen+j]);
      }
      printf("\n");
    }
    printf("\n");
}

void *thread_sor(){
  double  temp, accum;
  long int i, j;
  if (iters < test){
  pthread_mutex_lock(&lock);
  iters++;
  pthread_mutex_unlock(&lock);
    //for(iters = 0; iters < test; iters++){
        for (i = 1; i < Rowlen-1; i++) {
            for (j = 1; j < Rowlen-1; j++) {
                if (A_ready[(i-1)*Rowlen+j] == true && A_ready[i*Rowlen+(j-1)] == true){
                temp = sol[i*Rowlen+j];
                accum = .20 *         (sol[(i)*Rowlen+j] +
                                              sol[(i)*Rowlen+(j-1)] +
                                              sol[(i-1)*Rowlen+j] +
                                              sol[i*Rowlen+(j+1)] +
                                              sol[(i+1)*Rowlen+(j)]);
                pthread_mutex_lock(&lock);
                sol[(i)*Rowlen+j] = accum;
                A_ready[i*Rowlen+j] = true;
                pthread_mutex_unlock(&lock);
        }
      }
    //}
    //printf("Diff: %f\n", diff);
  }
  }
}

void setupbool()
{
    long int i, j;
    for (i = 0; i < Rowlen; i++) {
        for (j = 0; j < Rowlen; j++) {
            A_ready[i*Rowlen+j] = 0;
            if(i == 0 || i == Rowlen-1)
                A_ready[i*Rowlen+j] = 1;
            if(j == 0 || j == Rowlen-1)
                A_ready[i*Rowlen+j] = 1;
        
        }
    }
}

void setupdiff(){
    long int i, j;
    for (i = 0; i < Rowlen; i++) {
        for (j = 0; j < Rowlen; j++) {
            data[i*Rowlen+j] =(rand() % (10 - 0 + 1)) + 0;
        }
    }
}
void reset_sol(){
    long int i;
    for (i = 0; i < Rowlen*Rowlen; i++) {
        sol[i] = data[i];
    }
}

void threadSetup()
{
    int i;
    pthread_t tid[NUMTHREADS];
    for (i = 0; i < NUMTHREADS; i++)
        {pthread_create(&tid[i], NULL, thread_sor, NULL);}
    for (i = 0; i < NUMTHREADS; i++)
        {pthread_join(tid[i], NULL);}
}

void *thread_sorji(){
  double temp, accum;
  long int i, j;
  if (iters < test){
  pthread_mutex_lock(&lock);
  iters++;
  pthread_mutex_unlock(&lock);
    //for(iters = 0; iters < test; iters++){
        for (j = 1; j < Rowlen-1; j++) {
            for (i = 1; i < Rowlen-1; i++) {
                if (A_ready[(i-1)*Rowlen+j] == true && A_ready[i*Rowlen+(j-1)] == true){
                temp = sol[i*Rowlen+j];
                accum = .20 *         (sol[(i)*Rowlen+j] +
                                              sol[(i)*Rowlen+(j-1)] +
                                              sol[(i-1)*Rowlen+j] +
                                              sol[i*Rowlen+(j+1)] +
                                              sol[(i+1)*Rowlen+(j)]);
                 pthread_mutex_lock(&lock);
                 sol[(i)*Rowlen+j] = accum;
                 A_ready[i*Rowlen+j] = true;
                 pthread_mutex_unlock(&lock);
          }
      }
    //}
    //printf("Diff: %f\n", diff);
  }
  }
}

void threadSetupji()
{
    int i;
    pthread_t tid[NUMTHREADS];
    for (i = 0; i < NUMTHREADS; i++)
        {pthread_create(&tid[i], NULL, thread_sorji, NULL);}
    for (i = 0; i < NUMTHREADS; i++)
        {pthread_join(tid[i], NULL);}
}
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

/****************************************************************************/

/* To compile on the lab machines:
 
      gcc -O0 test_clock_gettime.c -lm -lrt -o test_clock_gettime
 
  Note that other machines, like your laptop, might not need -lrt option.
  Also, the -lm option is only needed if you use a math library routine,
  like sin() as suggested below.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <math.h>


/* -=-=-=-=- Time measurement by clock_gettime() -=-=-=-=- */
/*
  As described in the clock_gettime manpage (type "man clock_gettime" at the
  shell prompt), a "timespec" is a structure that looks like this:
 
        struct timespec {
          time_t   tv_sec;   // seconds
          long     tv_nsec;  // and nanoseconds
        };
 */

struct timespec diff(struct timespec start, struct timespec end)
{
  struct timespec temp;
  if ((end.tv_nsec-start.tv_nsec)<0) {
    temp.tv_sec = end.tv_sec-start.tv_sec-1;
    temp.tv_nsec = 1000000000+end.tv_nsec-start.tv_nsec;
  } else {
    temp.tv_sec = end.tv_sec-start.tv_sec;
    temp.tv_nsec = end.tv_nsec-start.tv_nsec;
  }
  return temp;
}
/*
     This method does not require adjusting a #define constant

  How to use this method:

      struct timespec time_start, time_stop;
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
      // DO SOMETHING THAT TAKES TIME
      clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);

      NOTE: calling the diff() function to determine the measurement
            is left as an exercise for the student

 */


/* -=-=-=-=- End of time measurement declarations =-=-=-=- */


int main(int argc, char *argv[])
{
  struct timespec time_start, time_stop, temp_time;
  long long int i, j, k;
  long long int time_sec, time_ns;
  double Calc;

  i = j = k = 0;

  /* get start time */
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_start);
  
  


  /* Here you should ADD YOUR OWN CODE and modify it until it takes about
   * one second to run. For example, figure out how many times the computer
   * can execute the sin(x) function inside a loop, where x changes each
   * time sin(x) is called, add up the values of sin(x).      
   
   This code takes directly from your example, adding up the values of sin(x) in the loop. I calculated the number of loops by starting with a very large number that created a 4.5sec run. I used this to scale the number of runs until it was within .0005 of 1 second             */
  for (long int limit = 21850000; limit >= 0; limit -= 1) {
  Calc += sin(limit);
  }

  /* get end time */
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time_stop);


  /* ADD CODE HERE to print something you computed in between the two calls
   * to clock_gettime, such as a sum. (to understand why, refer to the
   * test_O_level.c part of the assignment)                                */
  printf("Sum of Sin(x) is %f\n",Calc);


  /* compute elapsed time and print. */
  temp_time = diff(time_start,time_stop); 
  /* MODIFY: Add a call to the "diff()" function (which is defined above) as
   *         instructed in the lab0 instructions.                          */
  time_sec = temp_time.tv_sec; time_ns  = temp_time.tv_nsec; /* MODIFY: After you've called diff(), set these from the returned struct */


  printf("that took %ld sec and %ld nsec (%ld.%09ld sec)\n", time_sec, time_ns, time_sec, time_ns);

} /* end main() */


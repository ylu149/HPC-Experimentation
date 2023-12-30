/*****************************************************************

  gcc test_generic.c -o test_generic -std=gnu99

 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <pthread.h>
#include <errno.h>
#include <limits.h>
#include <signal.h>
#include <unistd.h>

/* The cast (int*) makes the type of pointer into an "int" type
   The *(int*) makes the variable into a pointer.  The way to read
   this is out-to-in.

   Once you get this basic structure, you can pass anything, as long as
   it has a defined starting address.  (You can even make the address
   itself the argument, but that's probably not a good idea.)               */

/******************************************************************************/
int main()
{
  int i;
  char c;
  float ArrayA[5] = {1.1, 2.2, 3.3, 4.4, 5.5};
  void *the_data;       /* generic pointer */

  i = 6;
  c = 'a';
  
  the_data = &ArrayA;       /* make ptr point to a memory location */
  printf("the_data points to the float value of the array %f\n", *(float*) the_data);
  printf("the_data points to the float value of the array %f\n", *((float*) the_data + 1));
  printf("the_data points to the float value of the array %f\n", *((float*) the_data + 2));
  the_data = &i;
  printf("the_data points to the integer value %d\n", *(int*) the_data);

  the_data = &c;       /* make ptr point to a different location */
  printf("the_data now points to the character %c\n", *(char*) the_data);

  /* MODIFY: use "the_data" to print out the contents of ArrayA */

  return 0;
}

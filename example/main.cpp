#include "algorithm_output.h"

int main(int argc, char **argv)
{
  float data[200] = {};
  float to_add[200] = {};

  test_dispatch_1(dispatch_ADD, data, to_add, 200);
  return 0;
}

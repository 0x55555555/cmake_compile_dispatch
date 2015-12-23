#pragma once
#include "algorithm_defs.h"

void test_dispatch_1(float *a, const float *b, std::size_t length)
{
  for (std::size_t i = 0; i < length; ++i)
  {
#if defined(ADD)
      a[i] += b[i];
#elif defined(MULTIPLY)
      a[i] *= b[i];
#elif defined(SUB)
      a[i] -= b[i];
#else
# error "No operation defined"
#endif
  }
}

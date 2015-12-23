

void pork(float *a, const float *b, std::size_t length)
{
  for (std::size_t i = 0; i < length; ++i)
  {
      a[i] += b[i];
  }
}

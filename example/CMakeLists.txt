
add_dispatcher_target(test_dispatch_1
  DEFINITIONS
    algorithm_defs.h
  SOURCE
    algorithm.h
  OUTPUT
    ${CMAKE_CURRENT_BINARY_DIR}/algorithm_output.h
  DISPATCHER_TYPE DispatchType
  DISPATCHERS
    dispatch_ADD
      -DADD
    dispatch_MULTIPLY
      -DMULTIPLY
    dispatch_SUB
      -DSUB
  ARGUMENTS "float *" "const float *" "std::size_t"
)

add_executable(test_dispatch
  main.cpp
  algorithm.h
)

target_link_libraries(test_dispatch
  PRIVATE
    test_dispatch_1
)

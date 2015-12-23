include(CMakeParseArguments)

# Storing this for use when configuring dispatchers in function call
set(SOURCE_DATA_DIR ${CMAKE_CURRENT_LIST_DIR})

# Call add_dispatcher to add a new dispatched function to your target.
# add_dispatcher(
#    target_name       # Target to add dispatcher to
#    NAME              # Name of the dispatcher function to create
#
#    DEFINITIONS       # Filename containing DISPATCHER_TYPE and required
#                      # predefinitions for dispatcher
#    SOURCE            # Filename containing source ${NAME} function,
#                      # to be wrapped in dispatchers
#    OUTPUT            # Filename to generate unifying wrapper in
#
#    DISPATCHERS       # List of pairs of enum value, to compile options,
#                      # used to build dispatch table.
#
#    DISPATCHER_TYPE   # Enum type used to dispatch function to
#    ARGUMENTS         # List of arguments to pass to the function
#    RETURN_TYPE       # Return type of the dispatcher (defaults to void).
#  )
function(add_dispatcher TARGET)
  # Extract options from ARGN
  set(options)
  set(oneValueArgs NAME DEFINITIONS SOURCE OUTPUT DISPATCHER_TYPE RETURN_TYPE)
  set(multiValueArgs DISPATCHERS ARGUMENTS)
  cmake_parse_arguments(DP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  # Check all arguments and apply defaults
  if(NOT TARGET)
    message(FATAL_ERROR "Required argument TARGET not specified.")
  endif()

  if(NOT DP_NAME)
    message(FATAL_ERROR "Required argument NAME not specified.")
  endif()
  set(NAME ${DP_NAME}) # rename this for use in configure_file

  if(NOT DP_SOURCE)
    message(FATAL_ERROR "Required argument SOURCE not specified.")
  endif()
  set(DISPATCHER_SOURCE ${DP_SOURCE}) # rename this for use in configure_file

  if(NOT DP_DEFINITIONS)
    message(FATAL_ERROR "Required argument DEFINITIONS not specified.")
  endif()
  set(DISPATCHER_HEADER ${DP_DEFINITIONS}) # rename this for use in configure_file

  if(NOT DP_OUTPUT)
    message(FATAL_ERROR "Required argument OUTPUT not specified.")
  endif()

  if(NOT DP_DISPATCHER_TYPE)
    message(FATAL_ERROR "Required argument DISPATCHER_TYPE not specified.")
  endif()

  if(NOT DP_DISPATCHERS)
    message(FATAL_ERROR "Required argument DISPATCHERS not specified.")
  endif()

  if(NOT DP_RETURN_TYPE)
    set(DP_RETURN_TYPE "void")
  endif()

  # Find and verify dispatcher list - expect pairs of arguments
  list(LENGTH DP_DISPATCHERS DISPATCHERS_LENGTH)
  math(EXPR DISPATCHERS_EVEN_CHECK "${DISPATCHERS_LENGTH}%2") # 1 here indicates missing pair partner...
  if (${DISPATCHERS_EVEN_CHECK} STREQUAL "1")
    message(FATAL_ERROR "Require dispatcher pairs to be passed, got odd number of items.")
  endif()
  # Find the max-index of the list of pairs, for iteration (ie, inclusive list range)
  math(EXPR DISPATCHERS_LENGTH "(${DISPATCHERS_LENGTH}/2)-1")


  set(SIGNATURE "")
  set(ARGUMENT_FORWARD "")
  set(DISPATCHER_SELECTION "")
  set(DISPATCHER_DEFINITIONS "")
  set(ARG_NUM 0)

  # Form strings for forwarding argument types to function
  # This loop builds up the above variables to forward and define
  # wrapper functions.
  foreach(ARGUMENT_TYPE ${DP_ARGUMENTS})
    if (NOT ${SIGNATURE} STREQUAL "")
      set(SIGNATURE "${SIGNATURE}, ")
      set(ARGUMENT_FORWARD "${ARGUMENT_FORWARD}, ")
    endif()

    set(SIGNATURE "${SIGNATURE}${ARGUMENT_TYPE} arg_${ARG_NUM}")
    set(ARGUMENT_FORWARD "${ARGUMENT_FORWARD}std::move(arg_${ARG_NUM})")
    math(EXPR ARG_NUM "${ARG_NUM}+1")
  endforeach()

  # For each dispatcher, build a dispatcher file
  foreach(DISPATCHER_INDEX RANGE ${DISPATCHERS_LENGTH})
    math(EXPR DISPATCHERS_ID_INDEX "${DISPATCHER_INDEX}*2")
    math(EXPR DISPATCHERS_OPTIONS_INDEX "${DISPATCHERS_ID_INDEX}+1")
    list(GET DP_DISPATCHERS ${DISPATCHERS_ID_INDEX} DISPATCHER_ID)
    list(GET DP_DISPATCHERS ${DISPATCHERS_OPTIONS_INDEX} DISPATCHER_OPTIONS)

    # Create the file for this dispatcher
    set(DISPATCHER_FILE "${CMAKE_CURRENT_BINARY_DIR}/${DISPATCHER_ID}.dispatcher.cpp")
    configure_file(${SOURCE_DATA_DIR}/dispatcher.cpp
      ${DISPATCHER_FILE}
      ESCAPE_QUOTES
    )

    # Add it to the target
    target_sources(${TARGET}
      PRIVATE
        ${DISPATCHER_FILE}
    )
    # Apply required properties to it.
    set_source_files_properties(${DISPATCHER_FILE} PROPERTIES COMPILE_FLAGS ${DISPATCHER_OPTIONS})

    # Append this dispatcher to the list of predefined dispatchers.
    set(DISPATCHER_DEFINITIONS "${DISPATCHER_DEFINITIONS}${DP_RETURN_TYPE} dispatch_${NAME}_${DISPATCHER_ID}(${SIGNATURE});\n")

    # Append this dispatcher to the list of case statements switching between dispatchers.
    set(DISPATCHER_SELECTION "${DISPATCHER_SELECTION}    case ${DP_DISPATCHER_TYPE}::${DISPATCHER_ID}: return dispatch_${NAME}_${DISPATCHER_ID}(${ARGUMENT_FORWARD});\n")
  endforeach()

  # Find the argument list of the output unifying dispatcher.
  set(SELECTOR_ARGUMENT "${DP_DISPATCHER_TYPE} selector_arg")
  set(DISPATCHER_BODY "  switch (selector_arg) {\n${DISPATCHER_SELECTION}  }")
  if (${SIGNATURE} STREQUAL "")
    set(SELECTOR_SIGNATURE "${SELECTOR_ARGUMENT}")
  else()
    set(SELECTOR_SIGNATURE "${SELECTOR_ARGUMENT}, ${SIGNATURE}")
  endif()

  # configure the dispatcher to call all created dispatcher files.
  configure_file(${SOURCE_DATA_DIR}/dispatcher_selection.h
    ${DP_OUTPUT}
    ESCAPE_QUOTES
  )

  target_sources(${TARGET}
    PRIVATE
      ${DP_OUTPUT}
  )
  message("Generated ${DP_OUTPUT}")
endfunction()

# Call add_dispatcher_target to create a new target containing a dispatcher,
#   using this variant ensures any compile options used are limited to the new target.
# add_dispatcher_target(
#    target_name       # Target to create.
#    DEFINITIONS       # Filename containing DISPATCHER_TYPE and required
#                      # predefinitions for dispatcher
#    SOURCE            # Filename containing source ${NAME} function,
#                      # to be wrapped in dispatchers
#    OUTPUT            # Filename to generate unifying wrapper in
#
#    DISPATCHERS       # List of pairs of enum value, to compile options,
#                      # used to build dispatch table.
#
#    DISPATCHER_TYPE   # Enum type used to dispatch function to
#    ARGUMENTS         # List of arguments to pass to the function
#    RETURN_TYPE       # Return type of the dispatcher (defaults to void).
#  )
function(add_dispatcher_target target_name)
  # Extract required options from ARGN
  set(options)
  set(oneValueArgs DEFINITIONS SOURCE OUTPUT)
  set(multiValueArgs)
  cmake_parse_arguments(DP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(NOT DP_SOURCE)
    message(FATAL_ERROR "Required argument SOURCE not specified.")
  endif()
  get_filename_component(SOURCE_INCLUDE_DIRECTORY ${DP_SOURCE} DIRECTORY)

  if(NOT DP_DEFINITIONS)
    message(FATAL_ERROR "Required argument DEFINITIONS not specified.")
  endif()
  get_filename_component(DEFINITIONS_INCLUDE_DIRECTORY ${DP_DEFINITIONS} DIRECTORY)

  if(NOT DP_OUTPUT)
    message(FATAL_ERROR "Required argument OUTPUT not specified.")
  endif()
  get_filename_component(OUTPUT_INCLUDE_DIRECTORY ${DP_OUTPUT} DIRECTORY)


  add_library(${target_name} STATIC
    ${DP_SOURCE}
    ${DP_DEFINITIONS}
  )

  target_include_directories(${target_name}
    PUBLIC
      "${OUTPUT_INCLUDE_DIRECTORY}"
    PRIVATE
      "${DEFINITIONS_INCLUDE_DIRECTORY}"
      "${SOURCE_INCLUDE_DIRECTORY}"
  )

  add_dispatcher(${target_name}
    NAME ${target_name}
    ${ARGN}
  )
endfunction()

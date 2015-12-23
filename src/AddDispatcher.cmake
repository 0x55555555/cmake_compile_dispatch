include(CMakeParseArguments)

function(add_dispatcher TARGET NAME)
  set(options)
  set(oneValueArgs DEFINITIONS SOURCE OUTPUT DISPATCHER_TYPE RETURN_TYPE)
  set(multiValueArgs DISPATCHERS ARGUMENTS)
  cmake_parse_arguments(DP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  # Argument parsing and defaults.
  if(NOT TARGET)
    message(FATAL_ERROR "Required argument TARGET not specified.")
  endif()

  if(NOT NAME)
    message(FATAL_ERROR "Required argument NAME not specified.")
  endif()

  if(NOT DP_SOURCE)
    message(FATAL_ERROR "Required argument SOURCE not specified.")
  endif()
  set(DISPATCHER_SOURCE ${DP_SOURCE})

  if(NOT DP_DEFINITIONS)
    message(FATAL_ERROR "Required argument DEFINITIONS not specified.")
  endif()
  set(DISPATCHER_HEADER ${DP_DEFINITIONS})

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


  set(SIGNATURE "")
  set(ARGUMENT_FORWARD "")
  set(DISPATCHER_SELECTION "")
  set(DISPATCHER_DEFINITIONS "")
  set(ARG_NUM 0)

  # Form strings for forwarding argument types.
  foreach(ARGUMENT_TYPE ${DP_ARGUMENTS})
    if (NOT ${SIGNATURE} STREQUAL "")
      set(SIGNATURE "${SIGNATURE}, ")
      set(ARGUMENT_FORWARD "${ARGUMENT_FORWARD}, ")
    endif()

    set(SIGNATURE "${SIGNATURE}${ARGUMENT_TYPE} arg_${ARG_NUM}")
    set(ARGUMENT_FORWARD "${ARGUMENT_FORWARD}std::move(arg_${ARG_NUM})")
    math(EXPR ARG_NUM "${ARG_NUM}+1")
  endforeach()

  message(${CMAKE_CURRENT_LIST_DIR})
  #message("Adding ${DP_SOURCE} to ${TARGET}")
  #message("Using arguments ${SIGNATURE}")
  #message("Using forwarder ${ARGUMENT_FORWARD}")

  list(LENGTH DP_DISPATCHERS DISPATCHERS_LENGTH)
  math(EXPR DISPATCHERS_EVEN_CHECK "${DISPATCHERS_LENGTH}%2")
  if (${DISPATCHERS_EVEN_CHECK} STREQUAL "1")
    message(FATAL_ERROR "Require dispatcher pairs to be passed, got odd number of items.")
  endif()

  math(EXPR DISPATCHERS_LENGTH "(${DISPATCHERS_LENGTH}/2)-1")
  foreach(DISPATCHER_INDEX RANGE ${DISPATCHERS_LENGTH})
    math(EXPR DISPATCHERS_ID_INDEX "${DISPATCHER_INDEX}*2")
    math(EXPR DISPATCHERS_OPTIONS_INDEX "${DISPATCHERS_ID_INDEX}+1")
    list(GET DP_DISPATCHERS ${DISPATCHERS_ID_INDEX} DISPATCHER_ID)
    list(GET DP_DISPATCHERS ${DISPATCHERS_OPTIONS_INDEX} DISPATCHER_OPTIONS)

    set(DISPATCHER_FILE "${CMAKE_CURRENT_BINARY_DIR}/${DISPATCHER_ID}.dispatcher.cpp")
    configure_file(${CMAKE_CURRENT_SOURCE_DIRECTORY}/dispatcher.cpp
      ${DISPATCHER_FILE}
      ESCAPE_QUOTES
    )

    target_sources(${TARGET}
      PRIVATE
        ${DISPATCHER_FILE}
    )
    set_source_files_properties(${DISPATCHER_FILE} PROPERTIES COMPILE_FLAGS ${DISPATCHER_OPTIONS})

    set(DISPATCHER_DEFINITIONS "${DISPATCHER_DEFINITIONS}${DP_RETURN_TYPE} dispatch_${NAME}_${DISPATCHER_ID}(${SIGNATURE});\n")

    set(DISPATCHER_SELECTION "${DISPATCHER_SELECTION}    case ${DP_DISPATCHER_TYPE}::${DISPATCHER_ID}: return dispatch_${NAME}_${DISPATCHER_ID}(${ARGUMENT_FORWARD});\n")
  endforeach()

  set(SELECTOR_ARGUMENT "${DP_DISPATCHER_TYPE} selector_arg")
  set(DISPATCHER_BODY "  switch (selector_arg) {\n${DISPATCHER_SELECTION}  }")
  if (${SIGNATURE} STREQUAL "")
    set(SELECTOR_SIGNATURE "${SELECTOR_ARGUMENT}")
  else()
    set(SELECTOR_SIGNATURE "${SELECTOR_ARGUMENT}, ${SIGNATURE}")
  endif()

  configure_file(dispatcher_selection.h
    ${DP_OUTPUT}
    ESCAPE_QUOTES
  )

  target_sources(${TARGET}
    PRIVATE
      ${DP_OUTPUT}
  )
  message("Generated ${DP_OUTPUT}")
endfunction()

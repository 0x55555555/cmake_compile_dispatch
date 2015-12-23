// Dispatcher for @NAME@ - @DISPATCHER_ID@
// Compiled with "@DISPATCHER_OPTIONS@"
#include <utility>

namespace {
#include "@DISPATCHER_SOURCE@"
}

@DP_RETURN_TYPE@ dispatch_@NAME@_@DISPATCHER_ID@(@SIGNATURE@)
{
  return @NAME@(@ARGUMENT_FORWARD@);
}

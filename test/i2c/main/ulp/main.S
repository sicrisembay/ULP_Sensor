#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "../../../../common/wake_up.S"
#include "../../../../common/m_stack.S"
#include "../../../../common/m_routine.S"
#include "../../../../i2c/i2c.S"

    /* Code goes into .text section */
    .text
    .global entry
entry:
    stack_init
    jump wake_up


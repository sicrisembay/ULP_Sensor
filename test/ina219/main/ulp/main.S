#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"
#include "m_stack.S"
#include "m_routine.S"

    .bss
    .global stackStart
stackStart:
    .skip 100
    .global stackEnd
stackEnd:
    .long 0

    /* Code goes into .text section */
    .text
    .global entry
entry:
    /* Initialize Stack */
    stack_init
    /* Simple Test Routine */
    rcall test_ina219
    jump wake_up

test_ina219:
    rcall ina219_init
    ret

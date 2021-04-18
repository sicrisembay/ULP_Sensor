#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "../../../../common/wake_up.S"
#include "../../../../common/m_stack.S"
#include "../../../../common/m_routine.S"

    .global upcount
upcount:
    .long 0

    .global downcount
downcount:
    .long 0

    /* Code goes into .text section */
    .text
    .global entry
entry:
    stack_init
    rcall test_routine_inc
    rcall test_routine_dec
    jump wake_up

/* Test Routine */
test_routine_inc:
    // upcount = upcount + 1;
    move r1, upcount
    ld r0, r1, 0
    add r0, r0, 1
    st r0, r1, 0
    ret

test_routine_dec:
    // downcount = downcount - 1;
    move r1, downcount
    ld r0, r1, 0
    sub r0, r0, 1
    st r0, r1, 0
    ret


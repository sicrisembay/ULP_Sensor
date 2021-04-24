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
    rcall test_i2c
    jump wake_up

    .set BMP180_ADDR,0x77 // 7-bit address
test_i2c:
    rcall i2c_start_cond
    move r1, BMP180_ADDR
    lsh r1, r1, 1
    rcall i2c_write_byte
    rcall i2c_stop_cond
    ret

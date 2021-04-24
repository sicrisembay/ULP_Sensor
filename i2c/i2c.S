/*
 * i2c
 * 
 * Note1: Based from pseudo code of i2c bit-bang found in
 *   https://en.wikipedia.org/wiki/I%C2%B2C
 *
 */
#include "sdkconfig.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"
#include "m_stack.S"
#include "m_routine.S"

#define SDA_RTC_GPIO    (CONFIG_ULP_I2C_SDA_IO)
#define SCL_RTC_GPIO    (CONFIG_ULP_I2C_SCL_IO)
/*
 * Macro: i2c_delay
 * Description: some delay
 * Affects: None
 */
.macro i2c_delay
    // Instruction: Wait cycle
    // Cycles: 2 + cycles, 4 cycles to fetch next instruction
    // Note: clock is 8MHz / (REG_CNTL_CK8M_DIV_SEL + 1)
    //       8MHz / 2 = 4MHz
    wait 4 // (2 + 4 + 4)(1/4MHz) = 2.5us
.endm


/*
 * Macro: read_SCL
 * Description: Read current level of SCL line
 * Affects: R0 (SCL level, 0/1)
 */
.macro read_SCL
    READ_RTC_REG(RTC_GPIO_IN_REG, RTC_GPIO_IN_NEXT_S + SCL_RTC_GPIO, 1)
.endm


/*
 * Macro: read_SDA
 * Description: Read current level of SDA line
 * Affects: R0 (SDA level, 0/1)
 */
.macro read_SDA
    READ_RTC_REG(RTC_GPIO_IN_REG, RTC_GPIO_IN_NEXT_S + SDA_RTC_GPIO, 1)
.endm


/*
 * Macro: set_SCL
 * Description: Set SCL to high impedance (pull-up)
 * Affects: None
 */
.macro set_SCL
    WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TC_REG, RTC_GPIO_ENABLE_W1TC_S + SCL_RTC_GPIO, 1, 1)
.endm


/*
 * Macro: clear_SCL
 * Description: Set SCL to Low
 * Affects: None
 */
.macro clear_SCL
    WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TS_REG, RTC_GPIO_ENABLE_W1TS_S + SCL_RTC_GPIO, 1, 1)
.endm


/*
 * Macro: set_SDA
 * Description: Set SDA to high impedance (pull-up)
 * Affects: None
 */
.macro set_SDA
    WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TC_REG, RTC_GPIO_ENABLE_W1TC_S + SDA_RTC_GPIO, 1, 1)
.endm


/*
 * Macro: clear_SDA
 * Description: Set SDA to Low
 * Affects: None
 */
.macro clear_SDA
    WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TS_REG, RTC_GPIO_ENABLE_W1TS_S + SDA_RTC_GPIO, 1, 1)
.endm


/*
 * Variable: i2c_started
 * Description: indicates that i2c transaction has started
 */
    .bss
i2c_started:
    .long 0


/*
 * Variable: i2c_init_done
 * Description: initialization done flag
 */
    .bss
i2c_init_done:
    .long 0


/*
 * Routine: i2c_start_cond
 * Description: Master I2C Start
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * STACK (R3) --> Caller return address
 */
    .text
    .global i2c_start_cond
i2c_start_cond:
    /* Check i2c_init_done flag */
    move r1, i2c_init_done
    ld r0, r1, 0
    jumpr done_init, 1, ge
    /*
     * Not yet Inited
     * 1. i2c_init_done = 1
     * 2. Init by pulling SDA and SCL low
     */
    move r0, 1
    st r0, r1, 0
    WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + SCL_RTC_GPIO, 1, 0)
    WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + SDA_RTC_GPIO, 1, 0)
done_init:
    move r1, i2c_started
    ld r0, r1, 0
    jumpr not_started, 1, lt
    /*
     * Already started, do a restart condition
     */
    set_SDA
    i2c_delay
    set_SCL
start_clock_stretch:
    read_SCL  // SCL Level --> R0
    jumpr start_clock_stretch, 1, lt
    i2c_delay
    i2c_delay
not_started:
    read_SDA  // SDA level --> R0
    /// TODO: if SDA is 0, we lost in arbitration
    /// Note: Supports only one master in bus. Do not expect any loss in arbitration

    /*
     * SCL is high, set SDA from 1 to 0.
     */
    clear_SDA
    i2c_delay
    clear_SCL
    /* Set i2c_started flag */
    move r1, i2c_started
    move r0, 1
    st r0, r1, 0

    /*
     * pops return address from stack to R2
     */
    ret


/*
 * Routine: i2c_stop_cond
 * Description: Master I2C Stop Condition
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * STACK (R3) --> Caller return address
 */
    .text
    .global i2c_stop_cond
i2c_stop_cond:
    clear_SDA
    i2c_delay
    set_SCL
stop_clock_stretch:
    read_SCL  // SCL Level --> R0
    jumpr stop_clock_stretch, 1, lt

    i2c_delay
    set_SDA
    i2c_delay
    read_SDA
    /// TODO: if SDA is 0, we lost in arbitration
    /// Note: Supports only one master in bus. Do not expect any loss in arbitration

    /* Clear i2c_started flag */
    move r1, i2c_started
    move r0, 0
    st r0, r1, 0

    /*
     * pops return address from stack to R2
     */
    ret


/*
 * Routine: i2c_write_bit
 * Description: Write a bit to I2C bus
 * Affects: R0, R2 (LR), R3(STACK)
 *
 * R0 --> bit to write 
 * STACK (R3) --> Caller return address
 */
    .text
i2c_write_bit:
    jumpr i2c_write_bit0, 1, lt
    set_SDA
    jump i2c_write_bit_done
i2c_write_bit0:
    clear_SDA
i2c_write_bit_done:
    /* SDA change propagation delay */
    i2c_delay
    /* Set SCL high to indicate a new valid SDA value is available */
    set_SCL
    i2c_delay
write_bit_clock_stretch:
    read_SCL  // SCL Level --> R0
    jumpr write_bit_clock_stretch, 1, lt

    clear_SCL
    /*
     * pops return address from stack to R2
     */
    ret


/*
 * Routine: i2c_read_bit
 * Description: Read a bit from I2C bus
 * Affects: R0, R2 (LR), R3(STACK)
 *
 * Input:
 *    None
 * Return
 *    R0 : bit read
 *
 * STACK (R3) --> Caller return address
 */
    .text
i2c_read_bit:
    set_SDA
    i2c_delay
    set_SCL
read_bit_clock_stretch:
    read_SCL  // SCL Level --> R0
    jumpr read_bit_clock_stretch, 1, lt

    i2c_delay
    read_SDA  // SDA Level --> R0
    clear_SCL
    ret


/*
 * Routine: i2c_write_byte
 * Description: Write a byte to I2C bus.  Return 0 in R0 if ack by the slave
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    R1 : Byte to Write
 * Return
 *    R0 : ACK (0)
 *
 * STACK (R3) --> Caller return address
 */
    .text
    .global i2c_write_byte
i2c_write_byte:
    stage_rst
i2c_write_next_bit:
    and r0, r1, 0x80
    rcall i2c_write_bit
    lsh r1, r1, 1
    stage_inc 1
    jumps i2c_write_next_bit, 8, lt

    /* Read Ack bit to R0 */
    rcall i2c_read_bit
    ret


/*
 * Routine: i2c_read_byte
 * Description: Read a byte from I2C bus.
 * Affects: R0, R1, R2 (LR), R3(STACK)
 *
 * Input:
 *    R1 : Acknowledge Slave after Read (0: ACK , 1: NOACK)
 * Return
 *    R0 : Byte read from bus
 *
 * STACK (R3) --> Caller return address
 */
    .text
    .global i2c_read_byte
i2c_read_byte:
    push r1
    move r1, 0
    stage_rst
i2c_read_next_bit:
    rcall i2c_read_bit  // Read bit in R0
    lsh r1, r1, 1       // r1 = (r1 << 1) | r0
    or r1, r1, r0
    stage_inc 1
    jumps i2c_read_next_bit, 8, lt

    /* Pop ack bit from stack */
    pop r0
    rcall i2c_write_bit
    /* return read byte in R0 */
    move r0, r1
    ret


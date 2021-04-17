/*
 * Stack Macros
 * 
 * Note1: R3 is used as stack pointer
 *
 */


/*
 * Push element in rx to stack
 */
.macro push rx
    st  \rx, r3, 0
    sub  r3, r3, 1
.endm


/*
 * Pop element from stack to rx
 */
.macro pop rx
    add  r3, r3, 1
    st  \rx, r3, 0
.endm
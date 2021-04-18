/*
 * Stack Macros
 * 
 * Note1: ULP assembly files are passed through C preprocessor first, so include directives
 * and C macros may be used in these files
 *
 * Note2: R3 is used as stack pointer
 *
 */

    .global stackStart
stackStart:
    .skip 100
    .global stackEnd
stackEnd:
    .long 0

/*
 * Initialize stack pointer
 */
.macro stack_init
    move r3, stackEnd
.endm

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
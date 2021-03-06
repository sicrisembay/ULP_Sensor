/*
 * Routine Macros
 *
 * Note1: ULP assembly files are passed through C preprocessor first, so include directives
 * and C macros may be used in these files
 */

/*
 * Call Routine Macro
 *
 * Description:
 *   1. Calculates the return address (r2)
 *   2. Push return address to stack (r3)
 *   3. Jump to routine
 *
 * Affected: r2, r3
 */
.macro rcall routine
    .set _retAddr2, (. + 16)
    move r2, _retAddr2
    push r2
    jump \routine
.endm


/*
 * Return from Routine Macro
 *   1. Pop return address from stack (r3) to r2
 *   2. Jump to return address
 *
 * Affected: r2, r3
 */
.macro ret
    pop  r2
    jump r2
.endm

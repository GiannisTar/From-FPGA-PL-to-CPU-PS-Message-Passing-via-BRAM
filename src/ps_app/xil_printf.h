// Minimal stub for xil_printf.h to allow local editing and simple builds.
// In Vitis, use the real xil_printf provided by the Xilinx BSP.

#ifndef XIL_PRINTF_H
#define XIL_PRINTF_H

#include <stdio.h>
#include <stdarg.h>

static inline int xil_printf(const char *format, ...) {
    va_list args;
    va_start(args, format);
    int r = vprintf(format, args);
    va_end(args);
    return r;
}

#endif // XIL_PRINTF_H

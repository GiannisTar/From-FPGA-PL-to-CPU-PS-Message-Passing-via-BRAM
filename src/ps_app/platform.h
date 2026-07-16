// Minimal stub for platform.h to allow local editing of main.c
// This file is NOT the full Vitis/Xilinx BSP header. It provides small
// prototypes so the file can be opened/inspected outside Vitis.

#ifndef PLATFORM_H
#define PLATFORM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

// Minimal platform init/cleanup used in the example app
static inline void init_platform(void) {
    // no-op stub for editor; real implementation comes from BSP in Vitis
}

static inline void cleanup_platform(void) {
    // no-op stub for editor; real implementation comes from BSP in Vitis
}

#ifdef __cplusplus
}
#endif

#endif // PLATFORM_H

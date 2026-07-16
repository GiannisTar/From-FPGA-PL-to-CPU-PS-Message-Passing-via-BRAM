#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

// Confirmed BRAM base address (from Address Editor)
#define BRAM_BASE_ADDR 0x40000000U
// Current BRAM size as assigned in the Address Editor (8 KB)
#define BRAM_SIZE_BYTES 8192U
// Read/print in chunks to avoid large local buffers
#define READ_CHUNK_SIZE 1024U

int main()
{
    init_platform();
    xil_printf("PS baremetal app starting...\n");

    volatile unsigned int * bram = (unsigned int *)BRAM_BASE_ADDR;

    while (1) {
        unsigned int len = bram[0];
        if (len > 0) {
            if (len >= BRAM_SIZE_BYTES) {
                xil_printf("Warning: reported message length (%u) >= BRAM capacity (%u). Truncating.\n", len, BRAM_SIZE_BYTES);
                len = BRAM_SIZE_BYTES - 4; // leave room for length word
            }

            xil_printf("Message received, length=%u\n", len);

            unsigned int remaining = len;
            unsigned int offset = 0;
            char chunk[READ_CHUNK_SIZE + 1];

            while (remaining > 0) {
                unsigned int to_read = (remaining < READ_CHUNK_SIZE) ? remaining : READ_CHUNK_SIZE;
                for (unsigned int i = 0; i < to_read; ++i) {
                    chunk[i] = ((volatile unsigned char *)bram)[4 + offset + i];
                }
                chunk[to_read] = '\0';
                xil_printf("%s", chunk); // print chunk without extra newline
                remaining -= to_read;
                offset += to_read;
            }
            xil_printf("\n");

            // Clear length to indicate message consumed
            bram[0] = 0;
        }
    }

    cleanup_platform();
    return 0;
}

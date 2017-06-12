
#include <stdio.h>
#include <stdarg.h>
#include "pixmap.h"

int
main(int ac, char **av)
{
    int         x, y, xs, ys, i;

    msg("Hello.\n");
    pixmap_init();
    msg("Still here.\n");

    for(i=0; i<1000; i++) {
        x = (rand()&0xfffff) % 600;
        y = (rand()&0xfffff) % 100;
        xs = (rand()&0xfffff) % (640-x);
        ys = (rand()&0xfffff) % (300-y);
        pixmap_setcolor_rect(fb, rand()&0xffff, x, y, xs, ys);
    }
    msg("Still here.\n");
}



#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <signal.h>
#include <sys/io.h>

/*  set_dac.c 
 *  
 *  Func:   set_dac.c uses the RTS and DTR pins of a serial device found at /dev/ttyS1 to 
 *          set the power levels of the DAC. 
 *          DTR is used as the clock signal SCL
 *          RTS is used as the data signal SDA
 *          Please refer to the Max521 specs page for more information on SCL, SDA.
 *
 *  Usage:  set_dac <dac number> <dac power level>
 *          <dac number> should be between 0-15 and indicate which dac to set.
 *          <dac power level> should be between 0-255 and indicate the power level to set.
 *  
 *  Author: Wonsop Sim
 *
 *  Date:   July 28, 2004
 */

//implements a <count> microsecond delay by reading from a slow I/O port.
void delay (int count)
{
    volatile int x;
    int i;
    for(i=0; i<count; i++)
        x = inb(0x40);       // safe slow I/O port to read
}


int main (int argc, char **argv)
{
    int dac_arg;
    int dac_adr;
    int dac_num;
    int pow_lvl;
    int fd;
    int flags;
    int i;
    int count = 5;

    //grab command line arguments
    dac_arg = atoi(argv[1]);
    pow_lvl = atoi(argv[2]);

    //check to make sure arguments are in the correct range
    if (dac_arg >= 0 && dac_arg < 8) {
        dac_adr = 0;
        dac_num = dac_arg;}
    else if (dac_arg >= 8 && dac_arg < 16) {
        dac_adr = 3;
        dac_num = dac_arg - 8;}
    else {
        fprintf(stderr, "DAC address must be in range 0-15\n");
        exit(1);}
    if (pow_lvl < 0 || pow_lvl > 255) {
        fprintf(stderr, "Power level must be in range 0-255\n");
        exit(1);}
    
    //add in factory set bits to the address
    dac_adr = (dac_adr * 2) + 80;

    //open the device
    if ((fd = open("/dev/ttyS1", O_RDWR | O_NDELAY)) < 0) {
        fprintf(stderr, "device not found");
        exit(1);}

    //enable I/O port controls
    iopl(3);

    //get line bits for serial port
    ioctl(fd, TIOCMGET, &flags);

    //make sure RTS and DTR lines are high
    flags &= ~TIOCM_RTS;
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    
    //do start condition 
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);

    //do address byte
    for (i = 7; i >=0; i--) {
        if ((dac_adr >> i) & 1)
            flags &= ~TIOCM_RTS;
        else
            flags |= TIOCM_RTS;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
        flags &= ~TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
        flags |= TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
    }
    //acknowledge bit
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);

    //do command byte
    for (i = 7; i >=0; i--) {
        if ((dac_num >> i) & 1)
            flags &= ~TIOCM_RTS;
        else
            flags |= TIOCM_RTS;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
        flags &= ~TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
        flags |= TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
    }
    //acknowledge bit
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    
    //do output byte
    for (i = 7; i >=0; i--) {
        if ((pow_lvl >> i) & 1)
            flags &= ~TIOCM_RTS;
        else
            flags |= TIOCM_RTS;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
        flags &= ~TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
        flags |= TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        delay(count);
    }

    //acknowledge bit
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);

    //do stop condition
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);
    flags &= ~TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    delay(count);

    close(fd);
    
    return 0;

}

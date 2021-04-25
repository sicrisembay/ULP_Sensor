# Test I2C
This is a simple test to verify I2C routine.  BMP180 device is used in this test.

# Build
Follow the following steps to build this test.
1. Create symbolic link
```
    $ ./asm_symlink.sh
```
2. Build and flash to board
```
    $ make menuconfig
    $ make -j8
    $ make -j8 flash monitor
```
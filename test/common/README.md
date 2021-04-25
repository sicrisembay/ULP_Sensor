# Test Common
This is a simple test to verify common macro and routine.
This are:
+ m_stack.S
+ m_routine.S
+ wake_up.S

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
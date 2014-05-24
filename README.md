# lx9micro \+ pmodAD2 \+ pmodACL \+ pmodBT2 #
*building a 4-channel, 3-axis accelerometer evaluation system*

Please, refer to [phealth @ liubenyuan](http://liubenyuan.github.io/phealth.html) for more details.

## phealth -- architecture ##

![Lx9 Microboard for healthcare](http://liubenyuan.github.io/pics/lx9health.png)

FPGA captures 3-axis accelerometer reads from `ADXL345`, 4-channel biosignals from `AD7991`. These recordings are transferred to PC via USB2UART using `CP2102`, or remotely via a bluetooth device `RN-42`.

Two peripherals are used, which are I2C and UART. SPI may also be used if we utilize the 4-wire connection of ADXL345. Those codes, `i2c_master.vhd` and `uart.vhd` are publicity available, and borrowed from [I2C master @ eewiki](http://eewiki.net/pages/viewpage.action?pageId=10125324) and [uart @ gabennett](https://github.com/pabennett/uart).

FPGA, is simply a *logic wrapper* of all the auxiliary peripherals.


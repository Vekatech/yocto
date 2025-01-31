#!/usr/bin/python3

# Imports
import argparse
import os
import sys
import serial

from tqdm import tqdm
from flasher.flashboot import CUBootFlasher


BOARD_DEFAULT = "vkrzg2lc"

def main():

     __script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))

     print(__script_dir)

     argparser = argparse.ArgumentParser(
         description="Utility to flash VK-RZ Boards.\n",
     )

     # Add arguments
     # select board
     argparser.add_argument(
         "--board",
         default=f"{BOARD_DEFAULT}",
         dest="board",
         action="store",
         type=str,
         help="Select board: vkrzv2l/vkrzg2l/vkrzg2lc/vkrzg2ul/vkrzfive/vkcmg2lc/vk-d184280e",
     )

     # Serial port arguments
     argparser.add_argument(
         "--serial_port",
         default="/dev/ttyUSB0",
         dest="serialPort",
         action="store",
         help="Serial port used to talk to board (defaults to: /dev/ttyUSB0)",
     )

     # Target
     argparser.add_argument(
         "--qspi",
         action="store_true",
         help="Flash to QSPI (default is eMMC)",
     )

     argparser.add_argument(
         "--debug", 
         action="store_true", 
         help="Enable debug output (buffer printing)"
     )


     __args = argparser.parse_args()

    
     try:
         __serial_port = serial.Serial(port=__args.serialPort, baudrate=115200)
     except Exception as e:  # pylint: disable=broad-exception-caught
         die(
             msg=(
                 f"Unable to open serial port. Error: {e}\n"
            )
        )

     flasher = CUBootFlasher(
        serial_port=__serial_port, 
        script_path=__script_dir, 
        board=__args.board, 
        qspi=__args.qspi, 
        debug=__args.debug
     )

     print( __args.board, __args.serialPort)

     if not flasher.check_bootloader_files():
         die(
             msg=(
                 f"Unable to find image files!\n"
            )
        )

     # Wait for device to be ready to receive image.
     print("Please power on the board, make it to boot from SCIF0 and reset it.")

     with tqdm(total=1) as progress_bar:
         __serial_port.read_until("please send !".encode())
         progress_bar.update(1)

     print("Flashing bootloader, this will take a few minutes...")

     with tqdm(total=4) as progress_bar:
         flasher.download_flash_writer()
         progress_bar.update(1)

         if flasher.qspi:
             flasher.flash_bootloader_qspi(progress_bar)
         else:
             flasher.flash_bootloader_emmc(progress_bar)

     print("Done flashing bootloader!")

def die(msg="", code=1):
    """
    Prints an error message and exits the program with the given exit code.
    """
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(code)


if __name__ == "__main__":
    main()

#!/usr/bin/python3

# Imports
import argparse
import os
import sys
import serial

from flasher.flashimg import CImageFlasher


BOARD_DEFAULT = "vkrzg2lc"
REL_IMAGE_PATH_DEFAULT = "images"
CORE_IMAGE_FILE_DEFAULT = "debian-bookworm-vkrzg2lc.img"

def main():

    __script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))

    print(__script_dir)

    argparser = argparse.ArgumentParser(
        description="Utility to flash rootfs image on VK Boards.\n"
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
     
     # Images
    argparser.add_argument(
        "--image_rootfs",
        dest="image_rootfs",
        default=f"{CORE_IMAGE_FILE_DEFAULT}",
        action="store",
        type=str,
        help="Path to rootfs.",
    )

    argparser.add_argument(
        "--image_path",
        default=f"{__script_dir}/{REL_IMAGE_PATH_DEFAULT}/{BOARD_DEFAULT}",
        dest="image_path",
        action="store",
        type=str,
        help=(
            "Absolute path to images dir"
        ),
    )

    # Networking
    argparser.add_argument(
        "--static_ip",
        default="",
        dest="staticIP",
        action="store",
        help="IP Address assigned to board during flashing",
    )

    # Target
    argparser.add_argument(
        "--udp",
        action="store_true",
        help="Flash using udp (default is USB).",
        )

    argparser.add_argument(
        "--debug", action="store_true", help="Enable debug output (buffer printing)"
        )

    __args = argparser.parse_args()


    print("Power on board. Make sure it's booting NOT from SCIF0.")
    print("Waiting for device...")

    
    try:
         __serial_port = serial.Serial(port=__args.serialPort, baudrate=115200)
    except Exception as e:  # pylint: disable=broad-exception-caught
         die(
             msg=(
                 f"Unable to open serial port. Error: {e}\n"
            )
        )

    flasher = CImageFlasher(
        serial_port=__serial_port, 
        script_path=__script_dir, 
        board=__args.board,
        core_image=__args.image_rootfs,
        udp=__args.udp, 
        debug=__args.debug
    )
            
    print( __args.board, __args.serialPort)
    
    
    flasher.write_system_image()





def die(msg="", code=1):
    """
    Prints an error message and exits the program with the given exit code.
    """
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(code)


if __name__ == "__main__":
    main()
#!/usr/bin/python3

# Imports
import os
import sys
import time
import zipfile
from subprocess import PIPE, Popen

import serial

BOARD_DEFAULT = "vkrzg2lc"
REL_IMAGE_PATH_DEFAULT = "images"
CORE_IMAGE_FILE_DEFAULT = "debian-bookworm-vkrzg2lc.img"



class CImageFlasher:
    def __init__(self, serial_port, script_path, board=f"{BOARD_DEFAULT}", core_image=f"{CORE_IMAGE_FILE_DEFAULT}", staticIP=None, udp=False, debug=False):
        
        self.__script_dir = script_path
        
        self.__serial_port = serial_port

        self.board = board

        self.staticIP = staticIP

        self.udp = udp

        self.debug = debug
        
        self.rootfs_image = f"{script_path}/{REL_IMAGE_PATH_DEFAULT}/{self.board}/{core_image}"
        
        self.fastboot = None
        
        
    def log(self, msg=""):
        if self.debug:
            print(f"{msg}")

    def write_serial_cmd(self, cmd, prefix=""):
        self.__serial_port.write(f"{prefix}{cmd}\r".encode())

    def write_file_to_serial(self, file):
        with open(file, "rb") as transmit_file:
            self.__serial_port.write(transmit_file.read())
            transmit_file.close()

    def wait_for_serial_read(self, cond="\n"):
        buf = self.__serial_port.read_until(cond.encode())

        self.log(buf.decode())

        return buf
        
    # Function to check and extract adb
    def __get_fastboot(self, sdk_path=None):
    
        if sdk_path is None:
            sdk_dir = self.__script_dir
        else:
            sdk_dir = sdk_path
            
        self.fastboot = None
        
        archive_path = ""
        # Extract platform tools if not already extracted
        if not os.path.exists(f"{sdk_dir}/platform-tools"):
            if sys.platform == "linux":
                archive_path = f"{sdk_dir}/adb/platform-tools-latest-linux.zip"
            elif sys.platform == "darwin":
                archive_path = f"{sdk_dir}/adb/platform-tools-latest-darwin.zip"
            elif sys.platform == "win32":
                archive_path = f"{sdk_dir}/adb/platform-tools-latest-windows.zip"
            else:
                self.log("Unknown platform.")
                return False

        if not os.path.isfile(archive_path):
            self.log("Can't find adb for your system. \
                This util expects to be ran from the flash_img.py dir.")
            return False    

        with zipfile.ZipFile(archive_path, "r") as zip_ref:
            zip_ref.extractall(f"{sdk_dir}/adb")
            
        self.fastboot = f"{sdk_dir}/adb/platform-tools/fastboot"

        if sys.platform != "win32":
            os.chmod(self.fastboot, 755)
            
        return True
            

    def write_system_image(self):
        if not os.path.isfile(self.rootfs_image):
            self.log(f"Missing system image: {self.rootfs_image}")
            return False
        
        if self.fastboot is None:
            if not self.__get_fastboot():
                return False
            

        # Interrupt boot sequence
        self.log("Waiting for device...")
        self.__serial_port.read_until("Hit any key to stop autoboot:".encode())
        self.write_serial_cmd("y")

        time.sleep(1)

        # Set static ip or attempt to get ip from dhcp

        if self.udp:
            if self.staticIP:
                self.log(f"Setting static IP: {self.staticIP}")
                self.write_serial_cmd(f"\rsetenv ipaddr {self.staticIP}")
            else:
                self.log("Waiting for device to be assigned IP address...")
                self.write_serial_cmd("\rsetenv autoload no; dhcp")
                self.__serial_port.read_until("DHCP client bound".encode())
        else:
            self.log(f"Setting serial #: {self.board}")
            self.write_serial_cmd(f"\rsetenv serial# {self.board}")

        time.sleep(1)

        # Put device into fastboot mode
        self.log("Putting device into fastboot mode")
        if self.udp:
            self.write_serial_cmd("\rfastboot udp")
            self.__serial_port.read_until("Listening for fastboot command on ".encode())
            self.log("Device in fastboot mode")
            self.__device_ip_address = (
                self.__serial_port.readline().decode().replace("\n", "").replace("\r", "")
                )
            fastboot_cmd = f"-s udp:{self.__device_ip_address} -v"
        else:
            self.write_serial_cmd("\rfastboot usb 1")
            fastboot_cmd = f"-s {self.board} -v"

        fastboot_args = f"{fastboot_cmd} flash rawimg {self.rootfs_image}"

        with Popen(
            self.fastboot + " " + fastboot_args,
            shell=True,
            stdout=PIPE,
            bufsize=1,
            universal_newlines=True,
        ) as fastboot_process:
            for line in fastboot_process.stdout:
                print(line, end="")

        if fastboot_process.returncode != 0:
            self.log("Failed to flash rootfs.")
            return False
        
        return True



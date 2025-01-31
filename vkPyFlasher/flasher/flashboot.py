#!/usr/bin/python3
import os
import sys
import serial

BOARD_DEFAULT = "vkrzg2lc"
REL_IMAGE_PATH_DEFAULT = "images"
FW_FILE_PFX="Flash_Writer_SCIF_"
BL2_FILE_PFX="bl2_bp_"
FIP_FILE_PFX="fip_"
QSPI_FILE_SFX="-sf"

class CUBootFlasher:
    def __init__(self, serial_port, script_path, board=f"{BOARD_DEFAULT}", qspi=False, debug=False ):
        self.__serial_port = serial_port

        self.board = board

        self.image_path = f"{script_path}/{REL_IMAGE_PATH_DEFAULT}/{self.board}"

        self.qspi = qspi

        self.debug = debug

        self.flash_writer_image_prefix = f"{FW_FILE_PFX}{self.board}"

        self.flash_writer_image = f"{self.image_path}/{self.flash_writer_image_prefix}.mot"

        for file in os.listdir(self.image_path):
            if file.upper().startswith(self.flash_writer_image_prefix.upper()):
                self.flash_writer_image = f"{self.image_path}/{file}"
                break

        self.bl2_image = f"{self.image_path}/{BL2_FILE_PFX}{self.board}.srec"
        self.fip_image = f"{self.image_path}/{FIP_FILE_PFX}{self.board}.srec"

        self.bl2_image_qspi = f"{self.image_path}/{BL2_FILE_PFX}{self.board}{QSPI_FILE_SFX}.srec"
        self.fip_image_qspi = f"{self.image_path}/{FIP_FILE_PFX}{self.board}{QSPI_FILE_SFX}.srec"
        
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

    def __serial_port_speedup(self):
        self.write_serial_cmd("sup")
        self.wait_for_serial_read("Please change to 921.6Kbps baud rate setting of the terminal.")
        self.__serial_port.baudrate=921600
        #self.__serial_port.write("\r".encode())
        #self.wait_for_serial_read(">", print_buffer=self.__args.debug)

    def __serial_port_speeddn(self):
        self.write_serial_cmd("sud")
        self.wait_for_serial_read("Please change to 115.2Kbps baud rate setting of the terminal.")
        self.__serial_port.baudrate=115200
        #self.__serial_port.write("\r".encode())
        #self.wait_for_serial_read(">", print_buffer=self.__args.debug)


    def check_bootloader_files(self):
        if not os.path.isfile(self.flash_writer_image):
            self.log(f"Missing flash writer image: {self.flash_writer_image}")
            return False


        if not self.qspi:
            if not os.path.isfile(self.bl2_image):
                self.log(f"Missing bl2 image: {self.bl2_image}")
                return False

            if not os.path.isfile(self.fip_image):
                self.log(f"Missing FIP image: {self.fip_image}")
                return False
        else:
            if not os.path.isfile(self.bl2_image_qspi):
                self.log(f"Missing qspi bl2 image: {self.bl2_image_qspi}")
                return False

            if not os.path.isfile(self.fip_image_qspi):
                self.log(f"Missing qspi fip image: {self.fip_image_qspi}")
                return False

        return True

    def download_flash_writer(self):
        self.write_file_to_serial(self.flash_writer_image)
        self.wait_for_serial_read(">")
        self.write_serial_cmd("")

    def flash_erase_emmc(self):
        self.write_serial_cmd("EM_E")
        self.wait_for_serial_read(">")
        self.write_serial_cmd("1")
        self.wait_for_serial_read(">")

    def flash_bl2_image_emmc(self):
        self.write_serial_cmd("EM_W")

        self.wait_for_serial_read(">")
        self.write_serial_cmd("1")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("1")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("11E00")

        self.wait_for_serial_read("please send !")
        self.write_file_to_serial(self.bl2_image)
        self.wait_for_serial_read("EM_W Complete!")

    def flash_fip_image_emmc(self):
        self.write_serial_cmd("EM_W")

        self.wait_for_serial_read(")>")
        self.write_serial_cmd("1")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("100")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("00000")

        self.wait_for_serial_read("please send !")
        self.write_file_to_serial(self.fip_image)
        self.wait_for_serial_read("EM_W Complete!")

    def setup_emmc_flash(self):
        self.write_serial_cmd("EM_SECSD")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("b1")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("2")
        self.wait_for_serial_read(">")
        self.write_serial_cmd("EM_SECSD")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("b3")
        self.wait_for_serial_read(":")
        self.write_serial_cmd("8")

    def flash_bootloader_emmc(self, progress_bar=None):
        if not self.check_bootloader_files():
            return False

        self.flash_erase_emmc()
                
        if progress_bar is not None:
            progress_bar.update(1)

        self.__serial_port_speedup()
        self.flash_bl2_image_emmc()
        
        if progress_bar is not None:
            progress_bar.update(1)

        self.flash_fip_image_emmc()
        self.setup_emmc_flash()
        
        if progress_bar is not None:
            progress_bar.update(1)

        self.__serial_port_speeddn()
        return True

    def flash_erase_qspi(self):
        self.write_serial_cmd("XCS")
        self.wait_for_serial_read("Clear OK?(y/n)")
        self.write_serial_cmd("y")
        self.log("Erasing SPI Flash...")
        self.wait_for_serial_read(">")

    def flash_bl2_image_qspi(self, erased=False):
        self.write_serial_cmd("XLS2")

        self.wait_for_serial_read("Please Input : H'")
        self.write_serial_cmd("11E00")

        self.wait_for_serial_read("Please Input : H'")
        self.write_serial_cmd("00000")

        self.wait_for_serial_read("please send !")

        self.write_file_to_serial(self.bl2_image_qspi)

        self.__serial_port.timeout = 2
        respond = self.wait_for_serial_read(">")
        self.__serial_port.timeout = None
        self.log (f"respond: {respond.decode()}")
        if b'(y/n)' in respond:
             self.write_serial_cmd("y")
             self.wait_for_serial_read(">")  

    def flash_fip_image_qspi(self):
        self.write_serial_cmd("XLS2")

        self.wait_for_serial_read("Please Input : H'")
        self.write_serial_cmd("00000")

        self.wait_for_serial_read("Please Input : H'")
        self.write_serial_cmd("1D200")

        self.wait_for_serial_read("please send")

        self.write_file_to_serial(self.fip_image_qspi)
        
        self.__serial_port.timeout = 2
        respond = self.wait_for_serial_read(">")
        self.__serial_port.timeout = None
        self.log (f"respond: {respond.decode()}")
        if b'(y/n)' in respond:
             self.write_serial_cmd("y")
             self.wait_for_serial_read(">")  

    def flash_bootloader_qspi(self, progress_bar=None, erase=False):
        
        if not self.check_bootloader_files():
            return False
            
        if erase:
            self.flash_erase_qspi()
            
        if progress_bar is not None:
            progress_bar.update(1)
        
        self.__serial_port_speedup()
        self.flash_bl2_image_qspi()
        
        if progress_bar is not None:
            progress_bar.update(1)
        
        self.flash_fip_image_qspi()
        
        if progress_bar is not None:
            progress_bar.update(1)
        
        self.__serial_port_speeddn()
        
        return True


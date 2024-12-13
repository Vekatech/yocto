# yocto
### Yocto image builder (Builds Kernel & Modules for various vkboards)
#
1. create source dir
    ``` bash
    mkdir -p $HOME/work
    cd $HOME/work
    ```

2. clone Yocto builder
    ``` bash
    git clone https://github.com/Vekatech/yocto.git
    cd yocto
    ```

3. build Yocto image (Dunfell) [^1]
    ``` bash
    chmod a+x build.sh
    ./build.sh <board>
    ```
#
### Yocto image flasher (Performs a factory reset)
#
1. Prepare the image to be in the appropriate sparse format. [^1][^2]
    ``` bash
    img2simg "path_to_the_image/core-image-<target>.wic" "vkPyFlasher/images/<board>/core-image-<target>.simg"
    ```

2. Write Yocto image on the SBC/SoM  [^1][^2][^3]

   If you are flashing from **`Linux`** / **`Unix`** machine:
    ``` bash
    python3 vkPyFlasher/flash_img.py --board=<board> --serial_port=/dev/ttyUSB<n> --image_rootfs=core-image-<target>.simg
    ```
    
   If you are flashing from **`Windows`** machine:
    ``` bash
    vkPyFlasher/flash_img.py --board=<board> --serial_port=COM<n> --image_rootfs=core-image-<target>.simg
    ```
#
If you are interested what else **`vkPyFlasher`** can do, you can check the full [manual](https://vekatech.com/factory/tools/vkPyFlasher%20How%20To.pdf) on our [website](https://vekatech.com/product_details.php?item=tools).

[^1]: `<board>` can be one of the boards: [ **`vkrzv2l`** | **`vkrzg2l`** | **`vkrzg2lc`** | **`vkrzg2ul`** | **`vkcmg2lc`** | **`vk-d184280e`** ]
[^2]: `<target>` can be one of the targets: [ **`minimal`** | **`bsp`** | **`weston`** | **`qt`** ]
[^3]: `<n>` is the digit of COM device connected to the System TTY of the board: [ **`0`** - **`9`** ]

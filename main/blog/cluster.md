# Setting up an in-house development HPC cluster

As a high performance computing (HPC) and systems engineering company, we really enjoy
setting up our own hardware clusters. Recently we had an opportunity to purchase
some really good systems off of an IT liquidator company for really cheap. We ended up buying two
[NVIDIA Tesla S1070](http://www.nvidia.in/object/tesla_s1070_in.html) 1U
servers, each with 4 NVIDIA Tesla C1060 GPUs, and 8 [Dell 1950 III](http://www1.la.dell.com/an/en/gen/enterprise/pedge_1950_3/pd.aspx?refid=pedge_1950_3&s=gen) 1U
servers, each with 2 quad-core Xeon 5400 CPUs and 16 GB RAM. The specification
manuals of the NVIDIA system is available [here](http://www.nvidia.com/docs/IO/43395/SP-04154-001_v02.pdf) and for the Dell system is
available
[here](http://www.dell.com/downloads/global/products/pedge/en/pe_1950_III_spec_sheet.pdf).

Despite cloud computing getting more popular, it is definitely useful to have
your own in-house development HPC cluster for doing work. In this blog post, we
explain how we went about setting up an HPC cluster for ourselves. So in all we
were going to have an effective cluster with 64 processing cores and 8 powerful
GPUs. We can use this for prototyping our HPC products, password
cracking using [Hashcat](http://www.hashcat.net), playing with Google's
[Tensorflow](http://www.tensorflow.org) software for deep learning or even
[Litecoin mining](https://litecoin.info/Mining_software). Building your own
cluster can be useful for any purpose.

## The Server Rack

We need the following parts in addition to the servers to setup the cluster:

- 1 42U Dell server rack ($250 off of Craigslist)
- 2 1U server rails ($20 each on eBay) for the NVIDIA Tesla S1070
- 8 1U Dell Rails for the Dell 1950 III servers (came with the servers)
- 1 rackmount Power Distribution Unit (PDU). We used [CyberPower
  CPS-1220RMS](https://www.amazon.com/dp/B00077IS32) which has 12 outlets. ($67 on Amazon)
- 1 or 2 2200VA UPS. We used one [CyberPower
  OR2200PFCRT2U](https://www.amazon.com/CyberPower-OR2200PFCRT2Ua-Sinewave-2200VA-Compatible/dp/B003OJAHWA).
($420 on Newegg).
- 4 NVIDIA PCI-e x16 host cards ($25 on eBay)
- 4 Dell-NVIDIA H6GPT Molex PCI-e extension cables for the host PCI-e x16 host
  cards ($35 each on eBay)
- 4 PCI-e x8 to PCI-e x16 flexible Riser cables for attaching the PCI-e x16 host cards to the Dell server's PCI-e
  x8 slots

Each Dell server cost us $85 and each NVIDIA server cost us $165, including
shipping. To connect the NVIDIA servers to the Dell servers, we needed to
purchase 4 PCI-e x16 host cards and cables described above. Except for our
servers and the server rack, every other item was purchased new.

Each NVIDIA server required 110V, 16A input, and the PDU and UPS required 20A
electrical sockets. So we ended up adding two extra 20A electrical lines from the
mains so that they could take the load of the full rack when all the servers
were running at once. This should be enough for our purposes. If we add more
such servers in, we will need to add more 20A lines to handle the load during
100% use of all the servers.

In all, the total cost was about $2100 for complete setup including the
electrical work, which is much cheaper than a single powerful server you could
buy today. But hey, this is a development cluster for ourselves, not for
production use, and setting it up was great fun !

## Connecting the NVIDIA and Dell Servers

Each NVIDIA server has 4 GPUs connecting to a host machine using 2 PCI-E x16 host
cards which need to be installed in the host machine, which in our case is the
Dell server. The host PCI-E card is then connected to the NVIDIA server using
the Dell-NVIDIA H6GPT Molex connector cable as described in the [S1070
documentation](http://www.nvidia.com/docs/IO/43395/SP-04154-001_v02.pdf).

The Dell servers only have two PCI-E x8 connectors but our host PCI-E cards are
x16. Hence, we use an PCI-E x8-x16 flexible Riser cable to connect the host
cards to the Dell server. However, this doesn't snugly fit inside the 1U server,
and hence we let the PCI-E x16 end of the cable come out of the slot at the rear
end of the Dell server and connect the host card to it as shown in the figure.

Despite these hanging cards, the server rack doors close without any problems.

Using a PCI-E x8 connector instead of a PCI-E x16 leads to slightly slow data
transfer speeds, but that may not be an issue for a development cluster. Speeds
are also dependent on the programs being run, where data transfer intensive
programs may see a boost in using a direct PCI-E x16 connector while compute
intensive programs may not see any difference.

Instead of attaching one host card per Dell server, we attached two host cards
per Dell server, making our GPU cluster consist of 4 GPUs per Dell Server. This
allows us to run CUDA or OpenCL programs that can take advantage of multiple
GPUs on a single machine.

## Installing the Required Software

The Dell 1950 III Server is supported out of the box on Ubuntu Server 16.06
(Xenial) 64-bit Linux. So we manually installed Ubuntu Server on each of the eight Dell
Servers.

For the two servers that had the NVIDIA host cards connected to them, we
installed the NVIDIA drivers and CUDA toolkit using the following procedure.

1. First we check which version of drivers and CUDA toolkit we need for NVIDIA
Tesla S1070. As shown in the figure, we see that the version needed for the
drivers is 340.93 and for CUDA toolkit is 6.5.
2. On Ubuntu Server 16.06, we have a package `nvidia-340-dev` that can install
the drivers without us having to manually do it. Hence we run the following
commands as `root`:

    
    $ apt-get install nvidia-340-dev libxmu-dev libglu1-mesa-dev g++-4.8\
        gcc-4.8 libxi-dev freeglut3-dev build-essential cmake gcc g++ wget \
        pkg-config make automake autoconf libtool curl


**NOTE**: We had to install `g++-4.8` because the CUDA toolkit 6.5 requires it.

3. We then download the CUDA toolkit 6.5 from NVIDIA directly which has an MD5
sum of `90b1b8f77313600cc294d9271741f4da` as given on the NVIDIA website. (Yes,
we know MD5 is not secure, but NVIDIA still uses it.)

    $ wget http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/cuda_6.5.14_linux_64.run
    $ md5sum cuda_6.5.14_linux_64.run                
    90b1b8f77313600cc294d9271741f4da  cuda_6.5.14_linux_64.run

4. We now extract the file so that we can **selectively** install only the items
we want such as the CUDA SDK and the samples. We do **not** want to install the
NVIDIA drivers that come with this binary blob. We do want to build all the
samples so that we can test the GPUs.


    ## extract the cuda installer into the cuda_installer directory
    $ sh ./cuda_6.5.14_linux_64.run -extract=cuda_installer

    ## change directory
    $ cd cuda_installler
    
    ## run the SDK install binary
    $ ./cuda-linux64-rel-6.5.14-18749181.run -noprompt
   
    ## setup the linker for use by everyone 
    $ echo /usr/local/cuda-6.5/lib64 > /etc/ld.so.conf.d/cuda_ld.conf
    $ ldconfig
    $ ln -s /usr/local/cuda-6.5 /usr/local/cuda

    ## run the sample install binary
    $ ./cuda-samples-linux-6.5.14-18745345.run -noprompt\
        -prefix=/usr/local/cuda-6.5/samples -cudaprefix=/usr/local/cuda-6.5/

    ## build the samples
    $ cd /usr/local/cuda-6.5/samples
    $ GCC=g++-4.8 EXTRA_NVCCFLAGS="-D_FORCE_INLINES" make -j4


5. At this stage we have now successfully installed and built the CUDA software
and the NVIDIA drivers. So let's reboot the system.

6. Once the system has booted up, let's login again either as `root` or as a
regular user and run `lspci` to make sure that the NVIDIA host cards and the
GPUs are detected.

    $ lspci
    00:00.0 Host bridge: Intel Corporation 5000X Chipset Memory Controller Hub (rev 12)
    00:02.0 PCI bridge: Intel Corporation 5000 Series Chipset PCI Express x4 Port 2 (rev 12)
    00:03.0 PCI bridge: Intel Corporation 5000 Series Chipset PCI Express x4 Port 3 (rev 12)
    00:04.0 PCI bridge: Intel Corporation 5000 Series Chipset PCI Express x8 Port 4-5 (rev 12)
    00:05.0 PCI bridge: Intel Corporation 5000 Series Chipset PCI Express x4 Port 5 (rev 12)
    00:06.0 PCI bridge: Intel Corporation 5000 Series Chipset PCI Express x8 Port 6-7 (rev 12)
    00:07.0 PCI bridge: Intel Corporation 5000 Series Chipset PCI Express x4 Port 7 (rev 12)
    00:10.0 Host bridge: Intel Corporation 5000 Series Chipset FSB Registers (rev 12)
    00:10.1 Host bridge: Intel Corporation 5000 Series Chipset FSB Registers (rev 12)
    00:10.2 Host bridge: Intel Corporation 5000 Series Chipset FSB Registers (rev 12)
    00:11.0 Host bridge: Intel Corporation 5000 Series Chipset Reserved Registers (rev 12)
    00:13.0 Host bridge: Intel Corporation 5000 Series Chipset Reserved Registers (rev 12)
    00:15.0 Host bridge: Intel Corporation 5000 Series Chipset FBD Registers (rev 12)
    00:16.0 Host bridge: Intel Corporation 5000 Series Chipset FBD Registers (rev 12)
    00:1c.0 PCI bridge: Intel Corporation 631xESB/632xESB/3100 Chipset PCI Express Root Port 1 (rev 09)
    00:1d.0 USB controller: Intel Corporation 631xESB/632xESB/3100 Chipset UHCI USB Controller #1 (rev 09)
    00:1d.1 USB controller: Intel Corporation 631xESB/632xESB/3100 Chipset UHCI USB Controller #2 (rev 09)
    00:1d.2 USB controller: Intel Corporation 631xESB/632xESB/3100 Chipset UHCI USB Controller #3 (rev 09)
    00:1d.3 USB controller: Intel Corporation 631xESB/632xESB/3100 Chipset UHCI USB Controller #4 (rev 09)
    00:1d.7 USB controller: Intel Corporation 631xESB/632xESB/3100 Chipset EHCI USB2 Controller (rev 09)
    00:1e.0 PCI bridge: Intel Corporation 82801 PCI Bridge (rev d9)
    00:1f.0 ISA bridge: Intel Corporation 631xESB/632xESB/3100 Chipset LPC Interface Controller (rev 09)
    01:00.0 SCSI storage controller: LSI Logic / Symbios Logic SAS1068E PCI-Express Fusion-MPT SAS (rev 08)
    02:00.0 PCI bridge: Broadcom EPB PCI-Express to PCI-X Bridge (rev c3)
    03:00.0 Ethernet controller: Broadcom Corporation NetXtreme II BCM5708 Gigabit Ethernet (rev 12)
    04:00.0 PCI bridge: Intel Corporation 6311ESB/6321ESB PCI Express Upstream Port (rev 01)
    04:00.3 PCI bridge: Intel Corporation 6311ESB/6321ESB PCI Express to PCI-X Bridge (rev 01)
    05:00.0 PCI bridge: Intel Corporation 6311ESB/6321ESB PCI Express Downstream Port E1 (rev 01)
    05:01.0 PCI bridge: Intel Corporation 6311ESB/6321ESB PCI Express Downstream Port E2 (rev 01)
    06:00.0 PCI bridge: Broadcom EPB PCI-Express to PCI-X Bridge (rev c3)
    07:00.0 Ethernet controller: Broadcom Corporation NetXtreme II BCM5708 Gigabit Ethernet (rev 12)
    0a:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0b:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0b:01.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0b:02.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0b:03.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0e:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0f:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0f:01.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0f:02.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    0f:03.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    10:00.0 3D controller: NVIDIA Corporation GT200GL [Tesla C1060 / M1060] (rev a1)
    12:00.0 3D controller: NVIDIA Corporation GT200GL [Tesla C1060 / M1060] (rev a1)
    16:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    17:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    17:01.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    17:02.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    17:03.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    1a:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    1b:00.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    1b:01.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    1b:02.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    1b:03.0 PCI bridge: NVIDIA Corporation NF200 PCIe 2.0 switch for Quadro Plex S4 / Tesla S870 / Tesla S1070 / Tesla S2050 (rev a3)
    1c:00.0 3D controller: NVIDIA Corporation GT200GL [Tesla C1060 / M1060] (rev a1)
    1e:00.0 3D controller: NVIDIA Corporation GT200GL [Tesla C1060 / M1060] (rev a1)
    22:0d.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] ES1000 (rev 02)


7. Let's run `lsmod` to check that the `nvidia` driver has been loaded. You will see that there is the `radeon` driver also loaded but that's because the Dell server has an on-board AMD/ATI VGA unit.

    $ lsmod | grep nvidia
    nvidia_uvm             36864  0
    nvidia              10567680  1 nvidia_uvm
    drm                   360448  5 ttm,drm_kms_helper,nvidia,radeon


8. Let's setup some environment variables needed to run the CUDA samples.

    ## setup your .bashrc with the following
    export CUDA_PATH=/usr/local/cuda
    export CUDA_SAMPLES_PATH=/usr/local/cuda/samples/bin/x86_64/linux/release
    export LD_LIBRARY_PATH=$CUDA_PATH/lib64:/usr/local/lib:$LD_LIBRARY_PATH
    export PATH=$CUDA_PATH/bin:$PATH:$CUDA_SAMPLES_PATH

9. Start a new `bash` shell and verify that the paths have been set.

    $ env | grep CUDA
    CUDA_PATH=/usr/local/cuda
    CUDA_SAMPLES_PATH=/usr/local/cuda/samples/bin/x86_64/linux/release

    $ which nvcc
    /usr/local/cuda/bin/nvcc

    $ which deviceQuery
    /usr/local/cuda/samples/bin/x86_64/linux/release/deviceQuery

    
10. Now let's run the `deviceQuery` program that is part of the CUDA SDK and make
sure it is detecting all the GPUs.

    $ deviceQuery
    /usr/local/cuda/samples/bin/x86_64/linux/release/deviceQuery Starting...

    CUDA Device Query (Runtime API) version (CUDART static linking)

    Detected 4 CUDA Capable device(s)

    Device 0: "Tesla T10 Processor"
    CUDA Driver Version / Runtime Version          6.5 / 6.5
    CUDA Capability Major/Minor version number:    1.3
    Total amount of global memory:                 4096 MBytes (4294770688 bytes)
    (30) Multiprocessors, (  8) CUDA Cores/MP:     240 CUDA Cores
    GPU Clock rate:                                1440 MHz (1.44 GHz)
    Memory Clock rate:                             800 Mhz
    Memory Bus Width:                              512-bit
    Maximum Texture Dimension Size (x,y,z)         1D=(8192), 2D=(65536, 32768), 3D=(2048, 2048, 2048)
    Maximum Layered 1D Texture Size, (num) layers  1D=(8192), 512 layers
    Maximum Layered 2D Texture Size, (num) layers  2D=(8192, 8192), 512 layers
    Total amount of constant memory:               65536 bytes
    Total amount of shared memory per block:       16384 bytes
    Total number of registers available per block: 16384
    Warp size:                                     32
    Maximum number of threads per multiprocessor:  1024
    Maximum number of threads per block:           512
    Max dimension size of a thread block (x,y,z): (512, 512, 64)
    Max dimension size of a grid size    (x,y,z): (65535, 65535, 1)
    Maximum memory pitch:                          2147483647 bytes
    Texture alignment:                             256 bytes
    Concurrent copy and kernel execution:          Yes with 1 copy engine(s)
    Run time limit on kernels:                     No
    Integrated GPU sharing Host Memory:            No
    Support host page-locked memory mapping:       Yes
    Alignment requirement for Surfaces:            Yes
    Device has ECC support:                        Disabled
    Device supports Unified Addressing (UVA):      No
    Device PCI Bus ID / PCI location ID:           16 / 0
    Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >

    Device 1: "Tesla T10 Processor"
    CUDA Driver Version / Runtime Version          6.5 / 6.5
    CUDA Capability Major/Minor version number:    1.3
    Total amount of global memory:                 4096 MBytes (4294770688 bytes)
    (30) Multiprocessors, (  8) CUDA Cores/MP:     240 CUDA Cores
    GPU Clock rate:                                1440 MHz (1.44 GHz)
    Memory Clock rate:                             800 Mhz
    Memory Bus Width:                              512-bit
    Maximum Texture Dimension Size (x,y,z)         1D=(8192), 2D=(65536, 32768), 3D=(2048, 2048, 2048)
    Maximum Layered 1D Texture Size, (num) layers  1D=(8192), 512 layers
    Maximum Layered 2D Texture Size, (num) layers  2D=(8192, 8192), 512 layers
    Total amount of constant memory:               65536 bytes
    Total amount of shared memory per block:       16384 bytes
    Total number of registers available per block: 16384
    Warp size:                                     32
    Maximum number of threads per multiprocessor:  1024
    Maximum number of threads per block:           512
    Max dimension size of a thread block (x,y,z): (512, 512, 64)
    Max dimension size of a grid size    (x,y,z): (65535, 65535, 1)
    Maximum memory pitch:                          2147483647 bytes
    Texture alignment:                             256 bytes
    Concurrent copy and kernel execution:          Yes with 1 copy engine(s)
    Run time limit on kernels:                     No
    Integrated GPU sharing Host Memory:            No
    Support host page-locked memory mapping:       Yes
    Alignment requirement for Surfaces:            Yes
    Device has ECC support:                        Disabled
    Device supports Unified Addressing (UVA):      No
    Device PCI Bus ID / PCI location ID:           18 / 0
    Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >

    Device 2: "Tesla T10 Processor"
    CUDA Driver Version / Runtime Version          6.5 / 6.5
    CUDA Capability Major/Minor version number:    1.3
    Total amount of global memory:                 4096 MBytes (4294770688 bytes)
    (30) Multiprocessors, (  8) CUDA Cores/MP:     240 CUDA Cores
    GPU Clock rate:                                1440 MHz (1.44 GHz)
    Memory Clock rate:                             800 Mhz
    Memory Bus Width:                              512-bit
    Maximum Texture Dimension Size (x,y,z)         1D=(8192), 2D=(65536, 32768), 3D=(2048, 2048, 2048)
    Maximum Layered 1D Texture Size, (num) layers  1D=(8192), 512 layers
    Maximum Layered 2D Texture Size, (num) layers  2D=(8192, 8192), 512 layers
    Total amount of constant memory:               65536 bytes
    Total amount of shared memory per block:       16384 bytes
    Total number of registers available per block: 16384
    Warp size:                                     32
    Maximum number of threads per multiprocessor:  1024
    Maximum number of threads per block:           512
    Max dimension size of a thread block (x,y,z): (512, 512, 64)
    Max dimension size of a grid size    (x,y,z): (65535, 65535, 1)
    Maximum memory pitch:                          2147483647 bytes
    Texture alignment:                             256 bytes
    Concurrent copy and kernel execution:          Yes with 1 copy engine(s)
    Run time limit on kernels:                     No
    Integrated GPU sharing Host Memory:            No
    Support host page-locked memory mapping:       Yes
    Alignment requirement for Surfaces:            Yes
    Device has ECC support:                        Disabled
    Device supports Unified Addressing (UVA):      No
    Device PCI Bus ID / PCI location ID:           28 / 0
    Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >
    Device 3: "Tesla T10 Processor"
    CUDA Driver Version / Runtime Version          6.5 / 6.5
    CUDA Capability Major/Minor version number:    1.3
    Total amount of global memory:                 4096 MBytes (4294770688 bytes)
    (30) Multiprocessors, (  8) CUDA Cores/MP:     240 CUDA Cores
    GPU Clock rate:                                1440 MHz (1.44 GHz)
    Memory Clock rate:                             800 Mhz
    Memory Bus Width:                              512-bit
    Maximum Texture Dimension Size (x,y,z)         1D=(8192), 2D=(65536, 32768), 3D=(2048, 2048, 2048)
    Maximum Layered 1D Texture Size, (num) layers  1D=(8192), 512 layers
    Maximum Layered 2D Texture Size, (num) layers  2D=(8192, 8192), 512 layers
    Total amount of constant memory:               65536 bytes
    Total amount of shared memory per block:       16384 bytes
    Total number of registers available per block: 16384
    Warp size:                                     32
    Maximum number of threads per multiprocessor:  1024
    Maximum number of threads per block:           512
    Max dimension size of a thread block (x,y,z): (512, 512, 64)
    Max dimension size of a grid size    (x,y,z): (65535, 65535, 1)
    Maximum memory pitch:                          2147483647 bytes
    Texture alignment:                             256 bytes
    Concurrent copy and kernel execution:          Yes with 1 copy engine(s)
    Run time limit on kernels:                     No
    Integrated GPU sharing Host Memory:            No
    Support host page-locked memory mapping:       Yes
    Alignment requirement for Surfaces:            Yes
    Device has ECC support:                        Disabled
    Device supports Unified Addressing (UVA):      No
    Device PCI Bus ID / PCI location ID:           30 / 0
    Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >

    deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 6.5, CUDA Runtime Version = 6.5, NumDevs = 4, Device0 = Tesla T10 Processor, Device1 = Tesla T10 Processor, Device2 = Tesla T10 Processor, Device3 = Tesla T10 Processor
    Result = PASS



With this we come to the end of the setup of our development HPC cluster. We are
now ready for using it.



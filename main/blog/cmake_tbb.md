# How to use [CMake](http://www.cmake.org) to Build Third party libraries

CMake is an excellent cross-platform build tool for automatically generating
Unix `Makefiles`, Windows `NMake Makefiles`, Microsoft Visual Studio&reg;
Solution projects or Xcode projects for MacOS. It has its own domain specific
language and various modules for most commonly used libraries and software
frameworks. The most common use of CMake is to build projects that are written
in C, C++ or both. As a user of CMake for the past 12 years, we have written
build systems for large and complex projects in it that also build Java and C#
wrappers, or use it for auto-generating cross-platform C/C++ code using Perl.

In this blog post we demonstrate how to use CMake to build a large toolkit like
Intel&reg; [Thread Building Blocks
(TBB)](http://www.threadingbuildingblocks.org/). Although TBB might be available
in your Linux operating system's package manager, sometimes you may want to
compile the latest version from source using a different compiler like Intel's C
Compiler (`icc`) instead of GNU C Compiler (`gcc`), or you're building software
that runs on both Linux and Windows, and you don't want to use a pre-built
version of TBB from Intel.

CMake has a module called `ExternalProject_Add` that can do this for you. Below
we demonstrate how to download the latest source from the TBB website, and how
to use features present in CMake to make sure that the project gets compiled and
ready to use in your project. TBB is a C++ library, hence our example will be
with C++ source.

## Sample Setup

Let's say your source code directory structure looks like below. For brevity we are
not displaying too many C++ files. We will use this example to show how to use
TBB as an external dependency.

        myproject/
        ├── CMakeLists.txt
        ├── include
        │   ├── CMakeLists.txt
        │   └── myproject.h
        ├── src
        │   ├── CMakeLists.txt
        │   └── myproject.cpp
        ├── test
        │   └── loadtbb.cpp
        └── thirdparty
            └── CMakeLists.txt

Here the `myproject.h`, `myproject.cpp` are the source code for your application
that will use TBB and `loadtbb.cpp` is a unit test to check that you have loaded
TBB correctly. The `CMakeLists.txt` files in each directory are for CMake to
know how to handle the files in each directory.

**TODO**: insert code samples

### The `myproject/CMakeLists.txt` file

Note that the below file `tbb.cmake` doesn't exist yet and we will be creating
it in the following section.

    # the minimum version of CMake required
    cmake_minimum_required(VERSION 2.8)

    # required for unit testing using CMake's ctest command
    include(CTest)
    enable_testing()
    
    # required modules for our task
    include(CheckIncludeFile)
    include(CheckIncludeFileCXX0
    include(CheckIncludeFiles)
    include(ExternalProject)
    include(thirdparty/tbb.cmake) # TO BE CREATED
    
    # we add the files in the include directory to be included while compiling
    # all the source code
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

    # we add the sub-directories that we want CMake to scan
    add_subdirectory(include)
    add_subdirectory(thirdparty)
    add_subdirectory(src)
    add_subdirectory(test)


## Creating the `tbb.cmake` file

Create an empty file using your favorite text editor called `tbb.cmake` in the
`thirdparty` directory. Your directory structure should look like this:


        myproject/
        ├── CMakeLists.txt
        ├── include
        │   ├── CMakeLists.txt
        │   └── myproject.h
        ├── src
        │   ├── CMakeLists.txt
        │   └── myproject.cpp
        ├── test
        │   └── loadtbb.cpp
        └── thirdparty
            ├── CMakeLists.txt
            └── tbb.cmake


## Downloading the TBB source

There are two ways to download the source: manually and using CMake. We explain
the manual method first, as the CMake method follows from that.

Using `curl` or `wget` or any browser download the source from the TBB website
from
[here](https://www.threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb44_20160316oss_src.tgz)
for example the latest source code version at the time of writing of this blog
post is 4.4. Place this downloaded file in the `thirdparty` directory of your
project, which in our case is the `myproject` directory. Our tree structure now
looks like this.

        myproject/
        ├── CMakeLists.txt
        ├── include
        │   ├── CMakeLists.txt
        │   └── myproject.h
        ├── src
        │   ├── CMakeLists.txt
        │   └── myproject.cpp
        ├── test
        │   └── loadtbb.cpp
        └── thirdparty
            ├── CMakeLists.txt
            ├── tbb44_20160316oss_src.tgz
            └── tbb.cmake


Let's add the following lines to the `tbb.cmake` file now.


        #denote the name of the folder where to compile TBB and set a variable
        #tbb44 represents tbb-4.4. You may be compiling multiple versions of TBB
        #in your project and hence separating them by version is good practice.
        set(TBB_PREFIX tbb44)
        # set a variable to point to the URL of the TBB source.
        # since we manually downloaded this, it will look like below
        set(TBB_URL ${CMAKE_CURRENT_SOURCE_DIR}/tbb44_20160316oss_src.tgz)


If you want to use the direct URL from the TBB website, the `TBB_URL` variable
line will look like below. Be aware that this causes TBB source to be
downloaded each time you build the project which may not be what you want.
Hence, we _recommend_ the manual download method above.


        # set a variable to point to the URL of the TBB source.
        set(TBB_URL https://www.threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb44_20160316oss_src.tgz)
        

The rest of the `tbb.cmake` file will be described assuming the manual download
method since that is expedient.




    

 

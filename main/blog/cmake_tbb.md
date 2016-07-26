# How to use [CMake](http://www.cmake.org) to Build Third party libraries

CMake is an excellent cross-platform build tool for automatically generating
Unix `Makefiles`, Windows `NMake Makefiles`, Microsoft Visual Studio&reg;
Solution projects or Apple Xcode&reg; projects for MacOS. It has its own domain specific
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

CMake has a module called **`ExternalProject`** that can do this for you. Below
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
know how to handle the files in each directory. Sample files are given at the
end of this post.

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
    include(CheckIncludeFileCXX)
    include(CheckIncludeFiles)
    include(ExternalProject)
    # TO BE CREATED
    include(thirdparty/tbb.cmake)
    
    # we add the files in the include directory to be included while compiling
    # all the source code
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

    # we add the sub-directories that we want CMake to scan
    add_subdirectory(include)
    add_subdirectory(thirdparty)
    add_subdirectory(src)
    add_subdirectory(test)


### Sample `test/loadtbb.cpp`


        #include <iostream>
        #include <tbb/tbb.h>
        
        int main (int argc, char **argv)
        {
            std::cout << "TBB version: "
                    << TBB_VERSION_MAJOR << "." << TBB_VERSION_MINOR
                    << std::endl;
            return 0; 
        }


### Sample `test/CMakeLists.txt`


        add_executable(loadtbb loadtbb.cpp)
        target_link_libraies(loadtbb ${TBB_LIBS})
        add_test(loadtbb_test loadtbb)



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


### Downloading the TBB source

There are two ways to download the source: manually and using CMake. We explain
the manual method first, as the CMake method follows from that.

Using `curl` or `wget` or any browser download the source from the [TBB
website](https://www.threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb44_20160316oss_src.tgz).
For example, the latest source code version at the time of writing of this blog
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

        # calculate the MD5 sum of the file downloaded and set it in a variable
        set(TBB_URL_MD5 1908b8901730fa1049f0c45d8d0e6d7d)


If you want to use the direct URL from the TBB website, the `TBB_URL` variable
line will look like below. Be aware that this causes TBB source to be
downloaded each time you build the project which may not be what you want.
Hence, we _recommend_ the manual download method above.


        # set a variable to point to the URL of the TBB source.
        set(TBB_URL https://www.threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb44_20160316oss_src.tgz)
        # calculate the MD5 sum of the file downloaded and set it in a variable
        set(TBB_URL_MD5 1908b8901730fa1049f0c45d8d0e6d7d)
        

The rest of the `tbb.cmake` file will be described assuming the manual download
method since that is expedient.

### Building the TBB source

To build the TBB source, we have to use the CMake functions provided by the
`ExternalProject` module, viz., `ExternalProject_Add`,
`ExternalProject_Get_Property` and `ExternalProject_Add_Step`. The details of
each of these functions can be viewed in the [CMake
manual](https://cmake.org/cmake/help/v3.0/module/ExternalProject.html) or using
the command `man cmake` on your terminal.

**NOTE**: To build TBB on Windows requires GNU Make or `gmake` installed and in
the `PATH` or set it in the `TBB_MAKE` variable.

The best way to verify this works is to first test it on Linux or MacOS.

We add the TBB project using the `ExternalProject_Add` command to the
`tbb.cmake` file like below. We also add the sub-projects in TBB that are
required in the file using `ExternalProject_Step`.

The `ExternalProject_Add` will uncompress the TBB source file we downloaded
earlier and compile it using as many CPU cores as available in your system. The
number of CPUs can be modified by editing the `NCPU` variable in the file.

It will then compile the source and all its dependencies that are specified. Any
following targets that need to be built usign `ExternalProject_Step` are also
built.

**NOTE**: Building the examples is optional. It can take very long and isn't
recommended for regular use. It is only useful if you want to see how stuff
works.

We then use CMake's module `CheckIncludeFileCXX` to have CMake test whether it
can include the `tbb/tbb.h` header file in code and compile it. If it can, then
we have succeeded in adding TBB as a dependency in our project.

The complete `tbb.cmake` file is below:


        set(TBB_PREFIX tbb44)
        set(TBB_URL ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/tbb44_20160316oss_src.tgz)
        set(TBB_URL_MD5 1908b8901730fa1049f0c45d8d0e6d7d)

        if (WIN32)
            set(TBB_MAKE gmake) ## you can set the full path to the file here
        else (WIN32)
            set(TBB_MAKE make)
        endif (WIN32)

        # set the number of CPUs used for compiling to 8 or 4 or as many as you
        # have in your system.
        set(NCPU 8)

        # add instructions to build the TBB source
        ExternalProject_Add(${TBB_PREFIX}
            PREFIX ${TBB_PREFIX}
            URL ${TBB_URL}
            URL_MD5 ${TBB_URL_MD5}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND  ${TBB_MAKE} -j${NCPU} tbb_build_prefix=${TBB_PREFIX}
            BUILD_IN_SOURCE 1
            INSTALL_COMMAND ""
            LOG_DOWNLOAD 1
            LOG_BUILD 1
            STEP_TARGETS ${TBB_PREFIX}_info ${TBB_PREFIX}_examples
        )

        # get the unpacked source directory path
        ExternalProject_Get_Property(${TBB_PREFIX} SOURCE_DIR)
        message(STATUS "Source directory of ${TBB_PREFIX} ${SOURCE_DIR}")
        # build another dependency
        ExternalProject_Add_Step(${TBB_PREFIX} ${TBB_PREFIX}_info
            COMMAND ${TBB_MAKE} info tbb_build_prefix=${TBB_PREFIX}
            DEPENDEES build
            WORKING_DIRECTORY ${SOURCE_DIR}
            LOG 1
        ) 
        
        # build the examples if you're interested
        ExternalProject_Add_Step(${TBB_PREFIX} ${TBB_PREFIX}_examples
            COMMAND make -j${NCPU} examples tbb_build_prefix=${TBB_PREFIX}
            DEPENDEES build
            WORKING_DIRECTORY ${SOURCE_DIR}
            LOG 1
        )

        # Set separate directories for building in Debug or Release mode
        set(TBB_DEBUG_DIR ${SOURCE_DIR}/build/${TBB_PREFIX}_debug)
        set(TBB_RELEASE_DIR ${SOURCE_DIR}/build/${TBB_PREFIX}_release)
        message(STATUS "TBB Debug directory ${TBB_DEBUG_DIR}")
        message(STATUS "TBB Release directory ${TBB_RELEASE_DIR}")

        # set the include directory variable and include it
        set(TBB_INCLUDE_DIRS ${SOURCE_DIR}/include)
        include_directories(${TBB_INCLUDE_DIRS})

        # link the correct TBB directory when the project is in Debug or Release mode
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            # in Debug mode
            link_directories(${TBB_RELEASE_DIR})
            set(TBB_LIBS tbb_debug tbbmalloc_debug)
            set(TBB_LIBRARY_DIRS ${TBB_DEBUG_DIR})
        else (CMAKE_BUILD_TYPE STREQUAL "Debug")
            # in Release mode
            link_directories(${TBB_RELEASE_DIR})
            set(TBB_LIBS tbb tbbmalloc)
            set(TBB_LIBRARY_DIRS ${TBB_RELEASE_DIR})
        endif (CMAKE_BUILD_TYPE STREQUAL "Debug")

        # verify that the TBB header files can be included
        set(CMAKE_REQUIRED_INCLUDES_SAVE ${CMAKE_REQUIRED_INCLUDES})
        set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES} ${TBB_INCLUDE_DIRS})
        check_include_file_cxx("tbb/tbb.h" HAVE_TBB)
        set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES_SAVE})
        if (NOT HAVE_TBB)
            message(STATUS "Did not build TBB correctly as cannot find tbb.h. Will build it.")
            set(HAVE_TBB 1)
        endif (NOT HAVE_TBB)
        
        # Optional: install the TBB libraries when the application being built gets installed
        # when you run "make install"
        if (UNIX)
            install(DIRECTORY ${TBB_LIBRARY_DIRS}/ DESTINATION lib
                USE_SOURCE_PERMISSIONS FILES_MATCHING PATTERN "*.so*")
        else (UNIX)
            ## Similarly for Windows.
        endif (UNIX)
        


As you see above this file looks complex but in reality, that's how CMake build
files look. You have to instruct CMake in detail to avoid it making mistakes,
especially in such cases. However, once you have a template like the above, it
is easy to make it work for other libraries too.

The commands to build the project are as follows:


        # enter your project directory
        $ cd myproject

        # it is always a good idea to not pollute the source with build files
        # so create a new build directory
        $ mkdir build
        $ cd build

        # run cmake and make
        $ cmake -DCMAKE_BUILD_TYPE=Release ..
        $ make

        # if you have tests, then the following
        $ ctest 


This has worked well for us on Linux and MacOS. We have not had a need to test
on Windows, but if you find any problems let us know.

**NOTE**: If you have errors in your run of `cmake` for any reason and they
don't go away, remember to delete the `CMakeCache.txt` file and then retry.


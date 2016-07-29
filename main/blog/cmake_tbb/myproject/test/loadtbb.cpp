#include <iostream>
#include <tbb/tbb.h>

int main(int argc, char **argv)
{
    std::cout << "TBB Version: " << TBB_VERSION_MAJOR
            << "." << TBB_VERSION_MINOR << std::endl;
    return 0;
}

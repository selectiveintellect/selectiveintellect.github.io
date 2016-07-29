add_executable(loadtbb loadtbb.cpp)
target_link_libraries(loadtbb ${TBB_LIBS})
add_test(loadtbb1 loadtbb)

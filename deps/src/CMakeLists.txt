project(PolymakeWrap)

cmake_minimum_required(VERSION 3.01)

find_package(JlCxx REQUIRED)

include_directories(${JlCxx_DIR}/../../../include/)
include_directories(${JuliaIncludeDir})
set(MY_LIST ${polymake_includes})
separate_arguments(MY_LIST)
include_directories(${MY_LIST})

add_subdirectory(generated)

SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -std=c++14 ${polymake_cflags}" )
SET( CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -L${JULIA_LIB_DIR} -Wl,-rpath,${JULIA_LIB_DIR} ${polymake_ldflags}" )


set(MY_LIST ${GENERATED_SRCS})
separate_arguments(MY_LIST)
add_library(polymake SHARED ${MY_LIST} polymake.cpp)
target_link_libraries(polymake JlCxx::cxxwrap_julia  -ljulia "${polymake_libs}")

install(TARGETS
  polymake
ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
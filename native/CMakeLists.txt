cmake_minimum_required(VERSION 3.22)
project(sornaz_music_analysis LANGUAGES C CXX)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(AUBIO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/aubio")
file(GLOB_RECURSE AUBIO_SOURCES CONFIGURE_DEPENDS "${AUBIO_ROOT}/src/*.c")
add_library(aubio_vendor STATIC ${AUBIO_SOURCES})
target_include_directories(aubio_vendor PUBLIC "${AUBIO_ROOT}/src")
target_compile_definitions(aubio_vendor PRIVATE
  HAVE_STDLIB_H=1 HAVE_STDIO_H=1 HAVE_MATH_H=1 HAVE_STRING_H=1
  HAVE_ERRNO_H=1 HAVE_LIMITS_H=1 HAVE_STDARG_H=1
  HAVE_C99_VARARGS_MACROS=1)
if(NOT MSVC)
  target_link_libraries(aubio_vendor PUBLIC m)
endif()

add_library(music_analysis_dsp SHARED music_analysis_dsp.cpp)
target_include_directories(music_analysis_dsp PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(music_analysis_dsp PRIVATE aubio_vendor)

include(CTest)
if(BUILD_TESTING AND NOT ANDROID AND NOT IOS)
  add_executable(music_analysis_dsp_test tests/music_analysis_dsp_test.cpp)
  target_link_libraries(music_analysis_dsp_test PRIVATE music_analysis_dsp)
  add_test(NAME music_analysis_dsp_test COMMAND music_analysis_dsp_test)
  add_executable(music_analysis_c_abi_smoke tests/c_abi_smoke.c)
  target_link_libraries(music_analysis_c_abi_smoke PRIVATE music_analysis_dsp)
  add_test(NAME music_analysis_c_abi_smoke COMMAND music_analysis_c_abi_smoke)
endif()

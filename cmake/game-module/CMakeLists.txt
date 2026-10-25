cmake_minimum_required(VERSION 3.28)
project(BananaPadGameModule LANGUAGES C CXX)
if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS" OR NOT CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
    message(FATAL_ERROR "Use PadMint's arm64 iOS module toolchain")
endif()
get_filename_component(BANANAPAD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(BANANAPAD_GENERATED "" CACHE PATH "Verified private output from build-game-module.py")
set(BANANAPAD_SOURCE "${BANANAPAD_ROOT}/work/module-sources/dk64" CACHE PATH "Verified pinned public source")
find_package(Python3 REQUIRED COMPONENTS Interpreter)
execute_process(COMMAND "${Python3_EXECUTABLE}" -X utf8 "${BANANAPAD_ROOT}/scripts/check-module-inputs.py" "${BANANAPAD_GENERATED}" "${BANANAPAD_SOURCE}"
    COMMAND_ERROR_IS_FATAL ANY)
include("${BANANAPAD_ROOT}/cmake/ModuleIdentity.cmake")
bananapad_module_identity("${BANANAPAD_ROOT}" identity)
set(runtime "${BANANAPAD_SOURCE}/lib/N64ModernRuntime")
set(source "${BANANAPAD_GENERATED}")
file(GLOB generated CONFIGURE_DEPENDS "${source}/RecompiledFuncs/*.c" "${source}/RecompiledFuncs/*.cpp")
add_library(BananaPadGame SHARED ${generated}
    "${source}/rsp/n_aspMain.cpp" "${source}/RecompiledPatches/patches.c" "${source}/RecompiledPatches/patches_bin.c"
    "${source}/src/main/register_overlays.cpp" "${source}/src/main/register_patches.cpp"
    "${BANANAPAD_ROOT}/apple/module/game_module_entry.cpp")
set_target_properties(BananaPadGame PROPERTIES C_STANDARD 11 CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON
    CXX_SCAN_FOR_MODULES OFF C_VISIBILITY_PRESET hidden CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON PREFIX "" OUTPUT_NAME "BananaPadGame")
target_include_directories(BananaPadGame PRIVATE "${BANANAPAD_ROOT}/apple/module"
    "${source}/include" "${source}/RecompiledFuncs" "${source}/RecompiledPatches"
    "${runtime}/N64Recomp/include" "${runtime}/librecomp/include" "${runtime}/ultramodern/include"
    "${runtime}/thirdparty" "${runtime}/thirdparty/sse2neon" "${runtime}/thirdparty/concurrentqueue")
target_compile_definitions(BananaPadGame PRIVATE "BANANAPAD_MODULE_ID=\"${identity}\"")
target_compile_options(BananaPadGame PRIVATE -fno-strict-aliasing -Wno-implicit-function-declaration
    -Wno-unused-variable -Wno-unused-but-set-variable "-ffile-prefix-map=${BANANAPAD_ROOT}=.")
set_source_files_properties("${source}/RecompiledPatches/patches.c" PROPERTIES
    COMPILE_OPTIONS "-include;${BANANAPAD_ROOT}/apple/module/patch_attributes.h;-include;${source}/RecompiledFuncs/funcs.h")
target_link_options(BananaPadGame PRIVATE "LINKER:-undefined,dynamic_lookup")

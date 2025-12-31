# This CMakeLists.txt integrates Swift Package Manager (SPM) with ESP-IDF for Embedded Swift on ESP32-C6.
# Requirements: Swift toolchain with Embedded Support (main-snapshot for now), ESP-IDF v5.2+ with RISC-V support, CMake 3.29+.

# Register the app as an IDF component
idf_component_register(
    SRCS /dev/null # We don't have any C++ sources
    PRIV_INCLUDE_DIRS "."
)

# Validate required files
if(NOT EXISTS "${COMPONENT_DIR}/Package.swift")
    message(FATAL_ERROR "Package.swift not found in ${COMPONENT_DIR}. Ensure the Swift package is present.")
endif()

# Target Architecture Validation
idf_build_get_property(target IDF_TARGET)
idf_build_get_property(arch IDF_TARGET_ARCH)

if("${arch}" STREQUAL "xtensa")
    message(FATAL_ERROR "Not supported target: ${target}")
endif()

# Compiler Flag Extraction
# Extract the -march flag and remove any vendor-specific extensions (_x*)
string(REGEX MATCH "-march=[^ ]+" march_flag "${CMAKE_C_FLAGS}")
string(REGEX REPLACE "_x[^ ]*" "" march_flag "${march_flag}")

# Extract the -mabi flag or set a default value if not present
string(REGEX MATCH "-mabi=[^ ]+" mabi_flag "${CMAKE_C_FLAGS}")
if("${mabi_flag}" STREQUAL "")
    set(mabi_flag "-mabi=ilp32")
endif()

# Clear the default COMPILE_OPTIONS which include a lot of C/C++ specific compiler flags that the Swift compiler will not accept
get_target_property(var ${COMPONENT_LIB} COMPILE_OPTIONS)
set_target_properties(${COMPONENT_LIB} PROPERTIES COMPILE_OPTIONS "")

# Include Path Setup for Swift Bridging
# Compute -Xcc flags to set up the C and C++ header search paths for Swift (for bridging).
set(SWIFT_INCLUDES_LIST)
foreach(dir ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES})
    list(APPEND SWIFT_INCLUDES_LIST "-Xcc" "-I${dir}")
endforeach()
foreach(dir ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
    list(APPEND SWIFT_INCLUDES_LIST "-Xcc" "-I${dir}")
endforeach()
list(JOIN SWIFT_INCLUDES_LIST " " SWIFT_INCLUDES)


# CMake Swift Language Setup
# Enable Swift support in CMake, force Whole Module builds (required by Embedded Swift), and use "CMAKE_Swift_COMPILER_WORKS" to
# skip the trial compilations which don't (yet) correctly work when cross-compiling.
set(CMAKE_Swift_COMPILER_WORKS YES)
set(CMAKE_Swift_COMPILATION_MODE_DEFAULT wholemodule)
set(CMAKE_Swift_COMPILATION_MODE wholemodule)
enable_language(Swift)

# Swift Package Manager (SPM) Integration
# ======================Package Support======================
# Add Package Support
# The target swift will be building for
set(SWIFT_TARGET "riscv32-none-none-eabi")
# Name of the library product in Package.swift
set(SWIFT_PRODUCT_NAME "App")

# Define output file of swift package
set(SWIFT_PRODUCT_BUILD   "${COMPONENT_DIR}/.build")
set(SWIFT_PRODUCT_RELEASE "${SWIFT_PRODUCT_BUILD}/release")
set(SWIFT_PRODUCT_ARCHIVE "${SWIFT_PRODUCT_RELEASE}/lib${SWIFT_PRODUCT_NAME}.a")

# Get swift toolchain location
find_program(SWIFT_EXECUTABLE swift)
if(NOT SWIFT_EXECUTABLE)
    message(FATAL_ERROR "Swift executable not found. Ensure Swift is installed and in PATH.")
endif()

get_filename_component(_SWIFT_ABS_LOCATION ${SWIFT_EXECUTABLE} REALPATH)
get_filename_component(SWIFT_TOOLCHAIN ${_SWIFT_ABS_LOCATION} DIRECTORY)

# Output SWIFT_INCLUDES for debugging
message(DEBUG "SWIFT_INCLUDES: ${SWIFT_INCLUDES}")


# Swift Package Archive Generation
# Generate Archive
add_custom_target(swift-archive
  COMMAND
    # Remove the archive. Swift does not overwrite this on building but merges them.
    # If the file with app_main gets renamed, both objectfiles (old and new) will be in the archive, potentially causing problems
    rm -f ${SWIFT_PRODUCT_ARCHIVE}
  COMMAND
    ${SWIFT_TOOLCHAIN}/swift package update --package-path ${COMPONENT_DIR}
  COMMAND
    ${SWIFT_TOOLCHAIN}/swift build
      --configuration release
      --package-path ${COMPONENT_DIR}
      --triple ${SWIFT_TARGET}
      --traits Embedded
      -Xswiftc -enable-experimental-feature -Xswiftc Embedded
      -Xswiftc -wmo
      -Xswiftc -parse-as-library
      -Xswiftc -Osize
      -Xswiftc -Xfrontend
      -Xswiftc -function-sections
      -Xswiftc -Xfrontend
      -Xswiftc -enable-single-module-llvm-emission
      -Xswiftc -pch-output-dir -Xswiftc ${CMAKE_BINARY_DIR}/tmp
      -Xcc ${march_flag}
      -Xcc ${mabi_flag}
      -Xcc -fno-pic
      -Xcc -fno-pie
      # for sourcekit-lsp
      -Xcc -D__APPLE__ -Xcc -D__MACH__
      -Xswiftc -Xfrontend -Xswiftc -disable-stack-protector
      # Get includes for C-std libraries and extra components
      ${SWIFT_INCLUDES_LIST}
      $$\( echo '$<TARGET_PROPERTY:__idf_main,INCLUDE_DIRECTORIES>' | tr '\;' '\\n' | sed -e 's/\\\(.*\\\)/-Xcc -I\\1/g' \)
  BYPRODUCTS
    ${SWIFT_PRODUCT_ARCHIVE}
)


# Post-Build Archive Processing
add_custom_command(
    TARGET swift-archive
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash
        ${SWIFT_PRODUCT_ARCHIVE} ${SWIFT_PRODUCT_ARCHIVE}
)

# app_main Object File Extraction
# Extract Objectfile with app_main() symbol so we can link it directly to __idf_main (not just as archive).
# This ensures the linker correctly resolves dependencies
# Uses shell commands to find and extract the specific object file containing app_main.
add_custom_command(
 OUTPUT ${SWIFT_PRODUCT_RELEASE}/_swift_package_app_main.o
 COMMAND
  # Extract first .o which defines the 'app_main' symbol
  ${SWIFT_TOOLCHAIN}/llvm-ar x ${SWIFT_PRODUCT_ARCHIVE} $$\( nm --defined-only -A ${SWIFT_PRODUCT_ARCHIVE} | grep -m 1 'app_main' | cut -d: -f2 \) --output ${SWIFT_PRODUCT_RELEASE}
  # Rename it to a predicatble file
  && \( mv -f -T ${SWIFT_PRODUCT_RELEASE}/$$\( nm --defined-only -A ${SWIFT_PRODUCT_ARCHIVE} | grep -m 1 'app_main' | cut -d: -f2 \) ${SWIFT_PRODUCT_RELEASE}/_swift_package_app_main.o 2>/dev/null || \(
   rm -rf ${SWIFT_PRODUCT_RELEASE}/_swift_package_app_main.o && mv -f ${SWIFT_PRODUCT_RELEASE}/$$\( nm --defined-only -A ${SWIFT_PRODUCT_ARCHIVE} | grep -m 1 'app_main' | cut -d: -f2 \) ${SWIFT_PRODUCT_RELEASE}/_swift_package_app_main.o \)
  \)
 DEPENDS
  swift-archive
  ${SWIFT_PRODUCT_ARCHIVE}
)
add_custom_target(swift_package_app_main DEPENDS ${SWIFT_PRODUCT_RELEASE}/_swift_package_app_main.o)

# Library Linking and Dependencies
# ${COMPONENT_LIB} expands to __idf_main
target_link_libraries(${COMPONENT_LIB} ${SWIFT_PRODUCT_ARCHIVE})
target_link_libraries(${COMPONENT_LIB} ${SWIFT_PRODUCT_RELEASE}/_swift_package_app_main.o)

# Add swift_package_app_main to __idf_main
add_dependencies(${COMPONENT_LIB} swift_package_app_main)

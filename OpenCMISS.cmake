###########################
# *DO NOT CHANGE THIS FILE*
###########################
#
# Prepares the use of OpenCMISS and defines macros to find the CMake-built OpenCMISS software suite.
#
# There need to be two parts as some code has to be run *before* and *after* the CMake project() command is issued.

# Prepares the use of OpenCMISS and its components.
#
# Thus far:
#     - Reads the environment variable OPENCMISS_INSTALL_DIR if present
#     - Includes the toolchain config script of the opencmiss installation

# Convenience: The OPENCMISS_INSTALL_DIR may also be defined in the environment.
if (NOT DEFINED OPENCMISS_INSTALL_DIR AND EXISTS "$ENV{OPENCMISS_INSTALL_DIR}")
    file(TO_CMAKE_PATH "$ENV{OPENCMISS_INSTALL_DIR}" OPENCMISS_INSTALL_DIR)
endif()

# Use the OpenCMISS scripts to also allow choosing a separate toolchain
# This file is located at the opencmiss installation rather than the local example
# as it avoids file replication and makes maintenance much easier
if (TOOLCHAIN)
    set(_OCTC ${OPENCMISS_INSTALL_DIR}/cmake/OCToolchainCompilers.cmake)
    if (EXISTS "${_OCTC}")
        include(${_OCTC})
    else()
        message(WARNING "TOOLCHAIN specified but OpenCMISS config script could not be found at ${_OCTC}. Using CMake defaults.")
    endif()
    unset(_OCTC)
endif()

# Initializes the use of OpenCMISS and its components.
#
# Arguments:
#    VERSION: The minimum OpenCMISS version to look for.
#
# Thus far:
#     - Adds OPENCMISS_INSTALL_DIR to the CMAKE_PREFIX_PATH
#     - Issues find_package(OpenCMISS) call to locate a matching OpenCMISS installation
#       Matches Version and selected architecture path (Toolchain, MPI, Multithreading, ...)
#     - Adds some necessary flags 
macro(OC_INIT VERSION)

    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    
    # One could specify CMAKE_PREFIX_PATH directly, however using OPENCMISS_INSTALL_DIR will be more intuitive
    list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_INSTALL_DIR})
    
    # Look for a matching OpenCMISS!
    find_package(OpenCMISS ${VERSION} REQUIRED ${ARGN} CONFIG)
    
    # On windows, we do not have the mpi.mod file
    if (WIN32)
        add_definitions(-DNOMPIMOD)
    endif()
    
    # Turn on Fortran preprocessing (#include directives)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -cpp")
endmacro()
###########################
# *DO NOT CHANGE THIS FILE*
###########################
#
# Prepares the use of OpenCMISS and defines macros to find the CMake-built OpenCMISS software suite.
#
# There need to be two parts as some code has to be run *before* and *after* the CMake project() command is issued.
# 

################################################################################
# Inclusion part - before "project()" command
########
#
# Thus far this
#     - Reads the environment variable OPENCMISS_INSTALL_DIR if present
#     - Includes the toolchain config script of the opencmiss installation

# Convenience: The OPENCMISS_INSTALL_DIR may also be defined in the environment.
if (NOT DEFINED OPENCMISS_INSTALL_DIR AND EXISTS "$ENV{OPENCMISS_INSTALL_DIR}")
    file(TO_CMAKE_PATH "$ENV{OPENCMISS_INSTALL_DIR}" OPENCMISS_INSTALL_DIR)
    message(STATUS "Using environment OPENCMISS_INSTALL_DIR: ${OPENCMISS_INSTALL_DIR}")
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

################################################################################
# Initialization part - after "project()" command
########
# Initializes the use of OpenCMISS and its components.
# Returns a target "opencmiss" that can be used as link library within your application code.
#
# Arguments:
#    VERSION: The minimum OpenCMISS version to look for.
#    COMPONENT1: At least one OpenCMISS component you want to use.
#        Available are Iron, Iron-C and Zinc thus far.
#    [, COMPONENT2,...]: Any more components of OpenCMISS you require to be available.
#
# Thus far this
#     - Adds OPENCMISS_INSTALL_DIR to the CMAKE_PREFIX_PATH
#     - Issues find_package(OpenCMISS) call to locate a matching OpenCMISS installation
#       Matches Version and selected architecture path (Toolchain, MPI, Multithreading, ...)
#     - Adds some necessary flags 
macro(OC_INIT VERSION COMPONENT)

    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    
    # One could specify CMAKE_PREFIX_PATH directly, however using OPENCMISS_INSTALL_DIR will be more intuitive
    list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_INSTALL_DIR})
    
    # Look for a matching OpenCMISS!
    find_package(OpenCMISS ${VERSION} REQUIRED ${COMPONENT} ${ARGN} CONFIG)
    
    # On some platforms (windows), we do not have the mpi.mod file or it could not be compatible for inclusion
    # This variable is set by the FindMPI.cmake module in OPENCMISS_INSTALL_DIR/cmake/OpenCMISSExtraFindModules
    if (NOT MPI_Fortran_MODULE_COMPATIBLE)
        add_definitions(-DNOMPIMOD)
    endif()
    
    # Turn on Fortran preprocessing (#include directives)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -cpp")
    
    # Put to source directory unless specified differently
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
endmacro()
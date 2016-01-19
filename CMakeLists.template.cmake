# OpenCMISS (Open Continuum Mechanics, Imaging, Signal processing and System identification)
# is a mathematical modelling environment that enables the application of finite element
# analysis techniques to a variety of complex bioengineering problems.
# 
# The OpenCMISS project website can be found at http://www.opencmiss.org
#
# --- Welcome! ---
# This is the template for main build files for OpenCMISS examples using the CMake build system
#
# For most situations, all you need to do is set the OPENCMISS_INSTALL_DIR to the
# desired/given OpenCMISS install directory.
#
# *Note that you may also define OPENCMISS_INSTALL_DIR in your environment!*
#
# For more information see http://www.opencmiss.org/documentation

############################## Preparation ##############################

# Include the OpenCMISS initalisation & macro definition file.
include("./OpenCMISS.cmake")

# Project setup
# -------------
# Change the project name and minimum required CMake version here if required.
# 
# .. note::
#
#     The OC_INIT script additionally ensures the CMake version is sufficienty new
#     for the found OpenCMISS installation
cmake_minimum_required(VERSION 3.3 FATAL_ERROR)
project(OpenCMISS-Example VERSION 1.0 LANGUAGES Fortran C CXX)

# Initialise OpenCMISS
# --------------------
#
# The OC_INIT function takes the following arguments:
#
# OC_INIT(VERSION [, COMPONENT [, ...]])
#
#    VERSION: The minimum OpenCMISS version required for this example
#    COMPONENT: One or more OpenCMISS components that are required.
#               Currently available: Iron Zinc
#
# This function creates a link target 'opencmiss' that contains references to the requested OpenCMISS components.
# For Iron, it also adds the necessary MPI information - no further find_package(MPI ..) and setting of extra include
# paths needed ;-)

OC_INIT(1.1 Iron)

############################## Actual example code ##############################

# Get sources in /src
file(GLOB SRC src/*.f90 src/*.c ../input/*.f90)
set(EXAMPLE_BINARY run)
# Add example executable
add_executable(${EXAMPLE_BINARY} ${SRC})

# Link to opencmiss
# -----------------
#
# This simply uses the opencmiss target created by OC_INIT() above.
#
# Alternatively, you can also directly invoke 'find_package(Iron <IRON_VERSION>)' to explicitly
# require that version etc.
#
target_link_libraries(${EXAMPLE_BINARY} PRIVATE opencmiss)

# If required, add any other required link libraries (cellml, petsc ..) here, too.
# For example, if you needed PetSC functionality, issue
#
#     find_package(PETSC <PETSC_VERSION> REQUIRED)
#     target_link_libraries(${EXAMPLE_BINARY} PRIVATE petsc)
#
# All the OpenCMISS dependencies provide a target you can link against corresponding to the (lowercase) component name.

# Install the binary to the root of the installation directory
#
# Copy any extra files required for execution there, too!
install(TARGETS ${EXAMPLE_BINARY} DESTINATION .)

###################
# Developer notice!
###################
#
# If you write Fortran code and use MPI, you need to use the following MPI directives:
#
# #ifndef NOMPIMOD
#   USE MPI
# #endif
# [...]
#   IMPLICIT NONE
# [...]
# #ifdef NOMPIMOD
#     #include "mpif.h"
# #endif
#
# Reasoning: In some cases like Windows/MPICH2 there sometimes is no mpi.mod file. In order to yet make
# the example work the build system adds the definition 'NOMPIMOD', which can be checked and acted to accordingly.
#
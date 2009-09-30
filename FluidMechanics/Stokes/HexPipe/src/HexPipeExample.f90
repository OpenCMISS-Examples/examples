!> \file
!> $Id: StokesFlowExample.f90 20 2009-04-08 20:22:52Z cpb $
!> \author Sebastian Krittian
!> \brief This is an example program to solve a Stokes equation using openCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> \example FluidMechanics/Stokes/HexPipe/src/HexPipeExample.f90
!! Example program to solve a Stokes equation using openCMISS calls.
!! \par Latest Builds:
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/FluidMechanics/Stokes/HexPipe/build-intel'>Linux Intel Build</a>
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/FluidMechanics/Stokes/HexPipe/build-gnu'>Linux GNU Build</a>
!<

!> Main program

PROGRAM StokesFlow

! OpenCMISS Modules

   USE BASE_ROUTINES
   USE BASIS_ROUTINES
   USE BOUNDARY_CONDITIONS_ROUTINES
   USE CMISS
   USE CMISS_MPI
   USE COMP_ENVIRONMENT
   USE CONSTANTS
   USE CONTROL_LOOP_ROUTINES
   USE COORDINATE_ROUTINES
   USE DOMAIN_MAPPINGS
   USE EQUATIONS_ROUTINES
   USE EQUATIONS_SET_CONSTANTS
   USE EQUATIONS_SET_ROUTINES
   USE FIELD_ROUTINES
   USE FIELD_IO_ROUTINES
   USE INPUT_OUTPUT
   USE ISO_VARYING_STRING
   USE KINDS
   USE MESH_ROUTINES
   USE MPI
   USE NODE_ROUTINES
   USE PROBLEM_CONSTANTS
   USE PROBLEM_ROUTINES
   USE REGION_ROUTINES
   USE SOLVER_ROUTINES
   USE TIMER
   USE TYPES
!!!!!
#ifdef WIN32
   USE IFQWIN
#endif

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! cmHeart input module
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


  USE FLUID_MECHANICS_IO_ROUTINES


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  IMPLICIT NONE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !Program types
  TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS
  TYPE(COORDINATE_SYSTEM_TYPE), POINTER :: COORDINATE_SYSTEM
  TYPE(MESH_TYPE), POINTER :: MESH
  TYPE(DECOMPOSITION_TYPE), POINTER :: DECOMPOSITION
  TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
  TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
  TYPE(FIELD_TYPE), POINTER :: GEOMETRIC_FIELD, DEPENDENT_FIELD, MATERIALS_FIELD
  TYPE(PROBLEM_TYPE), POINTER :: PROBLEM
  TYPE(REGION_TYPE), POINTER :: REGION,WORLD_REGION
  TYPE(SOLVER_TYPE), POINTER :: SOLVER
  TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
  TYPE(BASIS_TYPE), POINTER :: BASIS_M,BASIS_V,BASIS_P
  TYPE(MESH_ELEMENTS_TYPE), POINTER :: MESH_ELEMENTS_M,MESH_ELEMENTS_P,MESH_ELEMENTS_V
  TYPE(NODES_TYPE), POINTER :: NODES

  !Program variables
  INTEGER(INTG) :: NUMBER_OF_DOMAINS
  INTEGER(INTG) :: MPI_IERROR
  INTEGER(INTG) :: EQUATIONS_SET_INDEX
  LOGICAL :: EXPORT_FIELD,IMPORT_FIELD
  TYPE(VARYING_STRING) :: FILE,METHOD
  REAL(SP) :: START_USER_TIME(1),STOP_USER_TIME(1),START_SYSTEM_TIME(1),STOP_SYSTEM_TIME(1)
  INTEGER(INTG) :: NUMBER_COMPUTATIONAL_NODES
  INTEGER(INTG) :: MY_COMPUTATIONAL_NODE_NUMBER
  INTEGER(INTG) :: ERR
  TYPE(VARYING_STRING) :: ERROR
  INTEGER(INTG) :: DIAG_LEVEL_LIST(5)
  CHARACTER(LEN=MAXSTRLEN) :: DIAG_ROUTINE_LIST(1),TIMING_ROUTINE_LIST(1)

   !User types
  TYPE(EXPORT_CONTAINER):: CM

   !User variables
  INTEGER:: DECOMPOSITION_USER_NUMBER
  INTEGER:: GEOMETRIC_FIELD_USER_NUMBER
  INTEGER:: DEPENDENT_FIELD_USER_NUMBER
  INTEGER:: DEPENDENT_FIELD_NUMBER_OF_VARIABLES
  INTEGER:: DEPENDENT_FIELD_NUMBER_OF_COMPONENTS
  INTEGER:: REGION_USER_NUMBER
  INTEGER:: BC_NUMBER_OF_INLET_NODES,BC_NUMBER_OF_WALL_NODES
  INTEGER:: COORDINATE_USER_NUMBER
  INTEGER:: MESH_NUMBER_OF_COMPONENTS
  INTEGER:: I,J,K,L,M,N
  INTEGER:: X_DIRECTION,Y_DIRECTION,Z_DIRECTION
  INTEGER, ALLOCATABLE, DIMENSION(:):: BC_INLET_NODES
  INTEGER, ALLOCATABLE, DIMENSION(:):: BC_WALL_NODES
  INTEGER, ALLOCATABLE, DIMENSION(:):: DOF_INDICES
  INTEGER, ALLOCATABLE, DIMENSION(:):: DOF_CONDITION
  REAL(DP),ALLOCATABLE, DIMENSION(:):: DOF_VALUES

  DOUBLE PRECISION:: DIVERGENCE_TOLERANCE, RELATIVE_TOLERANCE, ABSOLUTE_TOLERANCE
  INTEGER:: MAXIMUM_ITERATIONS,RESTART_VALUE

#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Program starts
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Import cmHeart Information
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


  !Read node, element and basis information from cmheart input file
  !Receive CM container for adjusting OpenCMISS calls
  CALL FLUID_MECHANICS_IO_READ_CMHEART(CM,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Intialise cmiss
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(WORLD_REGION)
  CALL CMISS_INITIALISE(WORLD_REGION,ERR,ERROR,*999)

!Set all diganostic levels on for testing
!  DIAG_LEVEL_LIST(1)=1
!  DIAG_LEVEL_LIST(2)=2
!  DIAG_LEVEL_LIST(3)=3
!  DIAG_LEVEL_LIST(4)=4
!  DIAG_LEVEL_LIST(5)=5
!  DIAG_ROUTINE_LIST(1)=""
!  CALL DIAGNOSTICS_SET_ON(ALL_DIAG_TYPE,DIAG_LEVEL_LIST,"StokesFlowExample",DIAG_ROUTINE_LIST,ERR,ERROR,*999)
!  CALL DIAGNOSTICS_SET_ON(ALL_DIAG_TYPE,DIAG_LEVEL_LIST,"",DIAG_ROUTINE_LIST,ERR,ERROR,*999)

  !TIMING_ROUTINE_LIST(1)=""
  !CALL TIMING_SET_ON(IN_TIMING_TYPE,.TRUE.,"",TIMING_ROUTINE_LIST,ERR,ERROR,*999)


  !Calculate the start times
  CALL CPU_TIMER(USER_CPU,START_USER_TIME,ERR,ERROR,*999)
  CALL CPU_TIMER(SYSTEM_CPU,START_SYSTEM_TIME,ERR,ERROR,*999)
  !Get the number of computational nodes
  NUMBER_COMPUTATIONAL_NODES=COMPUTATIONAL_NODES_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999
  !Get my computational node number
  MY_COMPUTATIONAL_NODE_NUMBER=COMPUTATIONAL_NODE_NUMBER_GET(ERR,ERROR)
  IF(ERR/=0) GOTO 999

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Start the creation of a new RC coordinate system
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(COORDINATE_SYSTEM)
  COORDINATE_USER_NUMBER=1
  CALL COORDINATE_SYSTEM_CREATE_START(COORDINATE_USER_NUMBER,COORDINATE_SYSTEM,ERR,ERROR,*999)
  !Set the coordinate system dimension to CM%D
  CALL COORDINATE_SYSTEM_DIMENSION_SET(COORDINATE_SYSTEM,CM%D,ERR,ERROR,*999)
  CALL COORDINATE_SYSTEM_CREATE_FINISH(COORDINATE_SYSTEM,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Start the creation of a region
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(REGION)

  REGION_USER_NUMBER=1

  CALL REGION_CREATE_START(REGION_USER_NUMBER,WORLD_REGION,REGION,ERR,ERROR,*999)
  !Set the regions coordinate system
  CALL REGION_COORDINATE_SYSTEM_SET(REGION,COORDINATE_SYSTEM,ERR,ERROR,*999)
  CALL REGION_CREATE_FINISH(REGION,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Start the creation of a basis for spatial, velocity and pressure field
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(BASIS_M)
  !Spatial basis BASIS_M (CM%ID_M)
  CALL BASIS_CREATE_START(CM%ID_M,BASIS_M,ERR,ERROR,*999)
      !Set Lagrange/Simplex (CM%IT_T) for BASIS_M
      CALL BASIS_TYPE_SET(BASIS_M,CM%IT_T,ERR,ERROR,*999)
      !Set number of XI (CM%D)
      CALL BASIS_NUMBER_OF_XI_SET(BASIS_M,CM%D,ERR,ERROR,*999)
      !Set interpolation (CM%IT_M) for dimensions 
      IF (CM%D==2) THEN
        CALL BASIS_INTERPOLATION_XI_SET(BASIS_M,(/CM%IT_M,CM%IT_M/),ERR,ERROR,*999)
      ELSE IF (CM%D==3) THEN
        CALL BASIS_INTERPOLATION_XI_SET(BASIS_M,(/CM%IT_M,CM%IT_M,CM%IT_M/),ERR,ERROR,*999)
        CALL BASIS_QUADRATURE_NUMBER_OF_GAUSS_XI_SET(BASIS_M,(/3,3,3/),ERR,ERROR,*999)
      ELSE
        GOTO 999
      END IF
  CALL BASIS_CREATE_FINISH(BASIS_M,ERR,ERROR,*999)

  NULLIFY(BASIS_V)
  !Velocity basis BASIS_V (CM%ID_V)
  CALL BASIS_CREATE_START(CM%ID_V,BASIS_V,ERR,ERROR,*999)
      !Set Lagrange/Simplex (CM%IT_T) for BASIS_V
      CALL BASIS_TYPE_SET(BASIS_V,CM%IT_T,ERR,ERROR,*999)
      !Set number of XI (CM%D)
      CALL BASIS_NUMBER_OF_XI_SET(BASIS_V,CM%D,ERR,ERROR,*999)
      !Set interpolation (CM%IT_V) for dimensions 
      IF (CM%D==2) THEN
        CALL BASIS_INTERPOLATION_XI_SET(BASIS_V,(/CM%IT_V,CM%IT_V/),ERR,ERROR,*999)
      ELSE IF (CM%D==3) THEN
        CALL BASIS_INTERPOLATION_XI_SET(BASIS_V,(/CM%IT_V,CM%IT_V,CM%IT_V/),ERR,ERROR,*999)
        CALL BASIS_QUADRATURE_NUMBER_OF_GAUSS_XI_SET(BASIS_V,(/3,3,3/),ERR,ERROR,*999)
      ELSE
        GOTO 999
      END IF
  CALL BASIS_CREATE_FINISH(BASIS_V,ERR,ERROR,*999)

  NULLIFY(BASIS_P)
  !Spatial pressure BASIS_P (CM%ID_P)
  CALL BASIS_CREATE_START(CM%ID_P,BASIS_P,ERR,ERROR,*999)
      !Set Lagrange/Simplex (CM%IT_T) for BASIS_P
      CALL BASIS_TYPE_SET(BASIS_P,CM%IT_T,ERR,ERROR,*999)
      !Set number of XI (CM%D)
      CALL BASIS_NUMBER_OF_XI_SET(BASIS_P,CM%D,ERR,ERROR,*999)
      !Set interpolation (CM%IT_P) for dimensions 
      IF (CM%D==2) THEN
        CALL BASIS_INTERPOLATION_XI_SET(BASIS_P,(/CM%IT_P,CM%IT_P/),ERR,ERROR,*999)
      ELSE IF (CM%D==3) THEN
        CALL BASIS_INTERPOLATION_XI_SET(BASIS_P,(/CM%IT_P,CM%IT_P,CM%IT_P/),ERR,ERROR,*999)
        CALL BASIS_QUADRATURE_NUMBER_OF_GAUSS_XI_SET(BASIS_P,(/3,3,3/),ERR,ERROR,*999)
      ELSE
        GOTO 999
      END IF
  CALL BASIS_CREATE_FINISH(BASIS_P,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Create a mesh with three mesh components for different field interpolations
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !Define number of mesh components
  MESH_NUMBER_OF_COMPONENTS=3

  NULLIFY(NODES)
  ! Define number of nodes (CM%N_T)
  CALL NODES_CREATE_START(REGION,CM%N_T,NODES,ERR,ERROR,*999)
  CALL NODES_CREATE_FINISH(NODES,ERR,ERROR,*999)

  NULLIFY(MESH)
  ! Define 2D/3D (CM%D) mesh 
  CALL MESH_CREATE_START(1,REGION,CM%D,MESH,ERR,ERROR,*999)
      !Set number of elements (CM%E_T)
      CALL MESH_NUMBER_OF_ELEMENTS_SET(MESH,CM%E_T,ERR,ERROR,*999)
      !Set number of mesh components
      CALL MESH_NUMBER_OF_COMPONENTS_SET(MESH,MESH_NUMBER_OF_COMPONENTS,ERR,ERROR,*999)

      !Specify spatial mesh component (CM%ID_M)
      NULLIFY(MESH_ELEMENTS_M)
      CALL MESH_TOPOLOGY_ELEMENTS_CREATE_START(MESH,CM%ID_M,BASIS_M,MESH_ELEMENTS_M,ERR,ERROR,*999)
          !Define mesh topology (MESH_ELEMENTS_M) using all elements' (CM%E_T) associations (CM%M(k,1:CM%EN_M))
          DO k=1,CM%E_T
            CALL MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET(k,MESH_ELEMENTS_M, &
            CM%M(k,1:CM%EN_M),ERR,ERROR,*999)
          END DO
      CALL MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(MESH_ELEMENTS_M,ERR,ERROR,*999)

      !Specify velocity mesh component (CM%ID_V)
      NULLIFY(MESH_ELEMENTS_V)
      !Velocity:
      CALL MESH_TOPOLOGY_ELEMENTS_CREATE_START(MESH,CM%ID_V,BASIS_V,MESH_ELEMENTS_V,ERR,ERROR,*999)
          !Define mesh topology (MESH_ELEMENTS_V) using all elements' (CM%E_T) associations (CM%V(k,1:CM%EN_V))
          DO k=1,CM%E_T
            CALL MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET(k,MESH_ELEMENTS_V, &
            CM%V(k,1:CM%EN_V),ERR,ERROR,*999)
          END DO
      CALL MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(MESH_ELEMENTS_V,ERR,ERROR,*999)

      !Specify pressure mesh component (CM%ID_P)
      NULLIFY(MESH_ELEMENTS_P)
      !Pressure:
      CALL MESH_TOPOLOGY_ELEMENTS_CREATE_START(MESH,CM%ID_P,BASIS_P,MESH_ELEMENTS_P,ERR,ERROR,*999)
          !Define mesh topology (MESH_ELEMENTS_P) using all elements' (CM%E_T) associations (CM%P(k,1:CM%EN_P))
          DO k=1,CM%E_T
            CALL MESH_TOPOLOGY_ELEMENTS_ELEMENT_NODES_SET(k,MESH_ELEMENTS_P, &
            CM%P(k,1:CM%EN_P),ERR,ERROR,*999)
          END DO
      CALL MESH_TOPOLOGY_ELEMENTS_CREATE_FINISH(MESH_ELEMENTS_P,ERR,ERROR,*999)

  CALL MESH_CREATE_FINISH(MESH,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Create a decomposition for mesh
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(DECOMPOSITION)
  !Define decomposition user number
  DECOMPOSITION_USER_NUMBER=1
  !Perform decomposition
  CALL DECOMPOSITION_CREATE_START(DECOMPOSITION_USER_NUMBER,MESH,DECOMPOSITION,ERR,ERROR,*999)
      !Set the decomposition to be a general decomposition with the specified number of domains
      CALL DECOMPOSITION_TYPE_SET(DECOMPOSITION,DECOMPOSITION_CALCULATED_TYPE,ERR,ERROR,*999)
      CALL DECOMPOSITION_NUMBER_OF_DOMAINS_SET(DECOMPOSITION,NUMBER_COMPUTATIONAL_NODES,ERR,ERROR,*999)
  CALL DECOMPOSITION_CREATE_FINISH(DECOMPOSITION,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Define geometric field
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(GEOMETRIC_FIELD)
  !Set X,Y,Z direction parameters
  X_DIRECTION=1
  Y_DIRECTION=2
  Z_DIRECTION=3
  !Set geometric field user number
  GEOMETRIC_FIELD_USER_NUMBER=1

  !Create geometric field
  CALL FIELD_CREATE_START(GEOMETRIC_FIELD_USER_NUMBER,REGION,GEOMETRIC_FIELD,ERR,ERROR,*999)
      !Set field geometric type
      CALL FIELD_TYPE_SET(GEOMETRIC_FIELD,FIELD_GEOMETRIC_TYPE,ERR,ERROR,*999)
      !Set decomposition
      CALL FIELD_MESH_DECOMPOSITION_SET(GEOMETRIC_FIELD,DECOMPOSITION,ERR,ERROR,*999)
      !Disable scaling      
      CALL FIELD_SCALING_TYPE_SET(GEOMETRIC_FIELD,FIELD_NO_SCALING,ERR,ERROR,*999)	
      !Set field component to mesh component for each dimension
      CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,X_DIRECTION,CM%ID_M,ERR,ERROR,*999)
      CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,Y_DIRECTION,CM%ID_M,ERR,ERROR,*999)
      IF(CM%D==3) THEN
      CALL FIELD_COMPONENT_MESH_COMPONENT_SET(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,Z_DIRECTION,CM%ID_M,ERR,ERROR,*999)
      ENDIF
  CALL FIELD_CREATE_FINISH(GEOMETRIC_FIELD,ERR,ERROR,*999)

  !Set geometric field parameters (CM%N(k,j)) and do update
  DO k=1,CM%N_M
    DO j=1,CM%D
      CALL FIELD_PARAMETER_SET_UPDATE_NODE(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,CM%ID_M,k,j, &
        & CM%N(k,j),ERR,ERROR,*999)
    END DO
  END DO
  CALL FIELD_PARAMETER_SET_UPDATE_START(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
  CALL FIELD_PARAMETER_SET_UPDATE_FINISH(GEOMETRIC_FIELD,FIELD_U_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Create equations set
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(EQUATIONS_SET)

  !Set the equations set to be a Stokes Flow problem
  CALL EQUATIONS_SET_CREATE_START(1,REGION,GEOMETRIC_FIELD,EQUATIONS_SET,ERR,ERROR,*999)
    CALL EQUATIONS_SET_SPECIFICATION_SET(EQUATIONS_SET,EQUATIONS_SET_FLUID_MECHANICS_CLASS,EQUATIONS_SET_STOKES_EQUATION_TYPE, &
    & EQUATIONS_SET_STATIC_STOKES_SUBTYPE,ERR,ERROR,*999)
  CALL EQUATIONS_SET_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Define dependent field and initialise
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !Create the equations set dependent field variables
  NULLIFY(DEPENDENT_FIELD)
  CALL EQUATIONS_SET_DEPENDENT_CREATE_START(EQUATIONS_SET,2,DEPENDENT_FIELD,ERR,ERROR,*999)
  CALL EQUATIONS_SET_DEPENDENT_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)


  !Initialise dependent field u=0,v=0,w=-1  
  CALL FIELD_COMPONENT_VALUES_INITIALISE(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,&
  &FIELD_VALUES_SET_TYPE,1,0.0_DP,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_VALUES_INITIALISE(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,&
  &FIELD_VALUES_SET_TYPE,2,0.0_DP,ERR,ERROR,*999)
  CALL FIELD_COMPONENT_VALUES_INITIALISE(DEPENDENT_FIELD,FIELD_U_VARIABLE_TYPE,&
  &FIELD_VALUES_SET_TYPE,3,-1.0_DP,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Define material field and initialise
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !Create the equations set materials field variables
  NULLIFY(MATERIALS_FIELD)
  CALL EQUATIONS_SET_MATERIALS_CREATE_START(EQUATIONS_SET,3,MATERIALS_FIELD,ERR,ERROR,*999)
  CALL EQUATIONS_SET_MATERIALS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)
  
  CALL FIELD_COMPONENT_VALUES_INITIALISE(MATERIALS_FIELD,FIELD_U_VARIABLE_TYPE,&
  &FIELD_VALUES_SET_TYPE,1,1.0_DP,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Define equations
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(EQUATIONS)
  CALL EQUATIONS_SET_EQUATIONS_CREATE_START(EQUATIONS_SET,EQUATIONS,ERR,ERROR,*999)
  !Set the equations matrices sparsity type
  CALL EQUATIONS_SPARSITY_TYPE_SET(EQUATIONS,EQUATIONS_SPARSE_MATRICES,ERR,ERROR,*999)
  !CALL EQUATIONS_OUTPUT_TYPE_SET(EQUATIONS,EQUATIONS_ELEMENT_MATRIX_OUTPUT,ERR,ERROR,*999)
  CALL EQUATIONS_SET_EQUATIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Define boundary conditions (temporary approach)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   BC_NUMBER_OF_WALL_NODES=600
    ALLOCATE(BC_WALL_NODES(BC_NUMBER_OF_WALL_NODES))
    BC_WALL_NODES=(/&
   & 1,2,3,4,5,6,9,10,11,12, &
   &13,14,15,16,23,28,29,30,32,33, &
   &34,35,36,37,42,46,47,48,50,51, &
   &52,53,54,55,60,64,65,66,68,69, &
   &70,71,72,73,78,82,83,84,86,87, &
   &88,89,90,91,96,100,101,102,104,105, &
   &106,107,108,109,114,118,119,120,122,123, &
   &124,125,126,127,132,136,137,138,140,141, &
   &142,143,144,145,150,154,155,156,158,159, &
   &160,161,162,163,168,172,173,174,176,177, &
   &178,179,180,181,186,190,191,192,194,195, &
   &196,197,198,199,204,208,209,210,212,213, &
   &214,215,216,217,222,226,227,230,231,232, &
   &233,244,246,247,248,256,258,259,260,268, &
   &270,271,272,280,282,283,284,292,294,295, &
   &296,304,306,307,308,316,318,319,320,328, &
   &330,331,332,340,342,343,344,352,354,355, &
   &356,364,366,367,368,376,377,378,379,380, &
   &381,382,383,387,388,389,393,394,395,396, &
   &397,398,401,402,405,406,407,408,409,410, &
   &413,414,417,418,419,420,421,422,425,426, &
   &429,430,431,432,433,434,437,438,441,442, &
   &443,444,445,446,449,450,453,454,455,456, &
   &457,458,461,462,465,466,467,468,469,470, &
   &473,474,477,478,479,480,481,482,485,486, &
   &489,490,491,492,493,494,497,498,501,502, &
   &503,504,505,506,509,510,513,514,515,516, &
   &517,518,521,522,525,526,527,530,531,532, &
   &539,544,546,547,552,556,558,559,564,568, &
   &570,571,576,580,582,583,588,592,594,595, &
   &600,604,606,607,612,616,618,619,624,628, &
   &630,631,636,640,642,643,648,652,654,655, &
   &660,664,666,667,672,776,777,781,782,783, &
   &787,788,791,792,795,796,799,800,803,804, &
   &807,808,811,812,815,816,819,820,823,824, &
   &827,828,831,832,835,836,839,840,843,844, &
   &847,848,851,852,855,856,859,860,863,864, &
   &867,868,871,872,875,876,877,878,879,880, &
   &881,882,889,890,891,892,893,894,895,896, &
   &897,902,903,904,905,906,907,908,909,914, &
   &915,916,917,918,919,920,921,926,927,928, &
   &929,930,931,932,933,938,939,940,941,942, &
   &943,944,945,950,951,952,953,954,955,956, &
   &957,962,963,964,965,966,967,968,969,974, &
   &975,976,977,978,979,980,981,986,987,988, &
   &989,990,991,992,993,998,999,1000,1001,1002, &
   &1003,1004,1005,1010,1011,1012,1013,1014,1015,1016, &
   &1017,1022,1023,1024,1025,1026,1027,1034,1035,1036, &
   &1037,1038,1043,1044,1045,1046,1051,1052,1053,1054, &
   &1059,1060,1061,1062,1067,1068,1069,1070,1075,1076, &
   &1077,1078,1083,1084,1085,1086,1091,1092,1093,1094, &
   &1099,1100,1101,1102,1107,1108,1109,1110,1115,1116, &
   &1117,1118,1123,1124,1125,1126,1127,1131,1132,1133, &
   &1134,1135,1136,1137,1138,1141,1142,1143,1144,1145, &
   &1146,1149,1150,1151,1152,1153,1154,1157,1158,1159, &
   &1160,1161,1162,1165,1166,1167,1168,1169,1170,1173, &
   &1174,1175,1176,1177,1178,1181,1182,1183,1184,1185, &
   &1186,1189,1190,1191,1192,1193,1194,1197,1198,1199, &
   &1200,1201,1202,1205,1206,1207,1208,1209,1210,1213, &
   &1214,1215,1216,1217,1218,1221,1222,1223,1224,1225 /)

  BC_NUMBER_OF_INLET_NODES=25
  ALLOCATE(BC_INLET_NODES(BC_NUMBER_OF_INLET_NODES))
  BC_INLET_NODES=(/211,219,221,224,365,370,372,374,520,524,665,669,671,&
  &674,768,770,772,774,870,874,1019,1021,1120,1122,1220/)


  ALLOCATE(DOF_INDICES(CM%D*(BC_NUMBER_OF_WALL_NODES+BC_NUMBER_OF_INLET_NODES)))
  ALLOCATE(DOF_VALUES(CM%D*(BC_NUMBER_OF_WALL_NODES+BC_NUMBER_OF_INLET_NODES)))
  ALLOCATE(DOF_CONDITION(CM%D*(BC_NUMBER_OF_WALL_NODES+BC_NUMBER_OF_INLET_NODES)))

  DOF_CONDITION=BOUNDARY_CONDITION_FIXED

  DO I=1,CM%D
    DO J=1,BC_NUMBER_OF_WALL_NODES
       DOF_INDICES(J+((I-1)*BC_NUMBER_OF_WALL_NODES))=BC_WALL_NODES(J)+((I-1)*CM%N_V)
       DOF_VALUES(J+((I-1)*BC_NUMBER_OF_WALL_NODES))=0.0_DP
    END DO
  END DO

  DO I=1,CM%D
    DO J=1,BC_NUMBER_OF_INLET_NODES
       DOF_INDICES(CM%D*BC_NUMBER_OF_WALL_NODES+J+((I-1)*BC_NUMBER_OF_INLET_NODES))=&
       &BC_INLET_NODES(J)+((I-1)*CM%N_V)

       IF(I==1) THEN !U
       DOF_VALUES(CM%D*BC_NUMBER_OF_WALL_NODES+J+((I-1)*BC_NUMBER_OF_INLET_NODES))=0.0_DP
       ELSE IF(I==2) THEN!V
       DOF_VALUES(CM%D*BC_NUMBER_OF_WALL_NODES+J+((I-1)*BC_NUMBER_OF_INLET_NODES))=0.0_DP
       ELSE !W, I=3
       DOF_VALUES(CM%D*BC_NUMBER_OF_WALL_NODES+J+((I-1)*BC_NUMBER_OF_INLET_NODES))=-1.0_DP
       END IF

    END DO
  END DO

  !Create the equations set boundar conditions
  NULLIFY(BOUNDARY_CONDITIONS)
  CALL EQUATIONS_SET_BOUNDARY_CONDITIONS_CREATE_START(EQUATIONS_SET,BOUNDARY_CONDITIONS,ERR,ERROR,*999)
  !Set boundary conditions
 CALL BOUNDARY_CONDITIONS_SET_LOCAL_DOF(BOUNDARY_CONDITIONS,FIELD_U_VARIABLE_TYPE,DOF_INDICES,DOF_CONDITION, &
   & DOF_VALUES,ERR,ERROR,*999)
!    CALL BOUNDARY_CONDITIONS_SET_LOCAL_DOF(BOUNDARY_CONDITIONS,FIELD_U_VARIABLE_TYPE,1,BOUNDARY_CONDITION_FIXED, &
!      & 0.0_DP,ERR,ERROR,*999)
!    CALL BOUNDARY_CONDITIONS_SET_LOCAL_DOF(BOUNDARY_CONDITIONS,FIELD_U_VARIABLE_TYPE,2,BOUNDARY_CONDITION_FIXED, &
!      & 0.0_DP,ERR,ERROR,*999)
!    CALL BOUNDARY_CONDITIONS_SET_LOCAL_DOF(BOUNDARY_CONDITIONS,FIELD_U_VARIABLE_TYPE,3,BOUNDARY_CONDITION_FIXED, &
!      & 1.0_DP,ERR,ERROR,*999)

  CALL EQUATIONS_SET_BOUNDARY_CONDITIONS_CREATE_FINISH(EQUATIONS_SET,ERR,ERROR,*999)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Define problem and solver settings
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  NULLIFY(PROBLEM)
  !Set the problem to be a standard Stokes problem
  CALL PROBLEM_CREATE_START(1,PROBLEM,ERR,ERROR,*999)
    CALL PROBLEM_SPECIFICATION_SET(PROBLEM,PROBLEM_FLUID_MECHANICS_CLASS,PROBLEM_STOKES_EQUATION_TYPE, &
    & PROBLEM_STATIC_STOKES_SUBTYPE,ERR,ERROR,*999)
  CALL PROBLEM_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem control loop
  CALL PROBLEM_CONTROL_LOOP_CREATE_START(PROBLEM,ERR,ERROR,*999)
  CALL PROBLEM_CONTROL_LOOP_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Start the creation of the problem solvers
  NULLIFY(SOLVER)

  RELATIVE_TOLERANCE=1.0E-10_DP !default: 1.0E-05_DP
  ABSOLUTE_TOLERANCE=1.0E-14_DP !default: 1.0E-10_DP
  DIVERGENCE_TOLERANCE=1.0E5 !default: 1.0E5
  MAXIMUM_ITERATIONS=100000 !default: 100000
  RESTART_VALUE=300 !default: 30

  CALL PROBLEM_SOLVERS_CREATE_START(PROBLEM,ERR,ERROR,*999)
    CALL PROBLEM_SOLVER_GET(PROBLEM,CONTROL_LOOP_NODE,1,SOLVER,ERR,ERROR,*999)
    CALL SOLVER_OUTPUT_TYPE_SET(SOLVER,SOLVER_MATRIX_OUTPUT,ERR,ERROR,*999)

    CALL SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET(SOLVER,DIVERGENCE_TOLERANCE,ERR,ERROR,*999)
    CALL SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET(SOLVER,ABSOLUTE_TOLERANCE,ERR,ERROR,*999)
    CALL SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET(SOLVER,RELATIVE_TOLERANCE,ERR,ERROR,*999)
    CALL SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET(SOLVER,MAXIMUM_ITERATIONS,ERR,ERROR,*999)
    CALL SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET(SOLVER,RESTART_VALUE,ERR,ERROR,*999)

    !For the Direct Solver MUMPS, uncomment the below two lines and comment out the above five
    !CALL SOLVER_LINEAR_TYPE_SET(SOLVER,SOLVER_LINEAR_DIRECT_SOLVE_TYPE,ERR,ERROR,*999)
    !CALL SOLVER_LINEAR_DIRECT_TYPE_SET(SOLVER,SOLVER_DIRECT_MUMPS,ERR,ERROR,*999)  

  CALL PROBLEM_SOLVERS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)

  !Create the problem solver equations
  NULLIFY(SOLVER)
  NULLIFY(SOLVER_EQUATIONS)
  CALL PROBLEM_SOLVER_EQUATIONS_CREATE_START(PROBLEM,ERR,ERROR,*999)
    CALL PROBLEM_SOLVER_GET(PROBLEM,CONTROL_LOOP_NODE,1,SOLVER,ERR,ERROR,*999)
    CALL SOLVER_SOLVER_EQUATIONS_GET(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*999)

    CALL SOLVER_EQUATIONS_SPARSITY_TYPE_SET(SOLVER_EQUATIONS,SOLVER_SPARSE_MATRICES,ERR,ERROR,*999)
    !Add in the equations set
    CALL SOLVER_EQUATIONS_EQUATIONS_SET_ADD(SOLVER_EQUATIONS,EQUATIONS_SET,EQUATIONS_SET_INDEX,ERR,ERROR,*999)

  CALL PROBLEM_SOLVER_EQUATIONS_CREATE_FINISH(PROBLEM,ERR,ERROR,*999)


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Solve the problem
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

 CALL PROBLEM_SOLVE(PROBLEM,ERR,ERROR,*999)
     WRITE(*,*)'Problem solved...'

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!Afterburner
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   FILE="cmgui"
   METHOD="FORTRAN"

   EXPORT_FIELD=.TRUE.
   IF(EXPORT_FIELD) THEN
     WRITE(*,*)'Now export fields...'
    CALL FLUID_MECHANICS_IO_WRITE_CMGUI(REGION,FILE,ERR,ERROR,*999)
     WRITE(*,*)'All fields exported...'
!     CALL FIELD_IO_NODES_EXPORT(REGION%FIELDS, FILE, METHOD, ERR,ERROR,*999)  
!     CALL FIELD_IO_ELEMENTS_EXPORT(REGION%FIELDS, FILE, METHOD, ERR,ERROR,*999)
   ENDIF

   !Calculate the stop times and write out the elapsed user and system times
   CALL CPU_TIMER(USER_CPU,STOP_USER_TIME,ERR,ERROR,*999)
   CALL CPU_TIMER(SYSTEM_CPU,STOP_SYSTEM_TIME,ERR,ERROR,*999)

   CALL WRITE_STRING_TWO_VALUE(GENERAL_OUTPUT_TYPE,"User time = ",STOP_USER_TIME(1)-START_USER_TIME(1),", System time = ", &
     & STOP_SYSTEM_TIME(1)-START_SYSTEM_TIME(1),ERR,ERROR,*999)

!   this causes issues
!   CALL CMISS_FINALISE(ERR,ERROR,*999)

   WRITE(*,'(A)') "Program successfully completed."

   STOP
999 CALL CMISS_WRITE_ERROR(ERR,ERROR)
   STOP

END PROGRAM StokesFlow

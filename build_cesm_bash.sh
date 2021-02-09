#!/bin/bash
#######################################################################
# Author: Colleen Golja
# Date: November 19, 2020 
# Purpose: Use this script to setup and build CESM 2.1.3 on the Cannon 
# currently, this builds the REg  version of the model 

# To Run - this is an executable script that is then submitted within a batch
# YOU MUST do this in batch or interactive mode, do not use on login node

# the user should go through and complete any tasks labeled "TO DO" 
##########################################################################

# SETUP CASE DETAILS (USER EDITS ) 

######  USER TO DO'S --- FILL IN BELOW ##########  
CASE_NAME='MY_FIRST_CASE'   #the name of your case 
COMPSET='F2000climo'        # the name of your compset
RES='f19_g17'               # your resolution
STOPOP='ndays'              # units of your runtime
STOPN=5                     # how long (in the above units) to run for 
JOBTIME='01:00:00'          # how long to request on the cluster? 
ARCHIVE='true'              # Do I want restart files? 
ARCH_OPT='nyears'           # how often do I wanna output restart files (units) 
ARCH_N=1                    # how often to output restart files in the above units ? 
CONT_RUN='false'            # for new runs this is always 'false'; check NCAR for when this should be 'true'

# RESUBMIT FOR LONG RUNS (DEFAULT =0) 
RESUB=0                     # do I need to have this resubmit more than one time (based on how many model years I want; eg runtime is > 168 hrs) 

# ARE YOU DOING A BRANCH? 0=NO 1 = YES
# BRANCH=1                    # am I going to pull restart files and kick off from a previous run? 1= yes, 0 = no! 
BRANCH=0

# ID REFCASE FILES: 
#BRCPATH="/n/holystore01/LABS/keith_lab_seas/Lab/cgolja/CESM_restart_files/CMIP6/"      # path to my restart files
#BRCCASE="b.e21.B1850.f19_g17.CMIP6-piControl-2deg.001"                                 # name of my previous case
#BRCDATE="0501-01-01"                                                                   # date of previous case
#BRCDIR="/n/holystore01/LABS/keith_lab_seas/Lab/cgolja/CESM_restart_files/CMIP6/b_e21_B1850_2degcmip6picontrol/0501-01-01-00000/" # full path to my restart files
#REST_COPY_TO="/n/holyscratch01/keith_lab_seas/cgolja/CESM213ROOT//Run/"                # location of my run folder (edit this to be your own) 


# MODIFY PES LAYOUT 
# CPL, ATM, LND, ICE, OCN, ROF, GLC, WAV, ESP
CPUS=('144' '144' '96' '96' '96' '96' '48' '48' '1') #specify how you want to run the models on the machine, simplest is to assign every model the same
ROOTS=('0' '0' '0' '96' '144' '0' '0' '0' '0')       #specify how you want to run the models on the machine, simplest is to set all values to 0

#SOURCE YOUR REQUIRED MODULES 
cd /n/home04/cgolja/             #INPUT YOUR OWN PATHNAMES
source CESM213_bash.rc           #INPUT THE NAME OF YOUR OWN CESM 2 BASH FILE
cd $CIMEROOT/scripts/

#### END OF USER TO-DO'S #### 

##### #### ##### #### #### #### #### #### 
##### #### ##### #### #### ####	#### #### 


# CREATE THE CASE 
./create_newcase --case ${CASE_NAME} --compset ${COMPSET} --res ${RES}
cd $CIMEROOT/scripts/${CASE_NAME}

echo %%%%%%%%% CREATE NEW CASE COMPLETE %%%%%%%%%%%%%

# XML VARIABLE CHANGES 
./xmlchange JOB_WALLCLOCK_TIME=${JOBTIME}
./xmlchange STOP_OPTION=${STOPOP}
./xmlchange STOP_N=${STOPN}
./xmlchange NTASKS_CPL=${CPUS[0]},NTASKS_ATM=${CPUS[1]},NTASKS_LND=${CPUS[2]},NTASKS_ICE=${CPUS[3]},NTASKS_OCN=${CPUS[4]},NTASKS_ROF=${CPUS[5]},NTASKS_GLC=${CPUS[6]},NTASKS_WAV=${CPUS[7]},NTASKS_ESP=${CPUS[8]}
./xmlchange ROOTPE_CPL=${ROOTS[0]},ROOTPE_ATM=${ROOTS[1]},ROOTPE_LND=${ROOTS[2]},ROOTPE_ICE=${ROOTS[3]},ROOTPE_OCN=${ROOTS[4]},ROOTPE_ROF=${ROOTS[5]},ROOTPE_GLC=${ROOTS[6]},ROOTPE_WAV=${ROOTS[7]},ROOTPE_ESP=${ROOTS[8]}

# SPECIFY YOUR PARTITION   
./xmlchange JOB_QUEUE='huce_cascade' 
./xmlchange MAX_TASKS_PER_NODE=48  # PARTITION SPECIFIC 

# MODIFY YOUR CAM CONFIGURATION TO MATCH B1850 STANDARD SETTINGS
#JESUS THIS ISNT WORKING IM GOING INSANE 
#this uses a bare bones prognostic aerosol model (not full chem) 
./xmlchange --append CAM_CONFIG_OPTS="-chem none"

# SAVE RESTART FILES :
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=${ARCHIVE}
./xmlchange REST_OPTION=${ARCH_OPT} 
./xmlchange REST_N=${ARCH_N}

# EDIT RESUBMIT OPTIONS: 
./xmlchange CONTINUE_RUN=${CONT_RUN}
./xmlchange RESUBMIT=${RESUB}

# ARE YOU BRANCHING OFF A PREVIOUS RUN?? 
if [ ${BRANCH} == 1 ] ; then
  ./xmlchange RUN_TYPE="hybrid"
  ./xmlchange RUN_REFCASE=${BRCCASE}
  ./xmlchange RUN_REFDATE=${BRCDATE}
  ./xmlquery RUN_REFDIR >> ~/buildout
  ./xmlchange RUN_REFDIR=${BRCDIR}
fi


echo %%%%%%% XML CHANGES COMPLETE %%%%%%%% they are as follows:

# OUTPUT YOUR CHANGES TO YOUR FILE: 
./xmlquery JOB_WALLCLOCK_TIME >> ~/buildout
./xmlquery STOP_OPTION >> ~/buildout
./xmlquery STOP_N >> ~/buildout
./xmlquery NTASKS >> ~/buildout
./xmlquery ROOTPE >> ~/buildout
./xmlquery JOB_QUEUE >> ~/buildout
./xmlquery CAM_CONFIG_OPTS >> ~/buildout
  

# SETUP CASE  
./case.setup
echo %%%%%%%%%% CASE SETUP COMPLETE %%%%%%%%%% 

#NAMELIST MODIFICATIONS 
#copy a prewritten namelist file to replace the standard
scp /n/home04/cgolja/CESM2_usernl_files/user_nl_cam_dailyvar user_nl_cam


# COPY YOUR RESTART FILES TO YOUR RUN DIRECTORY 
if [ $BRANCH == 1 ] ; then
   # This is from the CESM 2 guide .... 
   cp -a ${BRCDIR}* ${REST_COPY_TO}/${CASE_NAME}/run/
   # The below is EXE ROOT and seems like it might help 
   cp -a ${BRCDIR}* ${REST_COPY_TO}/${CASE_NAME}/bld/ 
fi

# PREVIEW NAMELIST: 
./preview_namelists
echo %%%%%%%% PREVIEW NAMELIST COMPLETE %%%%%%%%%%%

# BUILD CASE      
./case.build
echo %%%%%%%%% CASE BUILD COMPLETE %%%%%%% 

# CHECK CASE    
./check_case
echo %%%%%% CHECK CASE COMPLETE  %%%%%%% 

#SUBMIT CASE 
./case.submit 
echo %%%%%%%%%% CASE SUBMIT COMPLETE %%%%%%%%%%%%



#FIN 

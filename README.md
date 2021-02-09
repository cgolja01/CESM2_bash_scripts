# CESM2_bash_scripts
The purpose of these files is to automate the process of submitting or revising case builds/submits. Included are files and batch scripts for several situations that frequently occur

## 1. Building a Completely New Case:
* build_cesm_bash.sh: This performs tasks in the following order: sources required modules, creates a new case, edits xml variables, performs case setup, adds in user nl files, performs the model build, checks case, and submits 
  * This file can be located anywhere the user desires, but will output a "buildout" file that contains the executable outputs of all aforementioned steps. Together with standard err and out files, this is useful for debugging any issues 
* run_build_cesm: Sets up a batch submit script, indicating the user's requested cpus, memory and time allocation on the indicated partition. This will be variable based on user needs. This script clears "buildout" upon each submit.

## 2. Cleaning an Old Build: 
* clean_build_bash: sets up a simple build clean inside the case folder of anything you wish to clean and resubmit. The user will have to insert any required modifications between the clean and the re-build (eg xml changes or copying over new user_nl_<model> files). 
  * this will generate a file, "clean_buildout" in the folder in which you are running the build 
* run_clean_build: sets up the batch job to execute clean_build_bash 
 

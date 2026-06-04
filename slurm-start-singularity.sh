#!/bin/bash -l
# Allocate slurm resources, edit as necessary 
#SBATCH --account=$PAWSEY_PROJECT
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --job-name=rstudio_server
#SBATCH --partition=work 
#SBATCH --export=NONE

# Set our working directory
# Should be in a writable path with some space, like /scratch
# You'll need to manually change dir to this one through the RStudio interface
# Session -> Set Working Directory -> Choose Directory -> ...
dir="${MYSCRATCH}/rstudio-dir"

# Set the image and tag we want to use
image="docker://rocker/tidyverse:4.6.0"

# Load Singularity. The version may change over time. 
module load singularity/4.1.0-slurm

#!/bin/bash -l
# Allocate slurm resources, edit as necessary 
#SBATCH --account=pawsey1172
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

# You should not need to edit the lines below

# Prepare the working directory
mkdir -p $dir
cd ${dir}

# Get the image filename
imagename=${image##*/}
imagename=${imagename/:/_}.sif

# Create a user-specific tmp directory to avoid clashes between users
tmp_dir="${MYSCRATCH}/tmp/tmp_$USER"
mkdir -p $tmp_dir

# Get the hostname of the Setonix node
# We'll set up an SSH tunnel to connect to the RStudio server
host=$(hostname)

# Set the port for the SSH tunnel
# This part of the script uses a loop to search for available ports on the node;
# this will allow multiple instances of GUI servers to be run from the same host node
port="8787"
pfound="0"
while [ $port -lt 65535 ] ; do
  check=$( ss -tuna | awk '{print $4}' | grep ":$port *" )
  if [ "$check" == "" ] ; then
    pfound="1"
    break
  fi
  : $((++port))
done
if [ $pfound -eq 0 ] ; then
  echo "No available communication port found to establish the SSH tunnel."
  echo "Try again later. Exiting."
  exit
fi

# Generate a random password for the session
export PASSWORD=$(openssl rand -base64 15)

# Pull our Docker image in a folder
singularity pull --disable-cache $imagename $image

echo "*****************************************************"
echo "Setup - from your laptop do:"
echo "ssh -N -f -L ${port}:${host}:${port} $USER@setonix.pawsey.org.au"
echo "*****"
echo "The launch directory is: $dir"
echo "*****"
echo "Secret for this session is: $PASSWORD"
echo "*****************************************************"
echo ""
echo "*****************************************************"
echo "Terminate - from your laptop do:"
echo "kill \$( ps x | grep 'ssh.*-L *${port}:${host}:${port}' | awk '{print \$1}' )"
echo "*****************************************************"
echo ""

# Launch our container
# Note that content of /home will be lost after runtime
# You'll need to manually change dir to the working dir through the RStudio interface
# Session -> Set Working Directory -> Choose Directory -> ... 
srun -N $SLURM_JOB_NUM_NODES -n $SLURM_NTASKS -c $SLURM_CPUS_PER_TASK \
  singularity exec -c \
  -B ${tmp_dir}:/tmp \
  -B ${dir}:$HOME \
  -B ${tmp_dir}:/var \
  ${imagename} \
  rserver --www-port ${port} --www-address 0.0.0.0 --auth-none=0 --auth-pam-helper-path=pam-helper --server-user=$(whoami) 
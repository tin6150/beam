#!/bin/bash


#SBATCH                         --job-name=SnGpuTest    # -J CLI arg will overwrite this
#                                       CPU time (in seconds 1199 == 00:19:59 HH:MM:ss) :
#                                       Wall clock limit in HH:MM:ss
#SBATCH                         --time=00:59:00

#SBATCH                         --qos=lr_normal
#SBATCH                         --account=scs        # -A
#SBATCH                         --partition=lr6



#####SBATCH --time=60
#SBATCH --nodes=1
#####SBATCH --mem=184GB
#SBATCH --mem=90GB
#####SBATCH --partition=debug 

#SBATCH                         -o  sn_%N_%j.OUT.txt
#SBATCH                         -e  sn_%N_%j.ERR.txt


#### sbatch script to run beam container workflow via singularity

#### branch: tin/singularity  (off development)
#### will see if can run as singularity in lrc
#### tin 2021.0927
#### run as:
#### sbatch  run-beam-singularity.sh 
##XX xx test/input/beamville/beam.conf  2>&1 | tee docker_console.out

MyDir=$(pwd)

echo "current time is"
date
TZ=CUT date


#++ find out flat to ensure singularity store image as .SIF, then just test for that before this block.
cd /global/scratch/tin/tin-gh/beam/
[[ -d Singularity-repo ]] || mkdir Singularity-repo
cd    Singularity-repo
export SINGULARITY_TMPDIR="/global/scratch/tin/cacheDir" 
#// singularity pull docker://beammodel/beam:production-gemini-develop-1     
singularity pull docker://beammodel/beam:production-gemini-develop-1  || echo "Singularity image already cached"   
echo "**^ beyond singularity pull step ^**"

##config=$1
##input_folder_name="/projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/" 
##                                                                          ^--config base
#//input_folder_name="/global/home/users/tin/gs/tin-gh/beam/test/"
#input_folder_name="/global/scratch/tin/tin-gh/beam/test/"
input_folder_name="/global/scratch/tin/tin-gh/beam/"
output_folder_name="$input_folder_name/output" 
##cd /projects/geminixfc/repos/beam


#~~cd $MyDir
##cd /global/home/users/tin/gs/tin-gh/beam/test/input 
#XXXXcd /global/scratch/tin/tin-gh/beam/docker
#~~cd /global/scratch/tin/tin-gh/beam/

#~~input_folder_name="input"
#~~output_folder_name="beam_output"
#~~mkdir -m 777 $output_folder_name 2>/dev/null




#--module load singularity-container unset XDG_RUNTIME_DIR

unset LD_PRELOAD
#export SINGULARITY_BINDPATH="$input_folder_name:/app/production/sfbay/gemini"
export SINGULARITY_BINDPATH="$input_folder_name:/mnt"   # tmp as I don't have actual data for gemini
##export SINGULARITY_BINDPATH="$input_folder_name:/apps/output"   
# --mount source=/global/home/users/tin/tin-gh/beam/docker/test,destination=/app/test,type=bind --mount source=/global/home/users/tin/tin-gh/beam/docker/beam_output,destination=/app/output

# /app/production/sfbay/gemini exist inside the container
# /app/production/sfbay/gemini/gemini-base-2035.conf  maybe usable for --config
##config="production/sfbay/gemini/gemini-base-2035-helics-18k.conf"
config="production/sfbay/gemini/gemini-base-2035.conf"
#?config="input/beamville/beam.conf"
config="test/input/beamville/beam.conf"
#~~BeamBase=/global/scratch/tin/tin-gh/beam
#~~config="test/input/beamville/beam.conf"

#?? SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config
## **^ tin n0000.dirac1 /global/scratch/tin/tin-gh/beam/Singularity-repo ^**>  SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config
##/.singularity.d/actions/run: 9: export: -Xmx90g: bad variable name


#~~SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host --bind $BeamBase/test:/app  --bind $BeamBase/beam_output:/app/output    $BeamBase/Singularity-repo/beam_production-gemini-develop-1.sif --config $BeamBase/$config   2>&1

###cd $input_folder_name
###echo "Starting Singularity run as: SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host /global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif --config /mnt/$config 2>&1"
###SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host /global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif --config /mnt/$config   2>&1 

## echo "staring singularity run as: SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /mnt/$config"
## SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /mnt/$config  2>&1 | tee $input_folder_name/tin.$SLURM_JOB_ID.TEE_OUT  # mostly captured by slurm  -o ...
env | grep SINGULARITY
#echo  $input_folder_name
#ls -l $input_folder_name
#echo "---ls -l /mnt next---"
#ls -l /mnt


echo "Starting Singularity run as: SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config  2>&1 "
SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config  2>&1 

#//SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity shell --network host beam_production-gemini-develop-1.sif --config /app/$config

### seems to be expecting /projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/ production/sfbay/gemini/gemini-base-2035-helics-18k.conf

##SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx100g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config



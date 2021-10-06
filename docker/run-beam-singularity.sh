#!/bin/bash



#SBATCH                         --job-name=SnGpuTest    # -J CLI arg will overwrite this
#                               CPU time (in seconds 1199 == 00:19:59 HH:MM:ss) :
#                               Wall clock limit in HH:MM:ss
#SBATCH                         --time=07:59:00

#SBATCH                         --qos=lr_normal
#SBATCH                         --account=scs          # -A
#SBATCH                         --partition=lr_bigmem  # lr6


#SBATCH --nodes=1
#                              #SBATCH --mem=184GB
#                              #SBATCH --mem=90GB   # lr6
#SBATCH --mem=1390GB           # lr_bigmem

#SBATCH                        -o  sn_%N_%j.OUT.txt
#SBATCH                        -e  sn_%N_%j.ERR.txt


#### slurm sbatch script to run beam container workflow via singularity
####
#### branch: tin/singularity  (off development)
#### will see if can run as singularity in lrc
#### tin 2021.0928
#### run as:
#### sbatch  run-beam-singularity.sh 

#--MyDir=$(pwd)

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
echo "Current dir is $(pwd)"

##config=$1
##input_folder_name="/projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/" 
##                                                                          ^--config base

input_folder_name="/global/scratch/tin/tin-gh/beam/docker/PROD_EG/production"
output_folder_name="$input_folder_name/output" 

##cd /projects/geminixfc/repos/beam
#~~cd $MyDir
#~~cd /global/scratch/tin/tin-gh/beam/

#~~input_folder_name="input"
#~~output_folder_name="beam_output"
#~~mkdir -m 777 $output_folder_name 2>/dev/null




#--module load singularity-container unset XDG_RUNTIME_DIR

unset LD_PRELOAD
#export SINGULARITY_BINDPATH="$input_folder_name:/mnt"   # tmp as I don't have actual data for gemini
#??export SINGULARITY_BINDPATH="$input_folder_name:/app/production/sfbay/gemini"
export SINGULARITY_BINDPATH="$input_folder_name:/app/production"
##^^ working, got production2.zip unzipped at  docker/PROD_EG/
##^^ and there are contents as  docker/PROD_EG/production/sfbay/gemini/
# --mount source=/global/home/users/tin/tin-gh/beam/docker/test,destination=/app/test,type=bind --mount source=/global/home/users/tin/tin-gh/beam/docker/beam_output,destination=/app/output

# /app/production/sfbay/gemini exist inside the container
# /app/production/sfbay/gemini/gemini-base-2035.conf  maybe usable for --config
config="production/sfbay/gemini/gemini-base-2035-helics-18k.conf"
#~~config="production/sfbay/gemini/gemini-base-2035.conf"
#?config="input/beamville/beam.conf"
#~~config="test/input/beamville/beam.conf"
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
echo "config set to $config"
echo "i/o set to $input_folder_name $output_folder_name"
#echo  "ls -l of $input_folder_name"
#ls -l $input_folder_name
#echo "---ls -l /mnt next---"
#ls -l /mnt


echo "Starting Singularity run as: SINGULARITYENV_JAVA_OPTS='-Xmx1390g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config  2>&1 "
SINGULARITYENV_JAVA_OPTS='-Xmx1390g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config  2>&1 
#>>java -Xmx490g -cp /app/resources:/app/classes:/app/libs/* beam.sim.RunBeam --config /app/production/sfbay/gemini/gemini-base-2035.conf


#//SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity shell --network host beam_production-gemini-develop-1.sif --config /app/$config

### seems to be expecting /projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/ production/sfbay/gemini/gemini-base-2035-helics-18k.conf

##SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx100g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config



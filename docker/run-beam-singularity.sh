#!/bin/bash
#SBATCH --time=60
#SBATCH --account=scs
#SBATCH --nodes=1
#####SBATCH --mem=184GB
#SBATCH --mem=90GB
#SBATCH --partition=debug 

#### sbatch script to run beam container workflow via singularity

#### branch: tin/singularity  (off development)
#### will see if can run as singularity in lrc
#### tin 2021.0927
#### run as:
#### sbatch  run-beam-singularity.sh 
##XX xx test/input/beamville/beam.conf  2>&1 | tee docker_console.out


##config=$1

##input_folder_name="/projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/" 
##                                                                          ^--config base
input_folder_name="/global/home/users/tin/gs/tin-gh/beam/test/"
output_folder_name="$input_folder_name/output" 
##cd /projects/geminixfc/repos/beam
##cd /projects/geminixfc/repos/beam
cd /global/scratch/tin/tin-gh/beam/
[[ -d Singularity-repo ]] || mkdir Singularity-repo
cd    Singularity-repo

#--module load singularity-container unset XDG_RUNTIME_DIR

export SINGULARITY_TMPDIR="/global/scratch/tin/cacheDir" 
#// singularity pull docker://beammodel/beam:production-gemini-develop-1     
singularity pull docker://beammodel/beam:production-gemini-develop-1  || echo "Singularity image already cached"   
unset LD_PRELOAD
#export SINGULARITY_BINDPATH="$input_folder_name:/app/production/sfbay/gemini"
export SINGULARITY_BINDPATH="$input_folder_name:/mnt"   # tmp as I don't have actual data for gemini

# /app/production/sfbay/gemini exist inside the container
# /app/production/sfbay/gemini/gemini-base-2035.conf  maybe usable for --config
##config="production/sfbay/gemini/gemini-base-2035-helics-18k.conf"
config="production/sfbay/gemini/gemini-base-2035.conf"

#?? SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config
## **^ tin n0000.dirac1 /global/scratch/tin/tin-gh/beam/Singularity-repo ^**>  SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config
##/.singularity.d/actions/run: 9: export: -Xmx90g: bad variable name

SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config

#//SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity shell --network host beam_production-gemini-develop-1.sif --config /app/$config

### seems to be expecting /projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/ production/sfbay/gemini/gemini-base-2035-helics-18k.conf

##SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx100g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config




# from Zach's email 2021.0826
# this doesn't bind the input/output dir, but make sure things run and not dir binding issue, or not finding files.
# i guess the container has example files for beamville in there

docker run --network host --env 'JAVA_OPTS=-Xmx50g -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap' beammodel/beam:0.8.6 --config=test/input/beamville/beam.conf


#### email about run via singularity
#!/bin/bash
#SBATCH --time=60
#SBATCH --account=geminixfc
#SBATCH --nodes=1
#SBATCH --mem=184GB
#SBATCH --partition=debug config="production/sfbay/gemini/gemini-base-2035-helics-18k.conf"

input_folder_name="/projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/" 
output_folder_name="$input_folder_name/output" cd /projects/geminixfc/repos/beam

module load singularity-container unset XDG_RUNTIME_DIR
export SINGULARITY_TMPDIR="/tmp/scratch" singularity pull docker://beammodel/beam:production-gemini-develop-1

unset LD_PRELOAD
export SINGULARITY_BINDPATH="$input_folder_name:/app/production/sfbay/gemini"
SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx100g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config

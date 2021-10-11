#!/bin/bash 

# dead simple minded sbatch script to test running java in singularity container (from the beam/atlas project)

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

#SBATCH                        -o  snJv_%N_%j.OUT.txt
#SBATCH                        -e  snJv_%N_%j.ERR.txt


# run as
# sbatch TinHelloWorld.sbatch
# worked on command line, as stated in TinHelloWorld.java
singularity exec /global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif  java -cp /global/scratch/tin/tin-gh/beam/docker/PROD_EG/production TinHelloWorld 2>&1

echo "try 2"

input_folder_name="/global/scratch/tin/tin-gh/beam/docker/PROD_EG/production"
export SINGULARITY_BINDPATH="$input_folder_name:/app/production"
#export JAVA_CLASSPATH="-cp /app/production"
export JAVA_CLASSPATH="-cp /app/resources:/app/classes:/app/libs:/app/production"
export S_IMG=/global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif
export dummy=some/dummy/path
singularity exec --bind $SINGULARITY_BINDPATH $S_IMG  java $JAVA_CLASSPATH TinHelloWorld --config /app/$dummy    2>&1


#export JAVA_OPTS="-Xms12g"  
#export JAVA_OPTS="-Xmx1390g" 
export JAVA_OPTS="-Djava.awt.headless=true" 
echo "--try 3 as: singularity exec --bind $SINGULARITY_BINDPATH $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld   "
singularity exec --bind $SINGULARITY_BINDPATH $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld    2>&1


echo "----" 
echo "--it seems JAVA_OPTS just cant be more than 1 param, -classpath is treated just fine though"
# kinda bug? https://github.com/hpcng/singularity/issues/719  

#export JAVA_OPTS="-Xms12g -Xmx1390g -Djava.awt.headless=true" 
export JAVA_OPTS='-Xms12g -Xmx1390g'
#XXexport JAVA_OPTS="-Xmx1390g\ -Djava.awt.headless=true" 
echo "--try *4* as: singularity exec --bind $SINGULARITY_BINDPATH $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld   "
singularity exec --bind $SINGULARITY_BINDPATH $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld    2>&1


echo "----" 
echo "----" 
echo "--try 5, all spelled out, no vars--" 
echo "----" 

singularity exec --bind /global/scratch/tin/tin-gh/beam/docker/PROD_EG/production:/app/production /global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif  java -Xmx1390g  -Djava.awt.headless=true -cp /app/production TinHelloWorld 2>&1
singularity exec --bind /global/scratch/tin/tin-gh/beam/docker/PROD_EG/production:/app/production /global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif  java -Djava.awt.headless=true -cp /app/production -Xmx1390g TinHelloWorld 2>&1
echo "----****----"
echo "----next last one should work----"
echo "----****----"
## but dont, = sign in -D... maybe tripping something else, having it in a variable worked in above
singularity exec --bind /global/scratch/tin/tin-gh/beam/docker/PROD_EG/production:/app/production /global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif  java -Djava.awt.headless=true -cp /app/production TinHelloWorld 2>&1

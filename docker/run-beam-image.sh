#!/bin/bash

config=$1
beam_image="beammodel/beam:0.8.6"
##beam_image="beammodel/beam:production-gemini-develop-4"

#### branch: tin/singularity  (off development)
#### try to start docker with an pulled image
#### will see if can run as singularity in lrc
#### tin 2021.0821
#### run as:
#### cp -pRi ../test .
#### bash -x run-beam-image.sh test/input/beamville/beam.conf
#### bash -x run-beam-image.sh test/input/sf-bay/  # nowhere else has beam.conf.

input_folder_name="test"
output_folder_name="beam_output"
mkdir -m 777 $output_folder_name 2>/dev/null

##max_ram='10g'
max_ram='50g'
java_opts="-Xmx$max_ram -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"

docker run \
  --network host \
  --env JAVA_OPTS="$java_opts" \
  --mount source="$(pwd)/$input_folder_name",destination=/app/$input_folder_name,type=bind \
  --mount source="$(pwd)/$output_folder_name",destination=/app/output,type=bind \
  $beam_image --config=$config



#### end up being:
#+ config=test/input/beamville/beam.conf
#+ beam_image=beammodel/beam:0.8.6
#+ input_folder_name=test
#+ output_folder_name=beam_output
#+ mkdir -m 777 beam_output
#+ max_ram=50g
#+ java_opts='-Xmx50g -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap'
#++ pwd
#++ pwd
#+ docker run --network host --env 'JAVA_OPTS=-Xmx50g -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap' --mount source=/global/home/users/tin/tin-gh/beam/docker/test,destination=/app/test,type=bind --mount source=/global/home/users/tin/tin-gh/beam/docker/beam_output,destination=/app/output,type=bind beammodel/beam:0.8.6 --config=test/input/beamville/beam.conf


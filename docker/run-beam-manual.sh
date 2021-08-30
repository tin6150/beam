
# from Zach's email 2021.0826
# this doesn't bind the input/output dir, but make sure things run and not dir binding issue, or not finding files.
# i guess the container has example files for beamville in there

docker run --network host --env 'JAVA_OPTS=-Xmx50g -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap' beammodel/beam:0.8.6 --config=test/input/beamville/beam.conf

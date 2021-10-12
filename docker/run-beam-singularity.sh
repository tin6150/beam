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
#++singularity pull docker://beammodel/beam:production-gemini-develop-1  || echo "Singularity image already cached"   
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

#export JAR_LIST="/app/libs/GeographicLib-Java-1.44.jar:/app/libs/RoaringBitmap-0.7.3.jar:/app/libs/ST4-4.0.8.jar:/app/libs/activation-1.1.jar:/app/libs/agrona-1.4.1.jar:/app/libs/akka-actor_2.12-2.6.6.jar:/app/libs/akka-cluster-tools_2.12-2.6.6.jar:/app/libs/akka-cluster_2.12-2.6.6.jar:/app/libs/akka-coordination_2.12-2.6.6.jar:/app/libs/akka-http-circe_2.12-1.25.2.jar:/app/libs/akka-http-core_2.12-10.1.12.jar:/app/libs/akka-http_2.12-10.1.12.jar:/app/libs/akka-kryo-serialization_2.12-0.5.2.jar:/app/libs/akka-parsing_2.12-10.1.12.jar:/app/libs/akka-pki_2.12-2.6.6.jar:/app/libs/akka-protobuf-v3_2.12-2.6.6.jar:/app/libs/akka-remote_2.12-2.6.6.jar:/app/libs/akka-slf4j_2.12-2.6.6.jar:/app/libs/akka-stream_2.12-2.6.6.jar:/app/libs/animal-sniffer-annotations-1.17.jar:/app/libs/annotations-2.0.1.jar:/app/libs/antlr-runtime-3.5.2.jar:/app/libs/antlr4-4.5.1.jar:/app/libs/antlr4-runtime-4.5.1.jar:/app/libs/aopalliance-1.0.jar:/app/libs/apacheds-i18n-2.0.0-M15.jar:/app/libs/apacheds-kerberos-codec-2.0.0-M15.jar:/app/libs/api-asn1-api-1.0.0-M20.jar:/app/libs/api-util-1.0.0-M20.jar:/app/libs/ascii-utf-themes-0.0.1.jar:/app/libs/asciitable-0.3.2.jar:/app/libs/asm-5.0.4.jar:/app/libs/asn-one-0.4.0.jar:/app/libs/atom-v_1_0-1.1.0.jar:/app/libs/avro-1.8.2.jar:/app/libs/aws-java-sdk-core-1.11.341.jar:/app/libs/aws-java-sdk-kms-1.11.341.jar:/app/libs/aws-java-sdk-s3-1.11.341.jar:/app/libs/beam-utilities-v0.2.11.jar:/app/libs/bicycle-0.10.0.jar:/app/libs/caffeine-2.6.2.jar:/app/libs/cats-core_2.12-2.1.0.jar:/app/libs/cats-kernel_2.12-2.1.0.jar:/app/libs/cats-macros_2.12-2.1.0.jar:/app/libs/char-translation-0.0.2.jar:/app/libs/checker-qual-2.5.2.jar:/app/libs/circe-core_2.12-0.13.0.jar:/app/libs/circe-generic_2.12-0.13.0.jar:/app/libs/circe-jawn_2.12-0.13.0.jar:/app/libs/circe-numbers_2.12-0.13.0.jar:/app/libs/circe-parser_2.12-0.13.0.jar:/app/libs/commons-beanutils-1.7.0.jar:/app/libs/commons-beanutils-core-1.8.0.jar:/app/libs/commons-cli-1.4.jar:/app/libs/commons-codec-1.10.jar:/app/libs/commons-collections-3.2.2.jar:/app/libs/commons-collections4-4.1.jar:/app/libs/commons-compress-1.18.jar:/app/libs/commons-configuration-1.6.jar:/app/libs/commons-dbcp2-2.1.1.jar:/app/libs/commons-dbutils-1.6.jar:/app/libs/commons-digester-1.8.jar:/app/libs/commons-httpclient-3.1.jar:/app/libs/commons-io-2.5.jar:/app/libs/commons-lang-2.6.jar:/app/libs/commons-lang3-3.4.jar:/app/libs/commons-logging-1.2.jar:/app/libs/commons-math3-3.5.jar:/app/libs/commons-net-3.1.jar:/app/libs/commons-pool-1.6.jar:/app/libs/commons-pool2-2.4.2.jar:/app/libs/config-1.4.0.jar:/app/libs/converter-moshi-2.6.1.jar:/app/libs/core-0.26.jar:/app/libs/core-3.1.0.jar:/app/libs/curator-client-2.7.1.jar:/app/libs/curator-framework-2.7.1.jar:/app/libs/curator-recipes-2.7.1.jar:/app/libs/decongestion-0.11.0-2018w44.jar:/app/libs/elki-0.7.5.jar:/app/libs/elki-classification-0.7.5.jar:/app/libs/elki-clustering-0.7.5.jar:/app/libs/elki-core-0.7.5.jar:/app/libs/elki-core-api-0.7.5.jar:/app/libs/elki-core-data-0.7.5.jar:/app/libs/elki-core-dbids-0.7.5.jar:/app/libs/elki-core-dbids-int-0.7.5.jar:/app/libs/elki-core-distance-0.7.5.jar:/app/libs/elki-core-math-0.7.5.jar:/app/libs/elki-core-parallel-0.7.5.jar:/app/libs/elki-core-util-0.7.5.jar:/app/libs/elki-data-generator-0.7.5.jar:/app/libs/elki-database-0.7.5.jar:/app/libs/elki-geo-0.7.5.jar:/app/libs/elki-index-0.7.5.jar:/app/libs/elki-index-lsh-0.7.5.jar:/app/libs/elki-index-mtree-0.7.5.jar:/app/libs/elki-index-preprocessed-0.7.5.jar:/app/libs/elki-index-rtree-0.7.5.jar:/app/libs/elki-index-various-0.7.5.jar:/app/libs/elki-input-0.7.5.jar:/app/libs/elki-itemsets-0.7.5.jar:/app/libs/elki-logging-0.7.5.jar:/app/libs/elki-outlier-0.7.5.jar:/app/libs/elki-persistent-0.7.5.jar:/app/libs/elki-precomputed-0.7.5.jar:/app/libs/elki-timeseries-0.7.5.jar:/app/libs/enumeratum-circe_2.12-1.5.14.jar:/app/libs/enumeratum-macros_2.12-1.5.9.jar:/app/libs/enumeratum_2.12-1.5.13.jar:/app/libs/error_prone_annotations-2.2.0.jar:/app/libs/failureaccess-1.0.1.jar:/app/libs/fastutil-8.5.2.jar:/app/libs/fluent-hc-4.5.2.jar:/app/libs/geojson-jackson-1.5.jar:/app/libs/google-maps-services-0.14.0.jar:/app/libs/grabbag-1.8.1.jar:/app/libs/graphhopper-api-1.0.jar:/app/libs/graphhopper-core-1.0.jar:/app/libs/graphql-java-2016-02-19T11-51-00.jar:/app/libs/grizzly-framework-2.4.3.jar:/app/libs/grizzly-http-2.4.3.jar:/app/libs/grizzly-http-server-2.4.3.jar:/app/libs/grpc-context-1.25.0.jar:/app/libs/gson-2.8.5.jar:/app/libs/gt-api-16.0.jar:/app/libs/gt-coverage-14.0.jar:/app/libs/gt-data-14.5.jar:/app/libs/gt-epsg-hsql-16.0.jar:/app/libs/gt-epsg-wkt-15.2.jar:/app/libs/gt-geojson-14.0.jar:/app/libs/gt-geotiff-14.0.jar:/app/libs/gt-grid-16.0.jar:/app/libs/gt-main-16.0.jar:/app/libs/gt-metadata-16.0.jar:/app/libs/gt-opengis-16.0.jar:/app/libs/gt-referencing-16.0.jar:/app/libs/gt-shapefile-14.5.jar:/app/libs/gtfs-lib-3.0.7.jar:/app/libs/guava-27.0.1-jre.jar:/app/libs/guice-4.1.0.jar:/app/libs/guice-assistedinject-4.1.0.jar:/app/libs/guice-multibindings-4.1.0.jar:/app/libs/h3-3.4.1.jar:/app/libs/hadoop-annotations-2.7.3.jar:/app/libs/hadoop-auth-2.7.3.jar:/app/libs/hadoop-client-2.7.3.jar:/app/libs/hadoop-common-2.7.3.jar:/app/libs/hadoop-hdfs-2.7.3.jar:/app/libs/hadoop-mapreduce-client-app-2.7.3.jar:/app/libs/hadoop-mapreduce-client-common-2.7.3.jar:/app/libs/hadoop-mapreduce-client-core-2.7.3.jar:/app/libs/hadoop-mapreduce-client-jobclient-2.7.3.jar:/app/libs/hadoop-mapreduce-client-shuffle-2.7.3.jar:/app/libs/hadoop-yarn-api-2.7.3.jar:/app/libs/hadoop-yarn-client-2.7.3.jar:/app/libs/hadoop-yarn-common-2.7.3.jar:/app/libs/hadoop-yarn-server-common-2.7.3.jar:/app/libs/hadoop-yarn-server-nodemanager-2.7.3.jar:/app/libs/helics-wrapper-v2.6.1.jar:/app/libs/hppc-0.8.1.jar:/app/libs/hsqldb-2.3.0.jar:/app/libs/htrace-core-3.1.0-incubating.jar:/app/libs/httpclient-4.5.5.jar:/app/libs/httpcore-4.4.9.jar:/app/libs/imageio-ext-geocore-1.1.12.jar:/app/libs/imageio-ext-streams-1.1.12.jar:/app/libs/imageio-ext-tiff-1.1.12.jar:/app/libs/imageio-ext-utilities-1.1.12.jar:/app/libs/influxdb-java-2.16.jar:/app/libs/ion-java-1.0.2.jar:/app/libs/j2objc-annotations-1.1.jar:/app/libs/jackson-annotations-2.9.4.jar:/app/libs/jackson-core-2.9.4.jar:/app/libs/jackson-core-asl-1.9.13.jar:/app/libs/jackson-databind-2.9.4.jar:/app/libs/jackson-dataformat-cbor-2.6.7.jar:/app/libs/jackson-datatype-jdk8-2.8.9.jar:/app/libs/jackson-datatype-jsr310-2.8.9.jar:/app/libs/jackson-jaxrs-1.9.13.jar:/app/libs/jackson-mapper-asl-1.9.13.jar:/app/libs/jackson-module-paranamer-2.9.4.jar:/app/libs/jackson-module-scala_2.12-2.9.4.jar:/app/libs/jackson-xc-1.9.13.jar:/app/libs/jackson2-geojson-0.8.jar:/app/libs/jafama-2.3.2.jar:/app/libs/jai_core-1.1.3.jar:/app/libs/java-hamcrest-2.0.0.0.jar:/app/libs/javacsv-2.0.jar:/app/libs/javassist-3.19.0-GA.jar:/app/libs/javax.annotation-api-1.2-b01.jar:/app/libs/javax.inject-1.jar:/app/libs/javax.servlet-api-3.1.0.jar:/app/libs/jawn-parser_2.12-1.0.0.jar:/app/libs/jaxb-api-2.2.2.jar:/app/libs/jaxb-impl-2.2.3-1.jar:/app/libs/jaxb2-basics-runtime-0.9.4.jar:/app/libs/jcommander-1.72.jar:/app/libs/jcommon-1.0.23.jar:/app/libs/jdom-1.1.3.jar:/app/libs/jdom2-2.0.5.jar:/app/libs/jersey-client-1.9.jar:/app/libs/jersey-core-1.9.jar:/app/libs/jersey-guice-1.9.jar:/app/libs/jersey-json-1.9.jar:/app/libs/jersey-server-1.9.jar:/app/libs/jettison-1.1.jar:/app/libs/jetty-client-9.4.8.v20171121.jar:/app/libs/jetty-http-9.4.8.v20171121.jar:/app/libs/jetty-io-9.4.8.v20171121.jar:/app/libs/jetty-security-9.4.8.v20171121.jar:/app/libs/jetty-server-9.4.8.v20171121.jar:/app/libs/jetty-servlet-9.4.8.v20171121.jar:/app/libs/jetty-util-6.1.26.jar:/app/libs/jetty-util-9.4.8.v20171121.jar:/app/libs/jetty-webapp-9.4.8.v20171121.jar:/app/libs/jetty-xml-9.4.8.v20171121.jar:/app/libs/jfreechart-1.0.19.jar:/app/libs/jgrapht-core-1.3.0.jar:/app/libs/jgridshift-1.0.jar:/app/libs/jheaps-0.9.jar:/app/libs/jinjava-2.0.5.jar:/app/libs/jline-0.9.94.jar:/app/libs/jmespath-java-1.11.341.jar:/app/libs/jna-4.5.1.jar:/app/libs/joda-time-2.9.9.jar:/app/libs/json-simple-1.1.jar:/app/libs/json4s-ast_2.12-3.5.0.jar:/app/libs/json4s-core_2.12-3.5.0.jar:/app/libs/json4s-native_2.12-3.5.0.jar:/app/libs/json4s-scalap_2.12-3.5.0.jar:/app/libs/jsoup-1.8.1.jar:/app/libs/jsp-api-2.1.jar:/app/libs/jsr-275-1.0-beta-2.jar:/app/libs/jsr305-3.0.2.jar:/app/libs/jt-affine-1.0.6.jar:/app/libs/jt-algebra-1.0.6.jar:/app/libs/jt-bandcombine-1.0.6.jar:/app/libs/jt-bandmerge-1.0.6.jar:/app/libs/jt-bandselect-1.0.6.jar:/app/libs/jt-binarize-1.0.6.jar:/app/libs/jt-border-1.0.6.jar:/app/libs/jt-buffer-1.0.6.jar:/app/libs/jt-classifier-1.0.6.jar:/app/libs/jt-colorconvert-1.0.6.jar:/app/libs/jt-colorindexer-1.0.6.jar:/app/libs/jt-crop-1.0.6.jar:/app/libs/jt-errordiffusion-1.0.6.jar:/app/libs/jt-format-1.0.6.jar:/app/libs/jt-imagefunction-1.0.6.jar:/app/libs/jt-iterators-1.0.6.jar:/app/libs/jt-lookup-1.0.6.jar:/app/libs/jt-mosaic-1.0.6.jar:/app/libs/jt-nullop-1.0.6.jar:/app/libs/jt-orderdither-1.0.6.jar:/app/libs/jt-piecewise-1.0.6.jar:/app/libs/jt-rescale-1.0.6.jar:/app/libs/jt-rlookup-1.0.6.jar:/app/libs/jt-scale-1.0.6.jar:/app/libs/jt-stats-1.0.6.jar:/app/libs/jt-translate-1.0.6.jar:/app/libs/jt-utilities-1.0.6.jar:/app/libs/jt-utils-1.4.0.jar:/app/libs/jt-vectorbin-1.0.6.jar:/app/libs/jt-warp-1.0.6.jar:/app/libs/jt-zonal-1.0.6.jar:/app/libs/jt-zonalstats-1.4.0.jar:/app/libs/jts-1.13.jar:/app/libs/jts-core-1.15.1.jar:/app/libs/juel-api-2.2.7.jar:/app/libs/juel-impl-2.2.7.jar:/app/libs/juel-spi-2.2.7.jar:/app/libs/kamon-core_2.12-2.0.1.jar:/app/libs/kml-v_2_2_0-2.2.0.jar:/app/libs/kryo-4.0.2.jar:/app/libs/kryo-serializers-0.42.jar:/app/libs/kryo-tools-1.2.0.jar:/app/libs/leveldbjni-all-1.8.jar:/app/libs/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar:/app/libs/log4j-1.2.17.jar:/app/libs/log4j-over-slf4j-1.7.25.jar:/app/libs/logback-classic-1.2.3.jar:/app/libs/logback-core-1.2.3.jar:/app/libs/logging-interceptor-3.14.3.jar:/app/libs/lz4-1.3.0.jar:/app/libs/macro-compat_2.12-1.1.1.jar:/app/libs/mapdb-1.0.8.jar:/app/libs/matsim-0.10.1-beam-15.jar:/app/libs/minlog-1.3.0.jar:/app/libs/moshi-1.8.0.jar:/app/libs/msgpack-core-0.8.17.jar:/app/libs/multimodal-0.10.0.jar:/app/libs/netty-3.7.0.Final.jar:/app/libs/netty-all-4.0.23.Final.jar:/app/libs/nuprocess-1.2.4.jar:/app/libs/objenesis-2.5.1.jar:/app/libs/ojalgo-46.2.0.jar:/app/libs/okhttp-2.7.5.jar:/app/libs/okhttp-3.14.4.jar:/app/libs/okio-1.17.2.jar:/app/libs/opencensus-api-0.25.0.jar:/app/libs/optimus-solver-oj_2.12-3.1.0.jar:/app/libs/optimus_2.12-3.1.0.jar:/app/libs/or-tools-wrapper-7.5-0.jar:/app/libs/osm-lib-1.4.0.jar:/app/libs/osmosis-osm-binary-0.45.jar:/app/libs/paranamer-2.8.jar:/app/libs/parquet-avro-1.10.0.jar:/app/libs/parquet-column-1.10.0.jar:/app/libs/parquet-common-1.10.0.jar:/app/libs/parquet-encoding-1.10.0.jar:/app/libs/parquet-format-2.4.0.jar:/app/libs/parquet-hadoop-1.10.0.jar:/app/libs/parquet-jackson-1.10.0.jar:/app/libs/play-functional_2.12-2.6.3.jar:/app/libs/play-json_2.12-2.6.3.jar:/app/libs/polyline-encoder-0.1.jar:/app/libs/postgresql-42.0.0.jar:/app/libs/probability-monad_2.11-1.0.1.jar:/app/libs/protobuf-java-2.6.1.jar:/app/libs/r5-3ab4fa04.jar:/app/libs/reactive-streams-1.0.3.jar:/app/libs/reflectasm-1.11.3.jar:/app/libs/reflections-0.9.10.jar:/app/libs/retrofit-2.6.1.jar:/app/libs/scala-collection-compat_2.12-2.1.6.jar:/app/libs/scala-compiler-2.12.12.jar:/app/libs/scala-guice_2.12-4.1.0.jar:/app/libs/scala-java8-compat_2.12-0.8.0.jar:/app/libs/scala-library-2.12.12.jar:/app/libs/scala-logging_2.12-3.9.0.jar:/app/libs/scala-parser-combinators_2.12-1.1.2.jar:/app/libs/scala-reflect-2.12.12.jar:/app/libs/scala-xml_2.12-1.3.0.jar:/app/libs/scalac-scapegoat-plugin_2.12.11-1.4.5.jar:/app/libs/scopt_2.12-4.0.0-RC2.jar:/app/libs/servlet-api-2.5.jar:/app/libs/shapeless_2.12-2.3.3.jar:/app/libs/sigopt-java-4.9.0.jar:/app/libs/skb-interfaces-0.0.1.jar:/app/libs/slf4j-api-1.7.30.jar:/app/libs/snakeyaml-1.18.jar:/app/libs/snappy-java-1.1.2.6.jar:/app/libs/socnetsim-0.10.0.jar:/app/libs/sourcecode_2.12-0.1.9.jar:/app/libs/spark-core-2.7.2.jar:/app/libs/spray-json_2.12-1.3.5.jar:/app/libs/ssl-config-core_2.12-0.4.1.jar:/app/libs/stax-api-1.0-2.jar:/app/libs/super-csv-2.4.0.jar:/app/libs/trove4j-3.0.3.jar:/app/libs/tscfg-v0.9.4.jar:/app/libs/univocity-parsers-2.8.1.jar:/app/libs/uuid-3.4.0.jar:/app/libs/websocket-api-9.4.8.v20171121.jar:/app/libs/websocket-client-9.4.8.v20171121.jar:/app/libs/websocket-common-9.4.8.v20171121.jar:/app/libs/websocket-server-9.4.8.v20171121.jar:/app/libs/websocket-servlet-9.4.8.v20171121.jar:/app/libs/xercesImpl-2.9.1.jar:/app/libs/xml-apis-1.3.04.jar:/app/libs/xmlenc-0.52.jar:/app/libs/xmlgraphics-commons-2.3.jar:/app/libs/xz-1.5.jar:/app/libs/zookeeper-3.4.6.jar"
#??export JAVA_OPTS="-Xms12g -Xmx1390g -Djava.awt.headless=true -cp /app/resources:/app/classes:$JAR_LIST beam.sim.RunBeam"
#export JAVA_OPTS="-Xms12g -Xmx1390g -Djava.awt.headless=true -cp /app/resources:/app/classes:/app/libs   beam.sim.RunBeam"
export JAVA_CLASSPATH="-classpath /app/resources:/app/classes:/app/libs:$JAR_LIST"
export JAVA_OPTS="-Djava.awt.headless=true" 
export JAVA_OPTS="-Xmx1390g"
env | grep SINGULARITY
echo "config set to $config"
echo "i/o set to $input_folder_name $output_folder_name"
echo "JAVA_OPTS is $JAVA_OPTS"
#echo  "ls -l of $input_folder_name"
#ls -l $input_folder_name
#echo "---ls -l /mnt next---"
#ls -l /mnt
export S_IMG=/global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif
echo "--"
echo "--"


#++++SINGULARITYENV_JAVA_OPTS='-Xmx1390g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config  2>&1 
echo "++Running as: SINGULARITYENV_JAVA_OPTS=$JAVA_OPTS singularity run --network host $S_IMG  --config /app/$config  2>&1"
SINGULARITYENV_JAVA_OPTS=$JAVA_OPTS singularity run --network host $S_IMG  --config /app/$config  2>&1 

#++singularity exec -B $SINGULARITY_BINDPATH --network host beam_production-gemini-develop-1.sif  /usr/local/openjdk-8/bin/java  $JAVA_OPTS  --config /app/$config  2>&1 
## problem is that singularity 3.2 isn't likely taking options at the end to pass to the java cmd, or java interaction with container  parse error...
#%%%% singularity exec -B $SINGULARITY_BINDPATH --network host beam_production-gemini-develop-1.sif  /usr/local/openjdk-8/bin/java  $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld --config /app/$config

## ++ if only 1 param for JAVA_OPTS only anyway, may as well go back to use singularity run rather than exec, then don't have to specify that ugly long classpath
## actually still get some JNI complains when used with java exec
#** singularity exec -B $SINGULARITY_BINDPATH --network host $S_IMG  /usr/local/openjdk-8/bin/java  $JAVA_OPTS  $JAVA_CLASSPATH beam.sim.RunBeam --config /app/$config  2>&1 
echo "----after singularity run ... java... " 
#++ need to know what code they run with java that call --config...

#>>java -Xmx490g -cp /app/resources:/app/classes:/app/libs/* beam.sim.RunBeam --config /app/production/sfbay/gemini/gemini-base-2035.conf


#//SINGULARITYENV_JAVA_OPTS='-Xmx90g' singularity shell --network host beam_production-gemini-develop-1.sif --config /app/$config

### seems to be expecting /projects/geminixfc/repos/beam/configs/beam-run-configs/production/sfbay/gemini/ production/sfbay/gemini/gemini-base-2035-helics-18k.conf

##SINGULARITYENV_JAVA_OPTS='-Xms12g -Xmx100g' singularity run --network host beam_production-gemini-develop-1.sif --config /app/$config



exit $?

##  test with TinHelloWorld , .class placed in /global/scratch/tin/tin-gh/beam/docker/PROD_EG/production
export JAVA_CLASSPATH="-cp /app/production"
export S_IMG=/global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif
export JAVA_OPTS="-Xms12g -Xmx1390g -Djava.awt.headless=true" 
##echo "another try as: singularity exec -B $SINGULARITY_BINDPATH $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld"
##singularity exec -B $SINGULARITY_BINDPATH $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld 2>&1
##singularity exec  $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld 2>&1
## see TinHelloWorld.sbatch  parsing JAVA_OPTS is buggy somewhere along the line :/




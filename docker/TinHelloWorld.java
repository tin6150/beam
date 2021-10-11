
/*

javac              TinHelloWorld
java -classpath  . TinHelloWorld


input_folder_name="/global/scratch/tin/tin-gh/beam/docker/PROD_EG/production"
output_folder_name="$input_folder_name/output"

cp -p TinHelloWorld.class  $input_folder_name
java -classpath  $input_folder_name TinHelloWorld

export SINGULARITY_BINDPATH="$input_folder_name:/app/production"

cd /global/scratch/tin/tin-gh/beam/Singularity-repo

export JAVA_OPTS="-Xms12g -Xmx1390g -Djava.awt.headless=true -cp /app/resources:/app/classes:/app/libs   -cp /app/production"
export JAVA_OPTS="-Xms12g -Xmx1390g -Djava.awt.headless=true" 
export JAVA_CLASSPATH="-cp /app/production"

#XX singularity exec -B $SINGULARITY_BINDPATH --network host beam_production-gemini-develop-1.sif  /usr/local/openjdk-8/bin/java  $JAVA_OPTS TinHelloWorld --config /app/$config 
singularity exec -B $SINGULARITY_BINDPATH --network host beam_production-gemini-develop-1.sif  /usr/local/openjdk-8/bin/java  "$JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld --config /app/$config"

## problem is singularity exec take command but leave all the options as subsequent command , not as args to the java cmd 

*/

/*


these works:
singularity exec /global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif  java -cp /global/scratch/tin/tin-gh/beam/docker/PROD_EG/production TinHelloWorld

singularity exec -B /global/scratch/tin/tin-gh/beam/docker/PROD_EG/production:/app/production beam_production-gemini-develop-1.sif java -cp /app/production/ TinHelloWorld      

input_folder_name="/global/scratch/tin/tin-gh/beam/docker/PROD_EG/production"
export SINGULARITY_BINDPATH="$input_folder_name:/app/production"
singularity exec -B SINGULARITY_BINDPATH beam_production-gemini-develop-1.sif java -cp /app/production/ TinHelloWorld      

export JAVA_CLASSPATH="-cp /app/production"
singularity exec -B SINGULARITY_BINDPATH beam_production-gemini-develop-1.sif java $JAVA_CLASSPATH TinHelloWorld    

export S_IMG=/global/scratch/tin/tin-gh/beam/Singularity-repo/beam_production-gemini-develop-1.sif
singularity exec -B SINGULARITY_BINDPATH $S_IMG  java $JAVA_CLASSPATH TinHelloWorld    

export JAVA_OPTS="-Xms12g -Xmx1390g -Djava.awt.headless=true" 
singularity exec -B SINGULARITY_BINDPATH $S_IMG  java $JAVA_OPTS $JAVA_CLASSPATH TinHelloWorld    


*/


public class TinHelloWorld {
   public static void main(String[] args) {
      // Prints "Hello, World" in the terminal window.
      System.out.println("Hello World, Java, Singularity?");
   }
}

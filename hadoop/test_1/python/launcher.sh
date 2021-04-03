#!/bin/bash

# This script requires that the environmental variable HADOOP_HOME be set on your machine pointing 
# to the root of your Hadoop installation and that all Hadoop services (NameNode, DataNode, ResourceManager,
# and NodeManager) 

# create a temporary place to download the test input to and upload to hdfs from
if [[ -d ~/tmp_input_dir ]]
then
  echo "Input directory found at ~/tmp_input_dir."
  echo "Using data there for input."
else
  # if no previously defined data in the /tmp_input dir, then create one
  echo "No pre-made directory at ~/tmp_input_dir."
  echo "Creating one now..."
  mkdir -p ~/tmp_input_dir
  cd ~/temp_input_dir
  
  # then download three decently lengthy books from Project Gutenberg to use for analysis
  echo "Downloading some test text files..."
  wget http://www.gutenberg.org/files/5000/5000-8.txt
  wget http://www.gutenberg.org/files/4300/4300-0.txt
  wget http://www.gutenberg.org/files/2600/2600-0.txt
  echo "New data files downloaded."
fi


# creating a place to hold the input files on the hdfs cluster
hdfs dfs -mkdir /mr_tests
hdfs dfs -mkdir /mr_tests/input

# moving input files there and deleting local input files
hdfs dfs -put ~/tmp_input_dir/* /mr_tests/input/
rm -R ~/tmp_input_dir

# prepare output directory on the hdfs cluster
hdfs dfs -mkdir /mr_tests/output

echo "Running Hadoop Streaming Map Reduce job now..."
# Hadoop command to run the hadoop-streaming jar on the cluster with the following inputs:
# input    hdfs://mr_tests/input
# output   hdfs://mr_tests/output
# mapper   $RUN_DIR/mapper_easy.py
# reducer  $RUN_DIR/reducer_easy.py
$HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming*.jar \
-input /mr_tests/input/* -output /mr_tests/output/ \
-file mapper_easy.py     -mapper mapper_easy.py    \
-file reducer_easy.py    -reducer reducer_easy.py

# saving the process ID (pid) of the previous command to wait for it to finish
pid=$!
wait $pid
echo "Processing finished..."

# creating a local output location for results and moving from hdfs to there
mkdir ~/mr_test_output
hdfs dfs -get /mr_tests/output ~/mr_test_output
echo "You can now find the results in ~/mr_test_output!"

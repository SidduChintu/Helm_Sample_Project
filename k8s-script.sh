#This script helps us in getting result from multiple clusters at a time
#This script will automatically switch between the clusters given in *.txt files and execute the command given in while loop

INFILE=/home/u1283442/aws-clusters.txt #<-Change this path according to the file location which contains the list of clusters

while read -r LINE
do
    kubectl config use-context "$LINE" > /home/u1283442/testing/dump.txt #<- create a dump file so that it will store the output "switched to context <cluster-name>" into dumpfile as it is not necessary
      echo "$LINE" #<- Now this will just gives us the cluster name instead of unnecessary output like kcuc command
      kubectl get nodes -L node.kubernetes.io/instance-type --no-headers | sort -k2 #This is the command we want to execute in every clsuter, here we are getting nodes in cluster and the type they are
      kubectl get pods -A -l type=app #you can have multiple commands that can be executed in a cluster and change them according to your use
done < "$INFILE"

#Get the list of cluster context from kubecongig file
clusters=$(kubectl config get-contexts -o name)
# command="kubectl get daemonset -n datadog -o wide"
# Prompt the user for a kubernetes command
echo "Enter the kubernetes (kubectl) command you want to run on all clsuters:"
read -r command

# confirm the entered command
echo "You entered: $command"
echo "Running the command..."
#Iterate through each cluster context
for cluster in $clusters; do
  echo "Switching to clsuter context: "$cluster""

  #Switch to cluster context
  kubectl config use-context "$cluster"

  #Run the command you need to execute on all the clsuters
  echo "Running $command on cluster: $cluster"
  $command

  echo "------------------------------------------------------"
done

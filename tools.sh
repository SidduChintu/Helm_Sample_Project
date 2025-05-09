#!/bin/bash

while true
do
  border()
  {
    title="| $1 |"
    edge=$(echo "$title" | sed 's/./-/g')
    echo "$edge"
    echo -e "\033[31m$title\033[0m"
    echo "$edge"
  }

  border "Select the option"
  echo -e "Enter 1 to get Dremio updates:"
  echo -e "Enter 2 to get Rancher updates:"
  echo -e "Enter 3 to get Vault updates:"
  echo -e "Enter 4 to get Vault DR updates:"
  echo -e "Enter 5 to get Dallas Artifactory updates:"
  echo -e "Enter 6 to get Bedford Artifactory updates:"
  echo -e "Enter 7 to get Tigera updates:"
  echo -e "Enter 8 to get Calico updates:"
  echo -e "Enter 9 to get oss2 api updates:"
  echo -e "Enter q to quit the menu:"
  echo -e "\n"

  echo -e "Enter your selection:\c"

  read answer
  case "$answer" in
    1) kubectl config use-context mgti-dremio-prod-dallas
      kubectl get pods -n mgti-dremio-prod-dallas
      echo -e "\n";;
    2) kubectl config use-context mgti-rancher-dallas
    kubectl get pods -n cattle-system
    echo -e "\n"
    echo -e "Resource utilized by pods"
    kubectl top pods -n cattle-system
    echo -e "\n";;
    3) kubectl config use-context mgti-secops-dallas
    kubectl get pods -n vault
    echo -e "\n"
    echo -e "Resource utilized by pods"
    kubectl top pods -n vault
    echo "The leader is:"
    kubectl exec -it vault-1 -n vault sh --vaiult status | grep https://vault | cut -c '34-40'
    echo -e "\n"
    echo "producing vault audit logs occupency"
    for a in 0 1 2 3 4 5
    do
      if [ $a == 5 ]
      then
        break
      fi
      echo -e "\n"
      echo "vault-$a"
      kuebctl exec -it vault-$a -n vault sh -- df -h | grep audit | awk '{print $5}' | tr -d %
    done
    echo -e "\n";;
    4) kubectl config use-context mgti-secops-dallas-2
    kubectl get pods -n vault
    echo -e "\n"
    echo -e "Resource utilized by pods"
    kubectl top pods -n vault
    echo "The leader is:"
    kubectl exec -it vault-1 -n vault sh --vaiult status | grep https://vault | cut -c '34-40'
    echo -e "\n"
    echo "producing vault audit logs occupency"
    for a in 0 1 2 3 4 5
    do
      if [ $a == 5 ]
      then
        break
      fi
      echo -e "\n"
      echo "vault-$a"
      kuebctl exec -it vault-$a -n vault sh -- df -h | grep audit | awk '{print $5}' | tr -d %
    done
    echo -e "\n";;
    5) kubectl config use-context mgti-secops-dallas
    kubectl get pods -n artifactory-ha
    echo -e "\n"
    echo -e "Resource utilized by pods"
    kubectl top pods -n artifactory-ha
    echo -e "\n";;
    6) kubectl config use-context mgti-secops-bedford
    kubectl get pods -n artifactory-ha-b
    echo -e "\n"
    echo -e "Resource utilized by pods"
    kubectl top pods -n artifactory-ha-b
    echo -e "\n";;
    7) echo -e "Welcome to Tigera updates:"
       echo -e "\n"
    while true
    do
      echo -e "Enter 1 to get Tigera updates of all clusters:"
      echo -e "Enter 2 to get Tigera updates for specific cluster:"
      echo -e "Enter 0 to quit:"
      echo -e "Enter your selection:\c"
      read answer
      case "$answer" increment
        1) INFILE=/home/u1283442/clusters.txt
           while read -r LINE
           do
               kubectl config use-context "$LINE" > /home/u1283442/testing/dump.txt
                 echo "$LINE"
                 kubectl get tigerastatus
           done < "$INFILE"
           echo -e "\n";;
        2) echo -e "Enter cluster name:\c"
        read clsuter_name
        kubectl config use-context $clsuter_name
        kubectl get tigerastatus
        echo -e "\n";;
        0) exit ;;
      esac
    done
    echo -e "\n";;
    8) echo -e "Welcome to Calico updates:"
       echo -e "\n"
    while true
    do
      echo -e "Enter 1 to get Calico updates of all clusters:"
      echo -e "Enter 2 to get Calico updates for specific cluster:"
      echo -e "Enter 0 to quit:"
      echo -e "Enter your selection:\c"
      read answer
      case "$answer" increment
        1) INFILE=/home/u1283442/clusters.txt
           while read -r LINE
           do
               kubectl config use-context "$LINE" > /home/u1283442/testing/dump.txt
                 echo "$LINE"
                 kubectl get pods -n calico-system
           done < "$INFILE"
           echo -e "\n";;
        2) echo -e "Enter cluster name:\c"
        read clsuter_name
        kubectl config use-context $clsuter_name
        kubectl get pods -n calico-system
        echo -e "\n";;
        0) exit ;;
      esac
    done
    echo -e "\n";;
    9) kubectl config use-context mgti-secops-dallas
    kubectl get pods -n mgti-dvpseng-prd-oss2-platform-api
    kubectl get pods --namespace=mgti-dvpseng-prd-oos2-platform-api --no-headers -o custmo-columns=":metadara.name,:status.phase,:status.containerStatuses[*].ready" | while read pod status readiness
    do
        # Readiness check: If the pod has containers that are not ready (0/1 or similar)
        # Readiness is expected to be 1/1 if container is ready
        if [[ "$readiness" != "true" ]]; then
            echo "Pod $pod is not ready (readiness stauts: $readiness). Checking error logs..."
            #Call the python script to check logs for errors from this pod
            python errorlogs.py -p "$pod" -n mgti-dvpseng-prd-oss2-platform-api
        fi
    done
    echo -e "\n"
    echo -e "Resource utilized by pods"
    kubctl top pods -n mgti-dvpseng-prd-oss2-platform-api
    echo -e "\n";;
    q) exit ;;
  esac
done

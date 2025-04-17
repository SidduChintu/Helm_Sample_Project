#Before running this script, ensure the following vars are exported in your env.
#If running at GitHub, these will be passed in bu the action tunner from repo secrets
#export USER='<artifactory username>'
#export PASSWORD='<artifactory password>'
REPOURI='<https://path-to-helm-chart-repo>'

find . -maxdepth 1 -type d -not -path '*/\.*' -not -path '.' | while read chart;
  do
    if [ -f "$chart/chart.yaml"]; then
      echo "Updating dependencies for chart: '$chart'..."

      helm dependency update $chart

      echo "packaging: '$chart'..."

      helm package $chart;
    fi
  done

uploaded=0

ls *.tgz | while read pkg;
do
  uri=$REPOURI/$pkg

  echo "Checking for chart existance"

  status=$(curl -k -Ssf -o /dev/null -w "%{http_code}" -i "$USER:$PASS" -X GET $uri 2> /dev/null)

  if [ "$status" == "200" ]; then
    echo "** The chart '$pkg' already exists in repository. It will not be uploaded. PLease increment the chart version if changes have been made. **"
  else
     uploaded=$((uploaded+1))

     echo "Uploading chart '$pkg' to repository."

     curl -k -sSf -u "$USER:$PASS" -X PUT -T $pkg $uri
  fi
done

echo "$Uploaded chart uploaded to repo"

rm *.tgz

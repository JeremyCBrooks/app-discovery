#!/bin/bash

#expect a single argument which is a file containing DNS zones on separate lines
if [ -z "$1" ]
  then
    echo "$0 <zones_file>"
	exit
fi

zones_file=$1

#enumerate zones
for zone in $(cat $zones_file); do
  #find name servers for zone
  for nameserver in $(dig $zone NS +short); do
    echo "Attempting axfr on $zone $nameserver" 

    dig AXFR +nocmd +noall +answer +nocomments $zone @$nameserver | \
    sed 's/\s\s*/ /g' | \
    grep "IN\s\+\(A\|CNAME\)" | \
    cut -d ' ' -f1 | \
    sed 's/.$//' >> axfr.out
    
    echo "done."
  done
done

#do OSINT discovery
echo "Running amass..."
amass enum -df $zones_file -o amass.out

echo "Running findomain..."
./findomain-linux -f $zones_file -r -u findomain.out

#combine all discovered hosts into one file
cat amass.out findomain.out axfr.out | sort -u > discovered_hosts.out

#test hosts for web servers
echo "Running httprobe..."
cat ./discovered_hosts.out | ~/go/bin/httprobe -p large -c 50 > discovered_webhosts.out

#search for OpenAPI/Swagger docs
echo "Searching for OpenAPI docs..."
openapi_endpoints=("/" "/openapi" "/swagger" "swagger-ui" "/api" "/metadata")
for host in $(cat ./discovered_webhosts.out); do
  for endpoint in "${openapi_endpoints[@]}"; do
    url=$host$endpoint
    response=$(curl -s -k -L -w "HTTPSTATUS:%{http_code}\nCONTENTTYPE:%{content_type}" $url)
    status_code=$(echo $response | grep -o "HTTPSTATUS:.*" | cut -d' ' -f1 | cut -d':' -f2)
    content_type=$(echo $response | grep -o "HTTPSTATUS:.*" | cut -d' ' -f2 | cut -d':' -f2)
    if [ $status_code == "200" ] && [[ $content_type == *"json"* ]]; then
      body=$(echo $response|sed 's/HTTPSTATUS:.*$//')
      echo $url
    fi
  done
done

#generate screenshots
echo "Generating screenshots..."
mkdir ./screenshots 2> /dev/null
for host in $(cat ./discovered_webhosts.out); do
  screenshot_filename=$(echo $host|sed 's/[:\\/]/_/g')
  chromium-browser --headless --no-sandbox --disable-gpu --window-size=1024,768 --ignore-certificate-errors --run-all-compositor-stages-before-draw --virtual-time-budget=20000 --screenshot="./screenshots/$screenshot_filename.png" $host
done

#run eyeballer
pushd .
cd ./eyeballer
python3 ./eyeballer.py --weights ./bishop-fox-pretrained-v1.h5 predict ../screenshots/
mv results.csv ..
popd

#run testssl.sh
cat ./discovered_webhosts.out |grep https: > ./discovered_webhosts_https.out
rm ssl.out
./testssl.sh/testssl.sh -U -iL ./discovered_webhosts_https.out --jsonfile ssl.out

#collect risk factors


#report to Slack

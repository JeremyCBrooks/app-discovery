#!/bin/bash

apt-get update
apt-get install git jq golang-go chromium-browser

#https://github.com/OWASP/Amass
snap install amass 

#https://github.com/Edu4rdSHL/findomain
wget https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux
chmod +x findomain-linux

#https://github.com/tomnomnom/httprobe
go get -u github.com/tomnomnom/httprobe

#https://github.com/drwetter/testssl.sh
git clone --depth 1 https://github.com/drwetter/testssl.sh.git

#https://github.com/BishopFox/eyeballer
git clone https://github.com/BishopFox/eyeballer.git
pushd .
cd eyeballer
sudo pip3 install -r requirements.txt
wget -O eyeballer-training-data.zip https://www.dropbox.com/sh/7aouywaid7xptpq/AAD_-I4hAHrDeiosDAQksnBma?dl=1
unzip eyeballer-training-data.zip
popd

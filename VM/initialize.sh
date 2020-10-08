#
# Created by Martin Kacer
# Copyright 2020 H21 lab, All right reserved, https://www.h21lab.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#!/bin/bash

sudo apt update -yq
#DEBIAN_FRONTEND=noninteractive sudo apt dist-upgrade -yq
sudo apt install default-jre apt-transport-https gnupg2 -yq
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update -yq
sudo apt install logstash elasticsearch kibana -yq


systemctl enable elasticsearch.service
systemctl enable logstash.service
systemctl enable kibana.service
systemctl start elasticsearch.service
echo $'server.port: 5601\nserver.host: "0.0.0.0"\n' >> /etc/kibana/kibana.yml
systemctl start kibana.service

sudo apt install curl -yq

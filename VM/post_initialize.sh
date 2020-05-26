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

mv /home/vagrant/tsharkVM/tshark_logstash.conf /etc/logstash/conf.d/
chown logstash:logstash /etc/logstash/conf.d/tshark_logstash.conf
systemctl start logstash.service

cd /home/vagrant/tsharkVM/Kibana
curl -X PUT "localhost:9200/_template/packets?include_type_name" -H 'Content-Type: application/json' -d@template_tshark_mapping_deduplicated.json

echo "Wait for Kibana to start ... (waiting 60 seconds)"
sleep 60
curl -X POST "localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@export.ndjson
cd /home/vagrant
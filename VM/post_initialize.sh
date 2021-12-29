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
mv /home/vagrant/tsharkVM/tshark_logstash_fileinput.conf /etc/logstash/conf.d/
chown logstash:logstash /etc/logstash/conf.d/tshark_logstash_fileinput.conf
mkdir /home/vagrant/input
chmod go+w /home/vagrant/input
chown logstash:logstash /home/vagrant/input

systemctl start logstash.service

echo "Waiting for Elasticsearch to start ... (waiting 3 minutes)"
end=$((SECONDS+180))
while [ $SECONDS -lt $end ]; do
    if [ $(systemctl is-active elasticsearch.service) == "active" ]; then
        sleep 10
        echo "Importing Elasticsearch templates"
        cd /home/vagrant/tsharkVM/Kibana
        curl -X PUT "localhost:9200/_index_template/packets_template" -H 'Content-Type: application/json' -d@template_tshark_mapping_deduplicated.json
        break
    fi
    sleep 1
done
if [ $(systemctl is-active elasticsearch.service) != "active" ]; then
    echo "Error: Elasticsearch is not running. Failed to import Elasticsearch templates."
    echo "=== Start Elasticsearch and import it manually by executing the following ==="
    echo "cd ./VM"
    echo "vagrant ssh"
    echo "sudo systemctl start elasticsearch.service"
    echo "cd tsharkVM/Kibana/"
    echo "curl -X PUT \"localhost:9200/_index_template/packets_template\" -H 'Content-Type: application/json' -d@template_tshark_mapping_deduplicated.json"
fi

echo "Waiting for Kibana to start ... (waiting 3 minutes)"
end=$((SECONDS+180))
while [ $SECONDS -lt $end ]; do
    if [ $(systemctl is-active kibana.service) == "active" ]; then
        sleep 15
        echo "Importing Kibana objects"
        curl -X POST "localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@export.ndjson
        cd /home/vagrant
        break
    fi
    sleep 1
done
if [ $(systemctl is-active kibana.service) != "active" ]; then
    echo "Error: Kibana is not running. Failed to import Kibana objects."
    echo "=== Start Kibana and import it manually by executing the following ==="
    echo "cd ./VM"
    echo "vagrant ssh"
    echo "sudo systemctl start kibana.service"
    echo "cd tsharkVM/Kibana/"
    echo "curl -X POST \"localhost:5601/api/saved_objects/_import?overwrite=true\" -H \"kbn-xsrf: true\" --form file=@export.ndjson"
fi

# Resize disk space
resize2fs -p -F /dev/sda1


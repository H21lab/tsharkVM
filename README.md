# tshark VM appliance

This project builds virtual machine which can be used for analytics of tshark -T ek (ndjson) output.
The virtual appliance is built using vagrant, which builds Debian 10 with pre-installed and pre-configured ELK stack. 

After the VM is up, the process is simple:
* decoded pcaps (`tshark -T ek output` / ndjson) are sent over `TCP/17570` to the VM
* ELK stack in VM will process and index the data
* Kibana is running in VM and can be accessed on `http://127.0.0.1:15601/app/kibana#/dashboards`

### Clone source code
```bash
git clone https://github.com/H21lab/tsharkVM.git
```

### Build tshark VM
```bash
sudo apt update
sudo apt install tshark virtualbox
curl -O https://releases.hashicorp.com/vagrant/2.2.6/vagrant_2.2.6_x86_64.deb
sudo apt install ./vagrant_2.2.6_x86_64.deb
bash ./build.sh
```

### Upload pcaps to VM
```bash
# copy your pcaps into ./Trace
# run following script 
bash upload_pcaps.sh 

# or use tshark directly towards 127.0.0.1 17570/tcp
tshark -r trace.pcapng -x -T ek > /dev/tcp/localhost/17570
```

### Open Kibana with browser
```bash
firefox http://127.0.0.1:15601/app/kibana#/dashboards
```

![](res/tshark_vm_dashboard.png?raw=true "Kibana Dashboard")
![](res/tshark_vm_discover.png?raw=true "Kibana Discover")

### SSH to VM
```bash
cd ./VM
vagrant ssh
```

### Delete VM
```bash
cd ./VM
vagrant destroy default
```

### Start VM
```bash
cd ./VM
vagrant up
```

### Stop VM
```bash
cd ./VM
vagrant halt
```

## Limitations
Program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.

## License
The default license of source codes provided inside this project is the Apache License v2.0. 
Additionally refer to individual licenses and terms of used of installed software (see licenses for Wireshark, Elastic and other). 

## Attribution
Created by Martin Kacer

Copyright 2020 H21 lab, All right reserved, https://www.h21lab.com

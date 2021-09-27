# Simple NIDS in Go

Application is very simple NIDS (Network Intrusion Detection System) to log and record suspicious connections.

Recorded are all later communication from suspicious source.

## Logic:
1. Passively sniff interface on the server
2. Detect reliable security events (e.g. port scan) and mark the source as suspicious
3. Record that suspicious originating source for certain time
4. Security log and recorded pcap is produced
5. HIDS process will close after certain time, and should be respawned  (e.g. from inittab or in other ways)

=> The logs + pcaps could be uploaded and indexed in ELK (e.g. tsharkVM)	

## Security Detection:
* Currently only TCP/UDP/SCTP portscan event is used to mark the source as suspicious for recording

## How to use:
1. Update the Configuration section in this file for the given host
2. Add the daemon for example into inittab and auto respawn it
3. Upload the logs and pcaps to ELK for later processing


## License
Source code is licensed under the AGPLv3 (Free Open Source GNU Affero GPL v3.0).

## Attribution
Created by Martin Kacer

Copyright 2021 H21 lab, All right reserved, https://www.h21lab.com

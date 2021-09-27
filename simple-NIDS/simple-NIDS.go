/*
 * Simple NIDS in Go
 * Application is very simple NIDS (Network Intrusion Detection System) to log and record suspicious connections
 *
 * Logic:
 * 		1. Passively sniff interface on the server
 *		2. Detect reliable security events (e.g. port scan) and mark the source as suspicious
 *		3. Record that suspicious originating source for certain time
 *		4. Security log and recorded pcap is produced
 *		5. HIDS process will close after certain time, and should be respawned  (e.g. from inittab or in other ways)
 *		=> The logs + pcaps could be uploaded and indexed in ELK (e.g. tsharkVM)
 *
 * Detection logic:
 * 		- Currently only TCP/UDP/SCTP portscan event is used to mark the source as suspicious for recording
 *
 * How to use:
 *	1. Update the Configuration section in this file for the given host
 * 	2. Add the daemon for example into inittab and auto respawn it
 *	3. Upload the logs and pcaps to ELK for later processing
 *
 *
 * Created by Martin Kacer
 * Copyright 2021 H21 lab, All right reserved, https://www.h21lab.com
 *
 *
 * Source code is licensed under the AGPLv3 (Free Open Source GNU Affero GPL v3.0)
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	"github.com/google/gopacket/pcapgo"
	"github.com/zekroTJA/timedmap"
)

var (
	// Configuration
	iface  = "lo"                  // define capturing interface
	filter = ""                    // Optional tcpdump filter, e.g.: "tcp and port 21"
	MY_IPs = []string{"127.0.0.1"} // list of my IP addresses, used to identify inbound/outbound direction
	buffer = int32(1600)           // capture buffer size

	MAX_APP_RUNNING_TIME     = 24 * 60 * 60 * time.Second // app will terminate and should be respawned externally after this period
	REC_TIME_WINDOW          = 1 * 60 * 60 * time.Second  // record suspisious IP address for N of seconds
	MAX_UNIQUE_PORTS_SCANNED = 3                          // scan detection threshold - number of distinct dest ports before key expires
	IP_HM_exp                = 60 * 60 * time.Second      // expirtaion in seconds of IP hashmap
	P_HM_exp                 = 60 * time.Second           // expirtaion in seconds of port hashmap

	// Variables
	IP_reclist_tm = timedmap.New(1 * time.Second) // list of recorded IP addresses
	running       = true
	startTime     = time.Now()
)

func main() {
	fmt.Println("== Simple NIDS in Go ==")

	// Handle CTRL + C signal
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	go func() {
		<-c
		running = false
		time.Sleep(1 * time.Second)
		os.Exit(1)
	}()

	// Logger
	file, err := os.OpenFile("log-"+startTime.Format(time.RFC3339)+".log", os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {

		log.Fatalf("error opening file: %v", err)

	}
	defer file.Close()
	log.SetOutput(file)

	// Initialize interface listener
	if !deviceExists(iface) {
		log.Fatal("Unable to open device ", iface)
	}

	handler, err := pcap.OpenLive(iface, buffer, false, pcap.BlockForever)

	if err != nil {
		log.Fatal(err)
	}
	defer handler.Close()

	if err := handler.SetBPFFilter(filter); err != nil {
		log.Fatal(err)
	}

	// Initialize expiring Hash Map
	tm := timedmap.New(1 * time.Second)

	// Initialize output pcap
	outputPcap := "trace-" + startTime.Format(time.RFC3339) + ".pcap"
	var pcapWriter *pcapgo.Writer
	if outputPcap != "" {
		outPcapFile, err := os.Create(outputPcap)
		if err != nil {
			log.Fatalln(err)
		}
		defer outPcapFile.Close()
		pcapWriter = pcapgo.NewWriter(outPcapFile)
		pcapWriter.WriteFileHeader(65536, layers.LinkTypeEthernet)

	}

	// Read packets from interface
	source := gopacket.NewPacketSource(handler, handler.LinkType())
	for packet := range source.Packets() {

		if !running {
			fmt.Println("Exiting program")
			break
		}

		//fmt.Println(packet.String())

		// IP layer
		if ipLayer := packet.Layer(layers.LayerTypeIPv4); ipLayer != nil {

			ip, ok := ipLayer.(*layers.IPv4)
			if ok {
				// Check inbound packets only
				if !contains(MY_IPs, ip.SrcIP.String()) {

					//fmt.Println(ip.SrcIP.String())

					if !tm.Contains(ip.SrcIP.String()) {
						tm.Set(ip.SrcIP.String(), timedmap.New(time.Duration(1)*time.Second), IP_HM_exp, func(v interface{}) {
							//log.Println("1> key-value pair of 'hey' has expired")
						})
					}

					tm_p, ok := tm.GetValue(ip.SrcIP.String()).(*timedmap.TimedMap)
					if ok {
						var dst_port string
						// TCP layer
						if tcpLayer := packet.Layer(layers.LayerTypeTCP); tcpLayer != nil {
							tcp, _ := tcpLayer.(*layers.TCP)
							dst_port = tcp.DstPort.String() + "/tcp"
						}
						// UDP layer
						if udpLayer := packet.Layer(layers.LayerTypeUDP); udpLayer != nil {
							udp, _ := udpLayer.(*layers.UDP)
							dst_port = udp.DstPort.String() + "/udp"
						}
						// SCTP layer
						if sctpLayer := packet.Layer(layers.LayerTypeSCTP); sctpLayer != nil {
							sctp, _ := sctpLayer.(*layers.SCTP)
							dst_port = sctp.DstPort.String() + "/sctp"
						}
						//fmt.Println(dst_port)
						//ipLayer.LayerType().LayerTypes()
						tm_p.Set(dst_port, true, P_HM_exp, func(v interface{}) {
							//log.Println("2> key-value pair of 'hey' has expired")
						})
					}

					// Port scan detection
					// fmt.Println(tm_p.Size())
					if tm_p.Size() > MAX_UNIQUE_PORTS_SCANNED {
						log.Println("Port scan detected from :" + ip.SrcIP.String())
						IP_reclist_tm.Set(ip.SrcIP.String(), true, REC_TIME_WINDOW, func(v interface{}) {
							//log.Println("3> key-value pair of 'hey' has expired")
						})
					}

					// Hex string detection
					// TODO

					// Other simple detections
					// TODO
					/*app := packet.ApplicationLayer()
					if app != nil {
						payload := app.Payload()
						dst := packet.NetworkLayer().NetworkFlow().Dst()
						if bytes.Contains(payload, []byte("PASS")) {
							fmt.Print(dst, "  ->  ", string(payload))
						}
					}*/

				}

				// Check if IP is in list of recorded IP addresses
				if IP_reclist_tm.Contains(ip.SrcIP.String()) || IP_reclist_tm.Contains(ip.DstIP.String()) {
					pcapWriter.WritePacket(packet.Metadata().CaptureInfo, packet.Data())
				}
			}

		}

		// Measure time
		currentTime := time.Now()
		if MAX_APP_RUNNING_TIME != 0 && currentTime.Sub(startTime) > MAX_APP_RUNNING_TIME {
			os.Exit(1)
		}

	}
}

// Check if interface exist
func deviceExists(name string) bool {
	devices, err := pcap.FindAllDevs()

	if err != nil {
		log.Panic(err)
	}

	for _, device := range devices {
		if device.Name == name {
			return true
		}
	}
	return false
}

// Auxiliary method to check if string exist in slice
func contains(s []string, e string) bool {
	for _, a := range s {
		if a == e {
			return true
		}
	}
	return false
}

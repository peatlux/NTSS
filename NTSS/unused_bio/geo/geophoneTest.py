import socket
import argparse
import random
import time

from pythonosc import udp_client

UDP_IP = "194.95.203.101"
UDP_IP = "0.0.0.0"
UDP_PORT = 8888

print("iko 1")
sc = udp_client.SimpleUDPClient("127.0.0.1", 57120)

sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
print("iko 2")
sock.bind((UDP_IP, UDP_PORT))
print("iko iko")

while True:
    data, addr = sock.recvfrom(1024) # buffer size is 1024 bytes
    print("received message: %s" % data[0])
    sc.send_message("/test", str(data))
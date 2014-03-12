#!/usr/bin/python2
#Gets data from the ADC of the ATmega32 over serial and plots it
#Data must come as [0xBB,0x14,0x<DATA>,0x<DATA>]
import time
from serial import Serial
import sys
import pygame
from pygame.locals import *
SCREENSIZE=(1200,700)
BACKGROUNDCOLOR=(0,0,0) #BLACK
LINECOLOR=(255,255,255)

def GetReading():
    reading=[]
    while len(reading)<4:                     
        while (serialport.inWaiting() > 0) and len(reading)<4:
            rawin = ord(serialport.read(1))
            if len(reading)==0 and (not rawin==0xBB):
                continue
            if len(reading)==1 and (not rawin==0x14):
                reading=[]
                continue
            else:
                reading.append(rawin)
    reading[2]=(reading[2]<<2) | reading[3]>>6        
    return reading[2]
    
    

def DrawGraph(Data):
    screen.fill(BACKGROUNDCOLOR)
    pygame.draw.lines(screen,LINECOLOR,False,Data)
    pygame.display.flip()
    return 0
    


#Setup Serial    
if len(sys.argv)<2:
    print("You must enter serial port")
    sys.exit()
if "-v" in sys.argv:
    VERBOSE=1
else:
    VERBOSE=0
portpath=sys.argv[1]
serialport = Serial(port=portpath, baudrate=9600)

#Setup pygame
pygame.init()
screen=pygame.display.set_mode(SCREENSIZE,0,32)
clock=pygame.time.Clock()

Readings=[float(SCREENSIZE[1])-(GetReading()/1023.)*float(SCREENSIZE[1])]
counter=range(SCREENSIZE[0])
while True:
    rawread=GetReading()
    if VERBOSE:
        print(rawread)
    Readings.append(float(SCREENSIZE[1])-(rawread/1023.)*float(SCREENSIZE[1]))
    #Readings.append(50) #Debug
    if len(Readings)>SCREENSIZE[0]:
        Readings=Readings[-SCREENSIZE[0]:]
    GraphData=list(zip(counter,Readings))
    DrawGraph(GraphData)
    clock.tick()
#    print(clock.get_fps())
    

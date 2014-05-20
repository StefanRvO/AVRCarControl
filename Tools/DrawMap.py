#!/usr/bin/python2
import time
from serial import Serial
import sys
import pygame
from pygame.locals import *
import math
SCREENSIZE=(1200,700)
BACKGROUNDCOLOR=(0,0,0) #BLACK
LINECOLOR=(255,255,255)
WANTEDFPS=30
TEXTCOLORRAW=(150,30,30)
AXISCOLOR=(0,255,0)
FONTUSED = "Times New Roman"
TEXTSIZE=20
FLAGS=0
CIRCLECOLOR=(0,0,255)
LABELCOLOR=(70,180,255)
SCROLLSPEED=1.5
connected=1
STEPSIZE=6.369426751592357
Pi=math.pi

INNERRadius=250/STEPSIZE
OUTERRadius=328.5/STEPSIZE


OUTER45=0x01
OUTER90=0x02
OUTER135=0x03
OUTER180=0x04

INNER45=0x05
INNER90=0x06
INNER135=0x07
INNER180=0x08
def MakeCopy(List):
    newlist=[]
    for i in range(len(List)):
        newlist.append(List[i])
    return newlist
    


def GetData():
#    time.sleep(0.01)
    global serialport
    global connected
    if not connected:
        try:
            serialport.close()
            serialport = Serial(port=portpath, baudrate=9600)
            connected=1
        except:
            connected=0
            pygame.time.wait(4)
            return(["discon",0])
    try:
        reading=[]
        dobreak=0
        while len(reading)<6 and not dobreak:                     
            while (serialport.inWaiting() > 0) and len(reading)<6 and not dobreak:
                rawin = ord(serialport.read(1))
                if len(reading)==0 and (not rawin==0xBB):
                    continue
                    reading=[]
                if len(reading)==1 and (not (rawin==0x13 or rawin==0x17)):
                    reading=[]
                    continue
                else:
                    reading.append(rawin)
                
                
                if len(reading)==6:
                    if reading[1]==0x17:
                        dobreak=1
                        break
                elif len(reading)==6:
                    if reading[1]==0x15:
                        dobreak=1
                        break
        if reading[1]==0x17:
            return ["Turn",reading[2],((reading[3]-1)<<16)+(reading[4]<<8)+(reading[5])]
        elif reading[1]==0x15:
            return ["Lap",((reading[2]-1)<<16)+(reading[3]<<8)+(reading[4])]
        else:
            return["nodata",0]
        
    except IOError:
        connected=0
        pygame.time.wait(4)
        return(["discon",0])

def DrawRoad(Startpos,Endpos,lenght):
    direction=Startpos[1]
    xstart=Startpos[0][1]
    ystart=Startpos[0][1]
    xend=Endpos[0][1]
    yend=Endpos[0][1]
    pygame.draw.line(screen,(127,127,127),Startpos[0],Endpos[0])

def DrawThisTurn(Startpos,Endpos,Radius):
    direction=Startpos[1]
   # angle=Startpos[1]-Endpos[1]
   # print angle
   # if angle>0:
   #     if math.sin(direction+angle)>=0:
   #         ArcRect=pygame.Rect(Startpos[0][0],Startpos[0][1],Radius,Radius)
   #     else:
   #         ArcRect=pygame.Rect(Startpos[0][0]+Radius,Startpos[0][0]+Radius,Radius,Radius)
   # else:
   #     if math.sin(direction+angle)>=0:
   #         ArcRect=pygame.Rect(Startpos[0][0]-Radius,Startpos[0][1]-Radius,Radius,Radius)
   #     else:
   #         ArcRect=pygame.Rect(Startpos[0][0],Startpos[0][0],Radius,Radius)
   #         pygame.draw.arc(screen,(127,127,127),ArcRect,direction+angle,direction)

def DoEvents():
    for event in pygame.event.get():
        if event.type==QUIT:
            sys.exit()
        elif event.type==KEYDOWN:
            if event.key==K_ESCAPE:
                sys.exit()

def CalcAfterTurnPos(prevpos,position,radius):
    kordangle=(prevpos[1]-position[1])/2.+prevpos[1]
    angle=prevpos[1]-position[1]
    
    kordlenght=2*math.sin(angle/2.)*radius/2.
    print kordlenght
    print kordlenght
    return[[position[0][0]+kordlenght*math.sin(kordangle),position[0][1]+kordlenght*math.cos(kordangle)],position[1]]
    
    

def DrawStart(Turn,position):
    lenght=Turn[1]
    
    prevpos=[0,position[1]]
    prevpos[0]=MakeCopy(position[0])

    position[0][0]=position[0][0]+lenght*math.sin(position[1])
    position[0][1]=position[0][1]+lenght*math.cos(position[1])
    DrawRoad(prevpos,position,lenght)
    
    if Turn[0]==INNER45:
        print "I45"
        position[1]=position[1]+Pi*1.25
        radius=INNERRadius
    if Turn[0]==INNER90:
        print "I90"
        position[1]=position[1]+Pi*1.5
        radius=INNERRadius
    if Turn[0]==INNER135:
        print "I135"
        position[1]=position[1]+Pi*1.75
        radius=INNERRadius
    if Turn[0]==INNER180:
        print "I180"
        position[1]=position[1]+2*Pi
        radius=INNERRadius
    if Turn[0]==OUTER45:
        print "U45"
        position[1]=position[1]-Pi*1.25
        radius=INNERRadius
    if Turn[0]==OUTER90:
        print "U90"
        position[1]=position[1]-Pi*1.5
        radius=INNERRadius
    if Turn[0]==OUTER135:
        print "U135"
        position[1]=position[1]-Pi*1.75
        radius=INNERRadius
    if Turn[0]==OUTER180:   
        print "U180"
        position[1]=position[1]-2*Pi
        radius=INNERRadius

    DrawThisTurn(prevpos,position,radius)
    #position=CalcAfterTurnPos(prevpos,position,radius)
    print position
    return position
        

def DrawTurn(Turn,TurnLast,position):
    lenght=TurnLast[1]-Turn[1]
    prevpos=[0,position[1]]
    prevpos[0]=MakeCopy(position[0])

    position[0][0]=position[0][0]+lenght*math.sin(position[1])
    position[0][1]=position[0][1]+lenght*math.cos(position[1])
    DrawRoad(prevpos,position,lenght)
    if Turn[0]==INNER45:
        print "I45"
        position[1]=position[1]+Pi*0.25
        radius=INNERRadius
    if Turn[0]==INNER90:
        print "I90"
        position[1]=position[1]+Pi*+.5
        radius=INNERRadius
    if Turn[0]==INNER135:
        print "I135"
        position[1]=position[1]+Pi*+0.75
        radius=INNERRadius
    if Turn[0]==INNER180:
        print "I180"
        position[1]=position[1]+Pi
        radius=INNERRadius
    if Turn[0]==OUTER45:
        print "U45"
        position[1]=position[1]-Pi*0.25
        radius=INNERRadius
    if Turn[0]==OUTER90:
        print "U90"
        position[1]=position[1]-Pi*0.5
        radius=INNERRadius
    if Turn[0]==OUTER135:
        print "U135"
        position[1]=position[1]-Pi*0.75
        radius=INNERRadius
    if Turn[0]==OUTER180:   
        print "U180"
        position[1]=position[1]-Pi
        radius=INNERRadius

    DrawThisTurn(prevpos,position,radius)
    #position=CalcAfterTurnPos(prevpos,position,radius)
    print position
    return position
    

def DrawEnd(Lap,Turn,position):
    lenght=Turn[1]-Lap
    prevpos=[0,position[1]]
    prevpos[0]=MakeCopy(position[0])
    position[0][0]=position[0][0]+lenght*math.sin(position[1])
    position[0][1]=position[0][1]+lenght*math.cos(position[1])
    DrawRoad(prevpos,position,lenght)
    print position
    return
    

    


def DrawMap(Data):
    Laps=[]
    Turns=[]
    position=[[SCREENSIZE[0]/2.,SCREENSIZE[1]/2.],0] #[<x,y>,direction]
    for entry in Data:
        if entry[0]=="Lap":
            Laps.append(entry[1])
        elif entry[0]=="Turn":
            Turns.append(entry[1:])
    for i in range(len(Turns)):
        if i%2==0:
            if i==0:
                position=DrawStart(Turns[i],position)
            else:
                position=DrawTurn(Turns[i],Turns[i-1],position)
    if len(Laps)>=2:
        DrawEnd(Laps[1],Turns[-1],position)


    pygame.display.flip()
        

#Setup Serial    
if len(sys.argv)<2:
    print("You must enter serial port")
    sys.exit()

#get arguments
if "-v" in sys.argv:
    VERBOSE=1
else:
    VERBOSE=0
    
portpath=sys.argv[1]
serialport = Serial(port=portpath, baudrate=9600)
connected=1
if "-fscreen" in sys.argv:
    SCREENSIZE=(1366,768)
    FLAGS=pygame.FULLSCREEN
    
    
pygame.init()
screen=pygame.display.set_mode(SCREENSIZE,FLAGS,32)
clock=pygame.time.Clock()
serialport.write([0x55])
serialport.write([0x12])
serialport.write([0x00])

RAWFont=pygame.font.SysFont(FONTUSED,TEXTSIZE)

RecivedData=[]

while True:
    if(serialport.inWaiting()):
        RecivedData.append(GetData())
    DoEvents()
    if len(RecivedData)>=2:
        DrawMap(RecivedData)
    
    
    print RecivedData
        

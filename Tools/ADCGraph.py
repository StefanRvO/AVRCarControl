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
WANTEDFPS=30
TEXTCOLORRAW=(150,30,30)
AXISCOLOR=(0,255,0)
FONTUSED = "Times New Roman"
TEXTSIZE=20
FLAGS=0
CIRCLECOLOR=(0,0,255)
LABELCOLOR=(70,180,255)
def MakeCopy(List):
    newlist=[]
    for i in range(len(List)):
        newlist.append(List[i])
    return newlist
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
    
def DrawGraphPaused(PausedDATA,LastReading):
    RawReadings=PausedDATA[2]
    Data=PausedDATA[0]
    TimeList=PausedDATA[1]
    CurrentTime=TimeList[-1]
    Time=TimeList[0]
    Timespan=Time-CurrentTime
    screen.fill(BACKGROUNDCOLOR)
    MouseX=pygame.mouse.get_pos()[0]
    #print(type(Data[MouseX][1]))
    #Draw x-asix
    pygame.draw.line(screen,AXISCOLOR,(0,SCREENSIZE[1]/2),(SCREENSIZE[0],SCREENSIZE[1]/2),2)
    #Draw y-axis
    pygame.draw.line(screen,AXISCOLOR,(SCREENSIZE[0]/2,0),(SCREENSIZE[0]/2,SCREENSIZE[1]),2)
    #Draw time on x-axis
    text=RAWFont.render(str(Timespan)+" ms",True,AXISCOLOR)
    
    #Draw time on x-axis
    labelsx=3
    for i in range(labelsx):
        for j in [1,-1]:
            Current=int(SCREENSIZE[0]/2+SCREENSIZE[0]/(2*(labelsx-1))*0.90*i*j)
            #print(Current)
            #print(Current)
            #Draw "slip"
            pygame.draw.line(screen,AXISCOLOR,(Current,SCREENSIZE[1]/2-5),(Current,SCREENSIZE[1]/2+5),3)
            #Draw time
            if not(len(TimeList)-1<Current):
                text=RAWFont.render(str(TimeList[Current]-CurrentTime)+" ms",True,LABELCOLOR)
                screen.blit(text,(Current-text.get_width()/2,SCREENSIZE[1]/2+text.get_height()*0.5))
            if i==0:
                break
    
    #Draw labels on y
    pygame.draw.line(screen,AXISCOLOR,(SCREENSIZE[0]/2+5,SCREENSIZE[1]/4*3),(SCREENSIZE[0]/2-5,SCREENSIZE[1]/4*3),3)
    pygame.draw.line(screen,AXISCOLOR,(SCREENSIZE[0]/2+5,SCREENSIZE[1]/4*1),(SCREENSIZE[0]/2-5,SCREENSIZE[1]/4*1),3)
    text=RAWFont.render(str(1023/4*1),True,LABELCOLOR)
    screen.blit(text,(SCREENSIZE[0]/2+text.get_width()/2,SCREENSIZE[1]/4*3-text.get_height()/2))
    text=RAWFont.render(str(1023/4*3),True,LABELCOLOR)
    screen.blit(text,(SCREENSIZE[0]/2+text.get_width()/2,SCREENSIZE[1]/4*1-text.get_height()/2))
    #Draw data
    pygame.draw.lines(screen,LINECOLOR,False,Data,2)
    #Draw circle in selected pos
    if MouseX<len(Data):
        pygame.draw.circle(screen,CIRCLECOLOR,(MouseX,int(Data[MouseX][1])),6)
        text=RAWFont.render("Selected Time="+str(TimeList[MouseX]-CurrentTime)+" ms",True,CIRCLECOLOR)
        screen.blit(text,(5,SCREENSIZE[1]-text.get_height()))
        text=RAWFont.render("Selected Value="+str(RawReadings[MouseX]),True,CIRCLECOLOR)
        screen.blit(text,(5,SCREENSIZE[1]-text.get_height()*2))
    
    #Write out current reading
    text=RAWFont.render("Input="+str(LastReading),True,TEXTCOLORRAW)
    screen.blit(text,(SCREENSIZE[0]-text.get_width()-5,text.get_height()))
    #Write out Current time #For logging etc.
    text=RAWFont.render("Total Time ="+str(CurrentTime)+" ms",True,TEXTCOLORRAW)
    screen.blit(text,(5,text.get_height()))
    #View on screen
    pygame.display.flip()
    return 0    

def DrawGraph(Data,TimeList,LastReading):
    CurrentTime=TimeList[-1]
    Time=TimeList[0]
    Timespan=Time-CurrentTime
    screen.fill(BACKGROUNDCOLOR)
    #Draw x-asix
    pygame.draw.line(screen,AXISCOLOR,(0,SCREENSIZE[1]/2),(SCREENSIZE[0],SCREENSIZE[1]/2),2)
    #Draw y-axis
    pygame.draw.line(screen,AXISCOLOR,(SCREENSIZE[0]/2,0),(SCREENSIZE[0]/2,SCREENSIZE[1]),2)
    #Draw time on x-axis
    labelsx=3
    for i in range(labelsx):
        for j in [1,-1]:
            Current=int(SCREENSIZE[0]/2+SCREENSIZE[0]/(2*(labelsx-1))*0.90*i*j)
            #print(Current)
            #print(Current)
            #Draw "slip"
            pygame.draw.line(screen,AXISCOLOR,(Current,SCREENSIZE[1]/2-5),(Current,SCREENSIZE[1]/2+5),3)
            #Draw time
            if not(len(TimeList)-1<Current):
                text=RAWFont.render(str(TimeList[Current]-CurrentTime)+" ms",True,LABELCOLOR)
                screen.blit(text,(Current-text.get_width()/2,SCREENSIZE[1]/2+text.get_height()*0.5))
            if i==0:
                break
    
    #Draw labels on y
    pygame.draw.line(screen,AXISCOLOR,(SCREENSIZE[0]/2+5,SCREENSIZE[1]/4*3),(SCREENSIZE[0]/2-5,SCREENSIZE[1]/4*3),3)
    pygame.draw.line(screen,AXISCOLOR,(SCREENSIZE[0]/2+5,SCREENSIZE[1]/4*1),(SCREENSIZE[0]/2-5,SCREENSIZE[1]/4*1),3)
    text=RAWFont.render(str(1023/4*1),True,LABELCOLOR)
    screen.blit(text,(SCREENSIZE[0]/2+text.get_width()/2,SCREENSIZE[1]/4*3-text.get_height()/2))
    text=RAWFont.render(str(1023/4*3),True,LABELCOLOR)
    screen.blit(text,(SCREENSIZE[0]/2+text.get_width()/2,SCREENSIZE[1]/4*1-text.get_height()/2))
    #Draw data
    pygame.draw.lines(screen,LINECOLOR,False,Data,2)
    #Write out current reading
    text=RAWFont.render("Input="+str(LastReading),True,TEXTCOLORRAW)
    screen.blit(text,(SCREENSIZE[0]-text.get_width()-5,text.get_height()))
    #Write out Current time #For logging etc.
    text=RAWFont.render("Total Time ="+str(CurrentTime)+" ms",True,TEXTCOLORRAW)
    screen.blit(text,(5,text.get_height()))
    #View on screen
    pygame.display.flip()
    return 0
    
def DoEvents():
    global mode
    for event in pygame.event.get():
        if event.type==QUIT:
            sys.exit()
        elif event.type==KEYDOWN:
            if event.key==K_ESCAPE:
                sys.exit()
            elif event.key==K_SPACE:
                mode=2
                global Readings
                global TimeList
                global RawReadings
                PReadings=[x for x in Readings]
                PGraphData=list(zip(counter,PReadings))
                PTimeList=[x for x in TimeList]
                PRawReadings=[x for x in RawReadings]
                return [PGraphData,PTimeList,PRawReadings]
                
def DoEventsPaused():
    global mode
    for event in pygame.event.get():
        if event.type==QUIT:
            sys.exit()
        elif event.type==KEYDOWN:
            if event.key==K_ESCAPE:
                sys.exit()
            elif event.key==K_SPACE:
                    
                    mode=1
                    

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
if "-fscreen" in sys.argv:
    SCREENSIZE=(1366,768)
    FLAGS=pygame.FULLSCREEN

#Setup pygame
pygame.init()
screen=pygame.display.set_mode(SCREENSIZE,FLAGS,32)
clock=pygame.time.Clock()
fpscounter=1
fpsadjust=5
Readings=[float(SCREENSIZE[1])-(GetReading()/1023.)*float(SCREENSIZE[1])]
RawReadings=[GetReading()]
counter=range(SCREENSIZE[0])
#Setup fonts
RAWFont=pygame.font.SysFont(FONTUSED,TEXTSIZE)
TimeList=[pygame.time.get_ticks()]
mode=1
PausedDATA=[]
while True:
    fpscounter+=1
    rawread=GetReading()
    TimeList.append(pygame.time.get_ticks())
    if VERBOSE:
        print(str(rawread)+"\t"+str(TimeList[-1]))
    Readings.append(float(SCREENSIZE[1])-(rawread/1023.)*float(SCREENSIZE[1]))
    RawReadings.append(rawread)
    #Readings.append(50) #Debug
    if len(Readings)>SCREENSIZE[0]:
        Readings=Readings[-SCREENSIZE[0]:]
        TimeList=TimeList[-SCREENSIZE[0]:]
        RawReadings=RawReadings[-SCREENSIZE[0]:]
    GraphData=list(zip(counter,Readings))
    if fpscounter%fpsadjust==0:
        if(mode==1):
            DrawGraph(GraphData,TimeList,rawread)
            PausedDATA=DoEvents()
        elif (mode==2):
            DrawGraphPaused(PausedDATA,rawread)
            DoEventsPaused()
        
    


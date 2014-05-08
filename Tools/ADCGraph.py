#!/usr/bin/python2
#Gets data from the ADC of the ATmega32 over serial and plots it
#Data must come as [0xBB,0x14,0x<DATA>,0x<DATA>]
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
def MakeCopy(List):
    newlist=[]
    for i in range(len(List)):
        newlist.append(List[i])
    return newlist
    
def GetReading(LastReadings):
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
            return([511,511])
    try:
        reading=[]
        while len(reading)<3:                     
            while (serialport.inWaiting() > 0) and len(reading)<4:
                rawin = ord(serialport.read(1))
                if len(reading)==0 and (not rawin==0xBB):
                    continue
                if len(reading)==1 and (not rawin==0x14):
                    reading=[]
                    continue
                else:
                    reading.append(rawin)
        reading[2]=reading[2] << 2
        
        if len(LastReadings)<moving-1 or moving==1:        
            return [reading[2],reading[2]]
        else:
            #Make average over last <moving> readings and return the average
            LastReadings.append(reading[2])
            return [int(float(sum(LastReadings))/len(LastReadings)),reading[2]]
    except IOError:
        connected=0
        pygame.time.wait(4)
        return([511,511])
        
    
def DrawGraphPaused(Data,TimeList,LastReading,StartTime,RawReadings):
    NData=[[x,x] for x in range(len(Data))]
    for i in range(len(Data)):
        NData[i]=[Data[i][0]-Data[0][0],Data[i][1]]
    Data=NData
    CurrentTime=TimeList[-1]
    Time=TimeList[0]
    Timespan=Time-CurrentTime
    screen.fill(BACKGROUNDCOLOR)
    MouseX=pygame.mouse.get_pos()[0]
    if MouseX>len(Data):
        MouseX=len(Data)-1
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
        text=RAWFont.render("Selected Value="+str(RawReadings[MouseX+moving*2]),True,CIRCLECOLOR)
        screen.blit(text,(5,SCREENSIZE[1]-text.get_height()*2))
    
    #Write out current reading
    text=RAWFont.render("Input= Mov: "+str(LastReading[0])+" Real: "+str(LastReading[1]),True,TEXTCOLORRAW)
    screen.blit(text,(SCREENSIZE[0]-text.get_width()-5,text.get_height()))
    #Write out Current time #For logging etc.
    text=RAWFont.render("Total Time ="+str(pygame.time.get_ticks()-StartTime)+" ms",True,TEXTCOLORRAW)
    screen.blit(text,(5,text.get_height()))
    #Write out time for the viewed measurement (last time)
    text=RAWFont.render("Current Time ="+str(CurrentTime-StartTime)+" ms",True,(122,122,122))
    screen.blit(text,(5,text.get_height()*2))
    #View on screen
    pygame.display.flip()
    return 0    

def DrawGraph(Data,TimeList,LastReading,StartTime):
    NData=[x for x in range(len(Data))*2]
    for i in range(len(Data)):
        NData[i]=[Data[i][0]-Data[0][0],Data[i][1]]
    Data=NData
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
    text=RAWFont.render("Input= Mov: "+str(LastReading[0])+" Real: "+str(LastReading[1]),True,TEXTCOLORRAW)
    screen.blit(text,(SCREENSIZE[0]-text.get_width()-5,text.get_height()))
    #Write out Current time #For logging etc.
    text=RAWFont.render("Total Time ="+str(CurrentTime-StartTime)+" ms",True,TEXTCOLORRAW)
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
                global counter

                return(counter)
            elif event.key==K_b:
                serialport.write([0x55])
                serialport.write([0x14])
                serialport.write([0x00])
            elif event.key==K_u:
                serialport.write([0x55])
                serialport.write([0x15])
                serialport.write([0x00])
            elif event.key==K_h:
                serialport.write([0x55])
                serialport.write([0x10])
                serialport.write([0x32])
            elif event.key==K_f:
                serialport.write([0x55])
                serialport.write([0x10])
                serialport.write([0x64])
                
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

#get arguments
if "-v" in sys.argv:
    VERBOSE=1
else:
    VERBOSE=0
moving=1
if "-m" in sys.argv:
    try:
        moving=int(sys.argv[sys.argv.index("-m")+1])
        if moving<=0:
            print("Wrong arguments!!")
            sys.exit()  
    except:
        print("Wrong arguments!!")
        sys.exit()
        


portpath=sys.argv[1]
serialport = Serial(port=portpath, baudrate=9600)
connected=1
if "-fscreen" in sys.argv:
    SCREENSIZE=(1366,768)
    FLAGS=pygame.FULLSCREEN
MovingReadings=[]
RawReadings=[]
#prepare moving average
for i in range(moving):
    rawread=GetReading([])
    RawReadings.append(rawread[1])
    MovingReadings.append(rawread[0])
    

#Prepare to draw data
Readings=[float(SCREENSIZE[1])-(MovingReadings[-1]/1023.)*float(SCREENSIZE[1])]
counter=0
counterlist=[counter]

#Setup pygame
pygame.init()
screen=pygame.display.set_mode(SCREENSIZE,FLAGS,32)
clock=pygame.time.Clock()
fpscounter=1
fpsadjust=5
#Setup fonts
RAWFont=pygame.font.SysFont(FONTUSED,TEXTSIZE)

TimeList=[pygame.time.get_ticks()]
mode=1
PausedData=0
GraphData=[]
pagewait=0
while True:
    counter+=1
    fpscounter+=1
    RawReadings=RawReadings[-(moving-1):]
    rawread=GetReading(RawReadings)
    TimeList.append(pygame.time.get_ticks())
    if VERBOSE:
        print(str(rawread[0])+"\t"+str(rawread[1])+"\t"+str(TimeList[-1]-TimeList[0]))
    Readings.append(float(SCREENSIZE[1])-(rawread[0]/1023.)*float(SCREENSIZE[1]))
    #Readings.append(math.sin(counter/50.)*float(SCREENSIZE[1]/3)+float(SCREENSIZE[1])*(1.5/3))
    RawReadings.append(rawread[1])
    MovingReadings.append(rawread[0])
    counterlist.append(counter)
    GraphData+=list(zip([counterlist[-1]],[Readings[-1]]))
    if fpscounter%fpsadjust==0:
        if(mode==1):
            if counter>SCREENSIZE[0]:
                DrawGraph(GraphData[-SCREENSIZE[0]:],TimeList[-SCREENSIZE[0]:],rawread,TimeList[0])
            else:
                DrawGraph(GraphData,TimeList,rawread,TimeList[0])
            PausedData=DoEvents()
        elif (mode==2):
            if PausedData-SCREENSIZE[0]>moving:
                DrawGraphPaused(GraphData[PausedData-SCREENSIZE[0]:PausedData],TimeList[PausedData-SCREENSIZE[0]:PausedData],rawread,TimeList[0],MovingReadings[PausedData-SCREENSIZE[0]-moving:PausedData+moving])
                Pressed=pygame.key.get_pressed()
                if(Pressed[K_LEFT]):
                    if not(PausedData<SCREENSIZE[0]+int(fpsadjust*(SCROLLSPEED+1))):
                        PausedData-=int(fpsadjust*SCROLLSPEED)
                if(Pressed[K_RIGHT]):
                    if not PausedData>counter+SCREENSIZE[0]/2:
                        PausedData+=int(fpsadjust*SCROLLSPEED)
                if(Pressed[K_d]):
                    if (not PausedData>counter-SCREENSIZE[0]/2) and not(pagewait):
                        PausedData+=SCREENSIZE[0]
                        pagewait=4
                if(Pressed[K_a]):
                    if (not PausedData<SCREENSIZE[0]*2) and not(pagewait):
                        PausedData-=SCREENSIZE[0]
                        pagewait=4
                if(pagewait):
                    pagewait-=1                        
            else:
                DrawGraphPaused(GraphData,TimeList,rawread,TimeList[0],MovingReadings[moving-1:])
                PausedData=counter
            DoEventsPaused()
        
    




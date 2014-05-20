import sys
from serial import Serial



path=sys.argv[1]
serialport = Serial(port=path, baudrate=9600)
serialport.write([0x55])
serialport.write([0x12])
serialport.write([0x00])

def GetData():

    recivedlist=[]
    dobreak=0
    while len(recivedlist)<7 and not dobreak:
        while (serialport.inWaiting() > 0) and len(recivedlist)<7:
            recivedlist.append(ord(serialport.read(1)))
    #print recivedlist
    if recivedlist[1]==0x16:
        return ["time",(recivedlist[2]<<32)+(recivedlist[3]<<24)+(recivedlist[4]<<16)+(recivedlist[5]<<8)+(recivedlist[6])]
    else:
        return [0,0,0,0,0]
    
        
        




#f=open(filepath,"w")
#f.write(TITLE+'\n')
counter=0
lapcounter=0
while True:
    rec=GetData()
    counter+=1
    if rec[0]=="time":
        print("LAP "+str(lapcounter)+"\t"+str(rec[1]/16000000.)+"s")
        lapcounter+=1
        
    

import sys
from serial import Serial


TITLE=sys.argv[1]
path=sys.argv[2]
serialport = Serial(port=path, baudrate=9600)
serialport.write([0x55])
serialport.write([0x10])
serialport.write([0x64])

def GetData():

    recivedlist=[]
    dobreak=0
    while len(recivedlist)<5 and not dobreak:
        while (serialport.inWaiting() > 0) and len(recivedlist)<5:
            recivedlist.append(ord(serialport.read(1)))
    #print recivedlist
    if recivedlist[1]==0x16:
        return ["speedtime",(recivedlist[2]<<16)+(recivedlist[3]<<8)+(recivedlist[4])]
    elif recivedlist[1]==0x17:
        return ["motorcount",(recivedlist[2]<<24)+(recivedlist[3]<<16)+(recivedlist[4]<<8)]
    
        
        




#f=open(filepath,"w")
#f.write(TITLE+'\n')
print TITLE+'\n'
counter=0
lapcounter=0
while True:
    recived=[-2,-2]
    rec=GetData()
    counter+=1
    if rec[0]=="speedtime":
        speedtime=rec[1]
    elif rec[0]== "motorcount":
        motorcount=rec[1]
    if counter%2==0:
        print str(motorcount/16000000.)+'\t'+str(speedtime/16000000.)+'\n'
        
    

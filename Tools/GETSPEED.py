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
    while len(recivedlist)<5:
        while (serialport.inWaiting() > 0) and len(recivedlist)<5:
            recivedlist.append(ord(serialport.read(1)))
    #print recivedlist
    if recivedlist[1]==0x16:
        return ["speedtime",(recivedlist[2]<<16)+(recivedlist[3]<<8)+(recivedlist[4])]
    elif recivedlist[1]==0x13:
        return ["motorcount",(recivedlist[2]<<16)+(recivedlist[3]<<8)+(recivedlist[4])]
        
        




#f=open(filepath,"w")
#f.write(TITLE+'\n')
print TITLE+'\n'
counter=0
lapcounter=0
while True:
    recived=[-2,-2]
    while recived[0]==-2 and recived[1]==-2:
        rec=GetData()
        if rec[0]=="speedtime":
            recived[1]=rec
        elif rec[0]== "motorcount":
            recived[1]=rec
    print str(recieved[1][1])+'\t'+str(recieved[0][1])+'\n'
        
    

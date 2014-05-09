import sys
from serial import Serial


TITLE=sys.argv[1]
path=sys.argv[2]
serialport = Serial(port=path, baudrate=9600)
serialport.write([0x55])
serialport.write([0x12])
serialport.write([0x00])

def GetData():

    recivedlist=[]
    while len(recivedlist)<6:
        while (serialport.inWaiting() > 0) and len(recivedlist)<6:
            recivedlist.append(ord(serialport.read(1)))
        if len(recivedlist)==5:
            if recivedlist[1]==0x15:
                break
    #print recivedlist
    if recivedlist[1]==0x15:
        return ["mapend",(recivedlist[2]<<16)+(recivedlist[3]<<8)+(recivedlist[4])]
    elif recivedlist[1]==0x16:
        return ["speedtime",(recivedlist[2]<<16)+(recivedlist[3]<<8)+(recivedlist[4])]
    elif recivedlist[1]==0x17:
        return ["swing",recivedlist[2],(recivedlist[3]<<16)+(recivedlist[4]<<8)+(recivedlist[5])]
    else:
        return [0,0,0,0,0]
        




#f=open(filepath,"w")
#f.write(TITLE+'\n')
print TITLE+'\n'
counter=0
lapcounter=0
while True:

    recieved=GetData()
    #print recieved
    if recieved[0]=="mapend":
       #f.write('\t\n LAP'+str(recieved[1])+'\n')
       lapcounter+=1
       print '\t\n LAP'+str(lapcounter)+'\t'+str(recieved[1])+'\n'
    elif recieved[0]=="speedtime":
        print "SPEED: "+str(recieved[1])
    else:
        if counter%2==0:
            recivedfirst=recieved[2]
        elif recieved[0]=="swing":
            recivedsecond=recieved[2]
            lenght=recivedsecond-recivedfirst
            #f.write(str(counter/2)+str(recieved[0]))
            print str((counter/2)%4)+'\t'+str(lenght)+'\t'+str(recieved[1])
        counter+=1
        
    

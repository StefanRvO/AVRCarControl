    ldi R16,0x00
    sts TransNum,R16
    sts T1_Counter1,R16  ;zero counter stuff
    sts T1_Counter2,R16  ;zero counter stuff
    sts T1_Counter3,R16  ;zero counter stuff
    sts T1_RCounter,R16
    sts Counter,R16
    sts MotorSensorCount1,R16 ;Clear motor counter
    sts MotorSensorCount2,R16 ;Clear motor counter
    sts MotorSensorCount3,R16 ;Clear motor counter
    sts PrevTime1,R16
    sts PrevTime2,R16
    sts PrevTime3,R16
    sts PrevTime4,R16
    sts PrevTime5,R16
    sts TickTime1,R16
    sts TickTime2,R16
    sts TickTime3,R16
    sts TickTime4,R16
    ldi R16,0x10
    sts ADCInterval,R16

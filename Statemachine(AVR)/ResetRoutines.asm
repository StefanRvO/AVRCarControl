;This run on reset
.include    "SetupStack.asm"       ;setup the stack
.include    "SetupSerial.asm"      ;setup serial connection
.include    "SetupIO.asm"
.include    "SetupTime.asm"
.include    "SetupADC.asm"
.include    "ADCAverageStart.asm"
    sei                         ;enable interrupts
    ldi R16,0x00
    sts TurnCount,R16
    sts TransNum,R16
    sts T1_Counter1,R16  ;zero counter stuff
    sts T1_Counter2,R16  ;zero counter stuff
    sts T1_Counter3,R16  ;zero counter stuff
    sts MotorSensorCount1,R16 ;Clear motor counter
    sts MotorSensorCount2,R16 ;Clear motor counter
    sts MotorSensorCount3,R16 ;Clear motor counter
    sts AutoModeState,R16
    ldi R16,HIGH(CarLane)
    sts LanePointerH,R16
    ldi R16,LOW(CarLane)
    sts LanePointerL,R16
    ldi R16,0x00
    CALL    UNBRAKE
    jmp     Main

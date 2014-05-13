;// Routines for the various get commands

;###################################################
;##################GETSPEED#########################
;###################################################


GETSPEED:
    push        ZL
    push        ZH
    push        R20
    push        R21
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    in          R20,OCR2
    ST          Z+,R20
    ldi         R20,1
    sts         TransNum,R20
    ldi         R20,0xBB
    ldi         R21,0x10
    call        TRANSREPLY
    pop         R21
    pop         R22
    pop         ZH
    pop         ZL
ret

;###################################################
;##################GETSTOP##########################
;###################################################

GETSTOP:
ret
;###################################################
;##################GETAUTOMODE######################
;###################################################
GETAUTOMODE:
    push    R19
    push    R20
    push    R21
    lds     R19,AutoModeState
    sts     TransMSG,R19
    ldi     R19,1
    sts     TransNum,R19
    ldi     R20,0xaa
    ldi     R21,0x12
    CALL    TRANSREPLY
    pop     R21
    pop     R20
    pop     R19
ret


;###################################################
;##################GETACCEL#########################
;###################################################


GETACCEL:
    push        R20
    push        R21
    CALL        MakeAverage 
    sts         TransMSG,R20
    ldi         R20,1        ;
    sts         TransNum,R20          ;
    ldi         R20,0xBB ;Response headers
    ldi         R21,0x14
    CALL        TRANSREPLY
    pop         R21
    pop         R20
RET

;###################################################
;##################SWINGPING########################
;###################################################
SWINGPING2: ;//Send the motorcounter, Turncount, ZL, ZH
    push        R16
    push        R17   
    push        R18
    push        R19
    push        R20
    push        R21
    push        R22
    push        R23
    push        ZL
    push        ZH
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH
    SBIW        ZL,8
    
                ;get counters in turn
    LD          R16,Z+
    LD          R17,Z+
    LD          R18,Z+
    LD          R19,Z+
    
    LD          R20,Z+
    LD          R21,Z+
    LD          R22,Z+
    LD          R23,Z+
    
    SUB      R17,R21
    SBC     R18,R22
    SBC     R19,R23 
    
    
    ;Put counter in TransMSG
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    ST          Z+,R19
    ST          Z+,R18
    ST          Z+,R17
    ldi         R20,3
    ldi         R20,0x00 ;Respond header
    ldi         R21,0x00
    CALL        TRANSREPLY
    pop         ZH
    pop         ZL
    pop         R23
    pop         R22
    pop         R21
    pop         R20
    pop         R19
    pop         R18
    pop         R17
    pop         R16
    ret

SWINGPING: ;//Send the motorcounter, Turncount, ZL, ZH
    push        R22
    push        R21
    push        R20
    push        R19
    push        R18
    push        R17
    push        R16
    push        R15
    push        ZL
    push        ZH
    ;fetch motor counter
    lds         ZL,LanePointerL
    lds         ZH,LanePointerH
    SBIW        ZL,8
    ld          R22,Z+
    LD          R21,Z+
    LD          R20,Z+
    LD          R19,Z+
    
    LD          R18,Z+
    LD          R17,Z+
    LD          R16,Z+
    LD          R15,Z+
    ;Put counter in TransMSG
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    ST          Z+,R22
    ST          Z+,R19
    ST          Z+,R20
    ST          Z+,R21
    ldi         R20,4
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x17
    CALL        TRANSREPLY
    
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    ST          Z+,R18
    ST          Z+,R15
    ST          Z+,R16
    ST          Z+,R17
    ldi         R20,4
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x17
    CALL        TRANSREPLY
    pop         ZH
    pop         ZL
    pop         R15
    pop         R16
    pop         R17
    pop         R18
    pop         R19
    pop         R20
    pop         R21
    pop         R22
    ret

;###################################################
;##################GETTIME##########################
;###################################################

GETTIME: ;Send the current time
    push        R19
    push        R20
    push        R21
    push        R22
    push        R23
    push        R24
    push        ZL
    push        ZH
    ;fetch clock
    lds         R22,T1_Counter1     ;what if timer overflows while in interrupt?
    lds         R23,T1_Counter2
    lds         R24,T1_Counter3
    in          R20,TCNT1L
    in          R21,TCNT1H
    in          R19,TIFR
    SBRS        R19	,TOV1 ;Increment  if we have a overflow
    rjmp        END_INC_GETTIME
    cpi         R21,0xff
    brne        INCREASE_GETTIME ;routine is partly ripped of from arduino's micros() code
    cpi         R20,0xfe
    brsh        INCREASE_GETTIME
    rjmp        END_INC_GETTIME
    INCREASE_GETTIME:
    CLC
    inc         R22
    brne        END_INC_GETTIME
    inc         R23
    brne        END_INC_GETTIME
    inc         R24
    END_INC_GETTIME:  
    ;fetch done

        

    ;Put Time in TransMSG
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    ST          Z+,R24
    ST          Z+,R23
    ST          Z+,R22
    ST          Z+,R21
    ST          Z+,R20
    ldi         R20,5
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x16
    CALL        TRANSREPLY
    pop         ZH
    pop         ZL
    pop         R24
    pop         R23
    pop         R22
    pop         R21
    pop         R20
    pop         R19
ret
;#########################################################
;####################GETMOTORCOUNTER######################
;#########################################################

GETMOTORCOUNTER: ;Send the motor counter
    push        R20
    push        R21
    push        R22
    push        ZL
    push        ZH
    ;fetch motor counter
    lds         R22,MotorSensorCount1
    lds         R21,MotorSensorCount2
    lds         R20,MotorSensorCount3
    ;Put counter in TransMSG
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    ST          Z+,R20
    ST          Z+,R21
    ST          Z+,R22
    ldi         R20,3
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x15
    call        TRANSREPLY
    pop         ZH
    pop         ZL
    pop         R22
    pop         R21
    pop         R20
ret

;################################################
;############GETSPEEDTIME########################
;################################################
    

GETSPEEDTIME:
    push    R15
    push    R16
    push    R17
    push    R18
    push    R19
    push    R20
    push    R21
    push    ZL
    push    ZH
    
    
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    CALL        CALCSPEED
;    ST          Z+,R19
;    ST          Z+,R18
    ST          Z+,R17
    ST          Z+,R16
    ST          Z+,R15
    ldi         R20,3
    sts         TransNum,R20
    ldi         R20,0xBB ;Respond header
    ldi         R21,0x16
    call        TRANSREPLY
    
    pop     ZH
    pop     ZL
    pop     R21
    pop     R20
    pop     R19
    pop     R18
    pop     R17
    pop     R16
    pop     R15
ret
    

;###################################################
;##################TRANSREPLY#######################
;###################################################

TRANSREPLY:  ;Sends the data in R20:R21 (header), followed by data starting from 0x301 and forward the number of bytes in 0x300
    push        ZL
    push        ZH
    SBIS        UCSRA,UDRE
    RJMP        TRANSREPLY
    out         UDR,R20
    TRANSREPLY1:
    SBIS        UCSRA,UDRE
    RJMP        TRANSREPLY1
    out         UDR,R21
    ldi	        ZH,high(TransMSG)	; make high byte of Z point at address of msg
    ldi         ZL,low(TransMSG)
    lds         R20,TransNum
    inc         R20 ;Need to inc to get correct count
    TRANSREPLYloop:
    SBIS        UCSRA,UDRE
    RJMP        TRANSREPLYloop
    dec         R20
    BREQ        TRANSREPLYEXIT
    ld          R21,Z+
    out         UDR,R21
    rjmp        TRANSREPLYloop
    TRANSREPLYEXIT:
    pop         ZH
    pop         ZL
RET


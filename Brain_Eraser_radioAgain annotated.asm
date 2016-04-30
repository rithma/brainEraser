 .include	"tn28def.inc"

;The input and output ports should really be noted here.

;The fact that it runs on the internal oscillator should be noted here.

;The fact that an external oscillator sets the sample period should be noted here.

;The existence of two control switches should be noted here.

;But it is fun to just fly.

;Wheeeeeeeeee!

;This was done very quickly and informally.



.def  scratch = R16

.def  scratch2 = R17

.def  counterA0 = R18

.def  counterCB = R19

.def  counterED = R20

.def  parodyleft = R21

.def  parodyright = R22

.def  function = R23              ;unused

.equ  FQ0 = 0                     ;unused artifact

.def  FQ1 = R24                   ;FQ1 and FQ2 are really just used as
                                  ;single-bit flags for external switches.
.def FQ2 = R25                    ;I think the FQ's were left over from a 
                                  ;naming mistake in the counters early on
                                  ;in the effort of trying to translate the
                                  ;original VHDL CPLD code into AVR assembler.
                                  ;The library counter modules supplied by
                                  ;Lattice Semiconductor had Q0, Q1, Q2, and Q3 
                                  ;as the default names of the output lines.
                                  ;Lazily starting with that and then needing to 
                                  ;distinguish the next counter module's output 
                                  ;names led to the designations AQ0 etc.
                                  ;That's how these things happen.

.equ  FQ3 = 3                     ;unused


                                  ;The input clock frequency is something like
                                  ; 5600Hz for the nominal brain eraser song.


.equ  Q0 = 0                      ; 2800 Hz

.equ  Q1 = 1                      ; 1400 Hz

.equ  Q2 = 2                      ; 700 Hz

.equ  Q3 = 3                      ; 350 Hz

.equ  AQ0 = 4                     ; 175 Hz

.equ  AQ1 = 5                     ; 88 Hz

.equ  AQ2 = 6                     ; 44 Hz

.equ  AQ3 = 7                     ; 22 Hz

.equ  BQ0 = 0                     ; 11 hz

.equ  BQ1 = 1                     ; 5.5 Hz

.equ  BQ2 = 2                     ; 2.7 Hz

.equ  BQ3 = 3                     ; 1.4 Hz -or- 0.73 seconds


.equ  CQ0 = 4                     ; 1.5 seconds

.equ  CQ1 = 5                     ; 3 seconds

.equ  CQ2 = 6                     ; 6 seconds

.equ  CQ3 = 7                     ; 12 seconds

.equ  DQ0 = 0                     ; 23 seconds

.equ  DQ1 = 1                     ; 47 seconds

.equ  DQ2 = 2                     ; 94 seconds -or- a minute and a half

.equ  DQ3 = 3                     ; 3 minutes

.equ  EQ0 = 4                     ; 6 minutes

.equ  EQ1 = 5                     ; 12 minutes

.equ  EQ2 = 6                     ; 25 minutes

.equ  EQ3 = 7                     ; 50 minutes



loop:

wait:

waitloop:

sbis  pinB,0

rjmp waitloop

       
                                  ;Output the left and right channels
ser scratch                       ;set scratch to all 1's

out ddrd,scratch                  ;set port d lines to be all outputs



clr scratch

sbrc parodyleft,0                 ;transfere parity left and parity right
                                  ;0th bits to output port D bits 0 and 4
sbr scratch,0x01

sbrc parodyright,0

sbr scratch,0x04

out portd,scratch


                                  ;Read two external switches

clr scratch

mov FQ1,scratch                   ;same as clr FQ1 and FQ2
                                  ;but no flags are changed.
mov FQ2,scratch                   ;is this why it was done this way?
                                  ;No. Only bit-0 of FQ1 and FQ2 are checked.

ser scratch                       ;scratch set to all 1's

sbic PINB,3                       
                                  ;if port PINB bit 3 is high
mov FQ1,scratch                   ;change set FQ1 from all 0's to all 1's.
                                  ;Used in terms EZ21, 22, 23, and 24.
sbic pinB,4
                                  ;if port PINB bit 4 is high
mov FQ2,scratch                   ;change FQ2 from all 0,s to all 1's.
                                  ;Used in term FZ11, 12, 13, and 14.

clr parodyright                   ;clear parityright and parityleft
                                  ;accumulators for the calculation of the
clr parodyleft                    ;next output sample


                                  ;advance the 24bit counter.
                                  ;4-bit sections of the counter are called
                                  ; Q, AQ, BQ, CQ, DQ, and EQ.
                                  ;Two 4-bit sections are contained in a byte.
                                  ;As 8-bit bytes, the sections are called
                                  ; A0, CB, and ED. (EDCBA0)
clr scratch

ldi  scratch2,0X01                ;set scratch 2 to a value of 1.

add  counterA0,scratch2           ;ADD is used instead of INC because
                                  ;INC (increment) does not set the carry flag.
adc  counterCB,scratch            ;Add the value 0 along with the carry flag
                                  ;to propagate the carrys through the
adc  counterED,scratch            ;3-byte (24 bit) counter chain


clr parodyleft                    ;redundant

clr parodyright


                                  ;calculate the left channel output.
                                  ;parityleft is the parity generator.
                                  ;bit-0 = 0 means an even number of ones
                                  ; =1 means an odd number of 1's were seen.
                                  ;Each new 1 increments the byte-wide register
                                  ;parityleft and thereby toggles the least
                                  ;significant bit, bit-0, on and off and on
                                  ;and off --- leaving it on for an odd number
                                  ;and off for an even number of toggles or for
                                  ;no toggle at all. Parity 


                                  ;The 0th bit of the slower running 4-bit counter
                                  ;C, CQ0, gates the counter's highest frequency
                                  ;bit, Q0, through to the left side parity
                                  ;generator, bit-0 of a counter called parityleft.
termAZ01:

sbrs  counterA0,Q0                ;if Qo is zero, skip incrementing parityleft
                                  ;and continue on to the next slower bit, Q1.
rjmp termAZ02

sbrc  counterCB,CQ0               ;so, q0 was a one... is cq0 on, is it 1?
                                  ;if cq0 is off skip any Q0 action on parityleft.
inc  parodyleft                   ;increment parityleft (if Q0 AND CQ0 equal 1).


termAZ02:

sbrs  counterA0,Q1

rjmp  termAZ11

sbrc  counterCB,CQ1

inc  parodyleft                   ; ...if Q1 AND CQ1 are true


termAZ11:

sbrs  counterA0,Q2

rjmp  termAZ12

sbrc  counterCB,CQ2

inc  parodyleft                   ; ...if Q2 AND CQ2 are true


termAZ12:

sbrs  counterA0,Q3              

rjmp  termAZ21

sbrc counterCB,CQ3

inc parodyleft                    ; ...if Q3 AND CQ3 are true


termAZ21:

sbrs  counterA0,AQ0

rjmp  termAZ22

sbrc  counterCB,BQ0

inc  parodyleft                   ; ...if AQ0 AND BQ0 are true
                                  ;This breaks with the pattern established
                                  ;above for Q0-Q3 ANDED with Cq0-Cq3.
                                  ;CQ0 is 256 times slower than Q0.
                                  ;BQ0 is only 16 times slower than AQ0.
termAZ22:

sbrs  counterA0,AQ1

rjmp termAZ31

sbrc counterCB, BQ1

inc parodyleft                    ; ...if AQ1 AND BQ1 are true


termAZ31:

sbrs  counterA0,AQ0

rjmp termAZ32

sbrc counterCB,BQ2

inc parodyleft                    ; ...if AQ0 AND BQ2 are true
                                  ;So, with term AZ21, the statement becomes
                                  ; If [AQ0 AND BQ0] -OR- [AQ0 AND BQ2]
                                  ; are true
                                  
                                  ;This is the AND/OR/INVERT logic form that
                                  ;arises spontaneously from the primordial
                                  ;binary sea. If you look behind the registers,
                                  ;the flip-flops, in the 74LS163 logic drawings,
                                  ;you will see ANDs ORed together
                                  ;to make the fabric of the COUNT/
                                  ;CLEAR/LOAD function. The CPLD's acknowledge 
                                  ;this inevitability with their basic architecture.
                                  ;They consist of blocks of registers backed by
                                  ;manifolds of AND/OR/INVERT structures. 
                                  ;EXCLUSIVE ORs, another magic, are included.
                                  ;There used to be AND/OR/INVERT integrated circuits.

                                  ;The Parametrons were majority logic. The 
                                  ;outputs were the votes of all the inputs.
                                  ;Different... 
termAZ32:

sbrs  counterA0,AQ1

rjmp  termBZ01

sbrc  counterCB,BQ3

inc parodyleft                    ; ...if AQ1 AND BQ3 are true
                                  ;So, with term AZ31, the statement becomes
                                  ; If [AQ1 AND BQ1] -OR- [AQ1 AND BQ3]
                                  ; are true


termBZ01:

sbrs  counterCB,BQ0

rjmp  termBZ02

sbrc  counterED,DQ0

inc parodyleft                    ; ...if BQ0 AND DQ0 are true


termBZ02: 

sbrs  counterCB,BQ1

rjmp  termBZ11

sbrc counterED,DQ1

inc parodyleft                    ; ...if BQ1 AND DQ1 are true


termBZ11:

sbrs counterCB,BQ2

rjmp termBZ12

sbrc  counterED,DQ2

inc parodyleft                    ; ...if BQ2 AND DQ2 are true


termBZ12:

sbrs counterCB,BQ3

rjmp  termEZ01

sbrc  counterED,DQ3

inc parodyleft                    ; ...if BQ3 AND DQ3 are true

                                  ;This is the end of the left channel calculation.
                                  ;The left channel output is contained in the
                                  ;state of the least signnificant bit (LSB), bit-0,
                                  ;of parityleft.

                                  ; (Hey... this last part seems 
                                  ;pretty boring... it's just
                                  ;messing arround with flipping
                                  ;the output polarity at the 
                                  ;2Hz to 12Hz rates offered by
                                  ;BQ3-BQ0. If you turn up the 
                                  ;clock frequency though, these 
                                  ;do climb to become notes in 
                                  ;their own right. But in the 
                                  ;fixed song, I don't know.
                                  ;Maybe messing with it just 
                                  ;didn't do much (with the clock
                                  ;locked down to 5000 something Hz).
                                  ;I don't think I schmooed the clock
                                  ;during this design... In fact
                                  ;I would panic if I wandered off
                                  ;the magic frequency because it
                                  ;it was hard to just casually 
                                  ;find it again due to the fractal
                                  ;nature of the song.)


                                  ;Calculate the right channel output.
                                  ;Parityright is starting as all zero's from
                                  ;preparations made above.
termEZ01:

clr  scratch                      ;Oy!

sbrs  counterA0,Q0

rjmp  termEZ02

sbrs  counterCB,CQ0

rjmp  termEZ02

sbrc  counterED,EQ2

rjmp  termEZ02

ldi  scratch,01                   ;scratch is set to 1 if
                                  ; Q0 AND CQ0 AND NOT EQ2 
                                  ; are true.



termEZ02:

sbrs counterA0,Q3

rjmp termEZ03

sbrs  counterCB,CQ1

rjmp  termEZ03

sbrs  counterED,EQ2

rjmp  termEZ03

ldi  scratch,01                   ;scratch is set to one if
                                  ; Q3 AND CQ1 AND EQ2
                                  ; are true.


termEZ03:

add  parodyright,scratch          ;Parityright recieves a one if
                                  ; [Q0 AND CQ0 AND NOT EQ2] -OR- [Q3 AND CQ1 AND EQ2]
                                  ; are true. 
                                  ;EQ2 acts like a selector switch choosing which
                                  ;equation is active ...[Q0 AND CQ0] OR [Q3 and CQ1].
                                  ;EQ2 is the address line into a two-input multiplexer. 


clr scratch                       ;Term EZ03 actually starts here. Its lable was used
                                  ;as my lazy convenience. More correct would have been
                                  ;have everything RJMP or fall-through to a label
                                  ;celebrating the end or completion of terms EZ01 and
                                  ;EZ02. Then would start term EZ03 with a label that
                                  ;is informative, termEZ03, but not really used by 
                                  ;the program.
sbrs  counterED,EQ1

rjmp  termEZ04

sbrs  counterED,EQ2

rjmp termEZ04

rjmp termEZ05


termEZ04:

sbrs  counterA0,Q1

rjmp  termEZ05

sbrs counterCB,CQ1

rjmp  termEZ05

ldi  scratch,01                   ;scratch is set to 1 if
                                  ; [EQ1 AND EQ2]NOT AND Q1 AND CQ1 
                                  ; are true


termEZ05:

sbrs counterA0,Q2

rjmp termEZ11

sbrs counterCB,CQ3

rjmp termEZ11

sbrs counterED,EQ3

rjmp termEZ11

sbrs counterED,EQ1

rjmp termEZ11

sbrs counterED,EQ2

rjmp termEZ11

ldi  scratch,01                   ;scratch is set to 1 if
                                  ; Q2 AND CQ3 AND EQ3 AND EQ1 AND EQ2
                                  ; are true


termEZ11:

add parodyright,scratch           ;parityright receives a one if
                                  ; [[EQ1 AND EQ2]NOT AND Q1 AND CQ1]
                                  ;                -OR-
                                  ; [Q2 AND CQ3 AND EQ3 AND EQ1 AND EQ2]
                                  ; are true.
                                  ;[EQ1 AND EQ3] acts as the selector choosing
                                  ;[Q1 AND CQ1] if it is false, 
                                  ;with either EQ1 or EQ2 being zero,
                                  ;  -or-
                                  ;choosing [Q2 AND CQ3 AND EQ3] if it is true
                                  ;with both EQ1 and EQ2 being true (one).


sbrs counterA0,Q2                 ;termEZ11 actually starts here.

rjmp  termEZ12

sbrc  counterCB,CQ2

inc parodyright                   ; ...if Q2 AND CQ2 NOT are true.
                                 

termEZ12:

sbrs  counterA0,Q3

rjmp  termEZ21

sbrc counterCB,CQ3

inc parodyright                   ; ...if Q3 AND CQ3 NOT are true.



termEZ21:

clr scratch

sbrs counterA0,AQ0

rjmp termEZ22

sbrs counterCB,BQ1

rjmp termEZ22

sbrc  FQ1,0

rjmp  termEZ22

ldi  scratch,01                   ;AQ0 AND BQ1 if the switch feeding FQ1 is zero.


termEZ22:

sbrs counterA0,AQ0

rjmp termEZ23

sbrs  counterCB,BQ0

rjmp  termEZ23

sbrs FQ1,0

rjmp  termEZ23

ldi  scratch,01                   ;AQ0 AND BQ0 if the switch feeding FQ1 is one.


termEZ23:

add parodyright,scratch

clr scratch

sbrs  counterA0,AQ1

rjmp  termEZ24

sbrs  counterCB,BQ0

rjmp  termEZ24

sbrc  FQ1,0

rjmp termEZ24

ldi scratch,01                    ;AQ1 AND BQ0 if the switch feeding FQ1 is zero.



termEZ24:

sbrs counterA0,AQ1

rjmp termEZ31

sbrs counterCB,BQ1

rjmp termEZ31

sbrs  FQ1,0

rjmp termEZ31

ldi scratch,01                    ;AQ1 AND BQ1 if the switch feeding FQ1 is one.


termEZ31:

add parodyright,scratch

sbrs counterA0,AQ0

rjmp termEZ32

sbrc counterCB,BQ2

inc  parodyright                  ; ...if AQ0 AND BQ2 NOT are true.


termEZ32:

sbrs  counterA0,AQ1

rjmp termFZ01 

sbrc  counterCB,BQ3

inc parodyright                   ; ...if AQ1 AND BQ3 NOT are true.


termFZ01:

sbrs counterCB,BQ0

rjmp termFZ02

sbrc  counterED,DQ0

inc parodyright                   ; ...if BQ0 AND DQ0 NOT are true



termFZ02:

sbrs counterCB,BQ1

rjmp termFZ11

sbrc counterED,DQ1

inc parodyright                   ; ...if BQ1 AND DQ1 NOT are true


termFZ11:

clr scratch

sbrs  counterCB,BQ2

rjmp termFZ12

sbrs counterED,DQ2

rjmp termFZ12

sbrc FQ2,0

rjmp termFZ12

ldi scratch,01                    ;BQ2 AND DQ2 if the switch feeding FQ2 is zero.


termFZ12:

sbrs counterCB,BQ2

rjmp termFZ13

sbrs counterED,DQ3

rjmp termFZ13

sbrs FQ2,0

rjmp termFZ13

ldi scratch,01                    ;BQ2 AND DQ3 if the switch feeding FQ2 is one.


termFZ13:

add parodyright,scratch

clr scratch

sbrs  counterCB,BQ3

rjmp termFZ14

sbrs counterED,DQ3

rjmp termFZ14

sbrc FQ2,0

rjmp termFZ14

ldi scratch,01                    ;BQ3 AND DQ3 if the switch feeding FQ2 is zero.



termFZ14:    
                
sbrs counterCB,BQ3

rjmp termsexit

sbrs counterED,DQ2

rjmp termsexit

sbrs FQ2,0

rjmp termsexit


termsexit:

add parodyright,scratch           ;BQ3 AND DQ2 if the switch feeding FQ2 is one.



rjmp loop                         ;Go back around, output the left and right channels,
                                  ;and setup to calculate the next sample.



























 































































; definition
LCD1602_RS_Pin equ P0.0
LCD1602_RW_Pin equ P0.1
LCD1602_EN_Pin equ P0.2
LCD1602_Data_Port equ P1
DS1307_Address equ 0d0h
SDA equ P3.6
SCL equ P3.7
DS1307_Second_Reg equ 00h
DS1307_Minutes_Reg equ 01h
DS1307_Hours_Reg equ 02h
DS1307_Day_Reg equ 03h
DS1307_Date_Reg equ 04h
DS1307_Month_Reg equ 05h
DS1307_Year_Reg equ 06h
DS1307_Control_Reg equ 07h
DS1307_Ram equ 08h
LCD_Clear_Screen equ 01h
LCD_Reset_Cursor equ 02h
LCD_Input_Set equ 04h
LCD_Display_Switch equ 08h
LCD_Shift equ 10h
LCD_Function_Set equ 20h
LCD_Set_CGRAM_Addr equ 40h
LCD_Set_DDRAM_Addr equ 80h
Rotary_Encoder_DT equ P2.0
Rotary_Encoder_CLK equ P2.1
Rotary_Encoder_SW equ P3.2


org 0000h
	jmp Start

org 0003h
	clr EA
	acall delay_1ms
	acall BUTTON_HANDLER
	setb EA
	reti

org 0013h
	acall DISPLAY_TIME_TO_LCD
	reti

org 0030h
    monday: db "MON", 0 
    tuesday: db "TUE", 0
    wednesday: db "WED", 0
    thursday: db "THU", 0
    friday: db "FRI", 0
    saturday: db "SAT", 0 
    sunday: db "SUN", 0

org 0100h	
Start:
	; khoi tao lcd
	acall LCD_INIT
	acall DISPLAY_TIME_TO_LCD
	
	; khoi tao cac thong so ban dau cho DS1307
	acall DS1307_GET_SECOND
	acall START_RTC
	mov A, #0
	acall DS1307_SET_SQW_FREQ
	
	;setup input
	mov P2, #03h
	mov P3, #0ffh
	
	; setup cac ngat ngoai
	SETB IT0    ; INT0 kích cạnh xuống
    SETB EX0    ; Cho phép ngắt INT0
    SETB EA     ; Cho phép toàn bộ ngắt
	setb IT1	; INT1 kich canh xuong
	setb ex1	; bat ngat INT1
	
	mov 38h, #0ffh
	
MainLoop:
	acall CHECK_ENCODER
	acall delay_1ms
	jmp MainLoop

;-----------------------------------------------
; I2C Interface
;-----------------------------------------------
I2C_Start:
      setb SDA	; ensure SDA is high
      setb SCL	; ensure SCL is high
      clr SDA	; Pull SDA to low
      ret
I2C_Send_Byte:
      mov R7, #8;				(1 cycle)
      send_loop:
      clr SCL	; ready for data transfer 	(1 cycle)
      rlc A ; 					(1 cycle)
      mov SDA, C ; 				(2 cycles)
      acall delay_3us ;				(6 cycles)
      setb SCL  ; 				(1 cycle)
      acall delay_3us;				(6 cycles)
      nop	; 				(1 cycle)
      DJNZ R7, send_loop ;			(2 cycles)
      clr SCL	;				(1 cycle)
      ret;					(2 cycles)
I2C_Read_ACK:
      acall delay_2us;				(4 cycles)
      setb SDA	; 				(1 cycle)
      setb SCL ;				(1 cycles)
      mov C, SDA;				(1 cycle)
      nop;					(1 cycle)
      nop;					(1 cycle)
      ret ; 					(2 cycles)
I2C_Read_Byte:
      mov R7, #9; counter			(1 cycle)
	  clr C
	  clr A
      read_loop:
      setb SCL;					(1 cycle)
      mov C, SDA; read SDA's state		(1 cycle)
      rlc A;	shift read bit to A register	(1 cycle)
      acall delay_3us;				(6 cycles)
      nop;					(1 cycle)
      clr SCL;					(1 cycle)
      acall delay_3us;				(6 cycles)
      nop;					(1 cycle)
      DJNZ R7, read_loop;			(2 cycles)
      setb SCL;					(1 cycle) 
	  ;rlc A
      ret;					(2 cycles)
I2C_Send_Ack:
      clr SDA;					(1 cycle)
      acall delay_2us;				(4 cycles)
      setb SCL;					(1 cycle)
      ret;					(2 cycles)
I2C_Send_NoAck:
      nop;					(1 cycle)
      acall delay_2us;				(4 cycles)
      clr SCL;					(1 cycle)
      acall delay_4us;				(8 cycles)
      setb SDA;					(1 cycle)
      setb SCL;					(1 cycle)
      ret;					(2 cycles)
I2C_Stop:
      nop ;					(1 cycle)
      nop ;					(1 cycle)
      clr SCL	; Push SCL to high		(1 cycle)
      clr SDA;					(1 cycle)
      acall delay_4us;				(8 cycles)
      setb SCL;					(1 cycle)
      setb SDA	;stop condition			(1 cycle)
      ret;					(2 cycle)
;-----------------------------------------------;
;delay functions
;-----------------------------------------------;
delay_5us:
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      ret	;				(2 cycles)
delay_4us:
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      ret	;				(2 cycles)
delay_3us:
      nop ; 					(1 cycle)
      nop ; 					(1 cycle)
      ret	;				(2 cycles)
delay_2us:
      ret	;				(2 cycles)
delay_1ms:
      mov R1, #166;				(1 cycle)
      delay_loop:
      acall delay_5us;				(10 cycles)
      djnz R1, delay_loop;			(2 cycles)
      nop
      nop
      nop
      ret;					(2 cycles)
; su dung thanh ghi R2 lam tham so (ms > 1)
; todo: chua chinh xac
delay_ms:
      ;dec R2;					(1 cycle)
      delay_ms_loop:
      acall delay_1ms;				(2000 cycles)
      djnz R2, delay_ms_loop;			(2 cycle)
      ret;					(2 cycle)
     
;-----------------------------------------------;
;lcd 8-bit parallel 
;-----------------------------------------------;
; brief: send instuction code to lcd 1602
; use register A as instruction code byte to be sent
LCD1602_Send_Ins:
	setb LCD1602_EN_Pin
	clr LCD1602_RW_Pin
	clr LCD1602_RS_Pin
	mov LCD1602_Data_Port, A
	acall delay_3us
	clr LCD1602_EN_Pin
	mov R2, #2d
	acall delay_ms
	ret
	
; brief: send data to lcd 1602's RAM (DDRAM, CGRAM)
; use register A as data byte to be sent
LCD1602_Send_Data:
	setb LCD1602_EN_Pin
	clr LCD1602_RW_Pin
	setb LCD1602_RS_Pin
	mov LCD1602_Data_Port, A
	acall delay_3us
	clr LCD1602_EN_Pin
	mov R2, #2d
	acall delay_ms
	ret

;-----------------------------------------------
; LCD_INIT
; Khởi tạo LCD1602 chế độ 8-bit
;-----------------------------------------------
LCD_INIT:
	; initialize lcd 1602
	mov R2, #15d
	acall delay_ms
	mov A, #30h
	acall LCD1602_Send_Ins
	mov R2, #5d
	acall delay_ms
	mov A, #30h
	acall LCD1602_Send_Ins
	acall delay_2us
	mov A, #30h
	acall LCD1602_Send_Ins
	mov R2, #10d
	acall delay_ms
	
	;setup lcd 1602
	mov A, #38h ; function set -> DL = 1 (8 bit mode), N = 1 (2 line), F = 0 (5 x 8 characters)
	acall LCD1602_Send_Ins
	mov A, #08h ; turn the display, cursor, blinking off (D = 0, C = 0, B = 0)
	acall LCD1602_Send_Ins
	mov A, #01h ; screen clear instruction code
	acall LCD1602_Send_Ins
	mov A, #06h ; input set -> I/D = 1 (Increment mode), S = 0 (no shift)
	acall LCD1602_Send_Ins
	mov A, #0Ch ; turn the dislay on, D = 1
	acall LCD1602_Send_Ins    
    ret 

;-----------------------------------------------
; LCD_CLEAR
; Gửi lệnh 0x01 để xóa toàn bộ nội dung LCD
; Gọi LCD1602_Send_Ins, không cần thay đổi gì thêm
;-----------------------------------------------
LCD_Clear:
    mov A, #01h            ; Lệnh 0x01 clear
    acall LCD1602_Send_Ins ; 
    ret


;-----------------------------------------------
; LCD_SETCURSOR
; Đặt vị trí con trỏ tại (row, col)
; - Input: R0 = row (0 hoặc 1), R1 = col (0..15)
; - Tính địa chỉ DDRAM:
;     row = 0 → addr = 0x80 + col
;     row = 1 → addr = 0xC0 + col
; - Gán addr vào A, rồi gọi LCD1602_Send_Ins
;-----------------------------------------------
;Đặt vị trí con trỏ tại (row, col)
LCD_SETCURSOR:
    mov A, R0           ; Kiểm tra hàng (row)
    cjne A, #0, Row1    ; Nếu R0 ≠ 0 → row 1
; Row = 0
    mov A, #80h         ; 
    add A, R1           ; A = 0x80 + col
    sjmp SetCursor

Row1:
    mov A, #0C0h        ; Base address for row 1
    add A, R1           ; A = 0xC0 + col

SetCursor:
    acall LCD1602_Send_Ins
    ret

;-----------------------------------------------
;LCD_Send_Char
;-----------------------------------------------
; Gửi một ký tự đến LCD
; A = ký tự ASCII cần hiển thị
LCD_Send_Char:
    acall LCD1602_Send_Data
    ret


;-----------------------------------------------
; LCD_SEND_STRING
; Gửi chuỗi ký tự đến LCD
; - DPTR trỏ đến chuỗi kết thúc bằng 0 (null-terminated)
;-----------------------------------------------
LCD_SEND_STRING:
    clr A                    ; Đặt offset ban đầu = 0
Next_Char:
    push ACC
    movc A, @A+DPTR          ; Đọc ký tự từ ROM (DPTR + offset A)
    jz Done                  ; Nếu A == 0 (kết thúc chuỗi), thoát
    acall LCD1602_Send_Data  ; Gửi ký tự ra LCD
    pop ACC 
    inc A                    ; Tăng offset
    sjmp Next_Char           ; Lặp lại
Done:
	pop ACC
    ret
;-----------------------------------------------
;-----------------------------------------------
; DS1307_WRITE_BYTE
; Ghi 1 byte dữ liệu vào DS1307 tại địa chỉ reg
; Tham số: A chứa địa chỉ thanh ghi (reg)
; 	   B chứa dữ liệu cần ghi (data)		
;-----------------------------------------------
DS1307_WRITE_BYTE:
	push ACC
	mov A, #DS1307_Address
	acall I2C_Start
	acall I2C_Send_Byte
	acall I2C_Read_ACK
    pop ACC
	acall I2C_Send_Byte
	acall I2C_Read_ACK
	mov A, B
	acall I2C_Send_Byte
	acall I2C_Read_ACK
	acall I2C_Stop
	ret

;-----------------------------------------------
; DS1307_READ_BYTE
; Đọc 1 byte dữ liệu từ DS1307 tại địa chỉ reg
; Tham số: A chứa địa chỉ thanh ghi (reg)
; Trả về: A chứa dữ liệu đọc được từ DS1307
;huy
;-----------------------------------------------
DS1307_READ_BYTE:
	PUSH Acc
	mov A, #DS1307_Address
      	acall I2C_Start
      	acall I2C_Send_Byte
     	acall I2C_Read_ACK
     	pop Acc
      	acall I2C_Send_Byte
     	acall I2C_Read_ACK
     	acall I2C_Stop
    	mov A, #DS1307_Address
    	orl A, #1
   	acall I2C_Start
     	acall I2C_Send_Byte
     	acall I2C_Read_ACK
      	acall I2C_Read_Byte
      	acall I2C_Send_NoAck
      	acall I2C_Stop
	RET

;-----------------------------------------------
; DS1307_SET_SQW_FREQ
; Cài đặt tần số xung output của DS1307
; Tham số: 	A = 0x00 -> 1Hz
;	    	A = 0x01 -> 4kHz
;	    	A = 0x02 -> 8kHz
;	    	A = 0x03 -> 32kHz 
;-----------------------------------------------
DS1307_SET_SQW_FREQ:
	sqw_1hz:
	cjne A, #00h, sqw_4kHz
    mov A, #10h
    sjmp final_set_freq
	
	sqw_4kHz:
	cjne A, #01h, sqw_8kHz
    mov A, #11h
    sjmp final_set_freq

	sqw_8kHz:
	cjne A, #02h, sqw_32kHz
	mov A, #12h
    sjmp final_set_freq

	sqw_32kHz:
    mov A, #13h
	
    final_set_freq:
	mov B, A
	mov A, #DS1307_Control_Reg
	acall DS1307_WRITE_BYTE
    ret 


;-----------------------------------------------
; DS1307_SET_SQW
; Bật tắt xung output của DS1307
; Tham số: 	C = 0 -> off
;           C = 1 -> on
;-----------------------------------------------
DS1307_SET_SQW:
	jnc off
    on:
	mov A, #DS1307_Control_Reg 
    acall DS1307_READ_BYTE
    orl A, #10h
    sjmp final_set_sqw
    off:
	mov A, #DS1307_Control_Reg 
    acall DS1307_READ_BYTE
    anl A, #0efh
    final_set_sqw:
    mov B, A 
    mov A, #DS1307_Control_Reg
    acall DS1307_WRITE_BYTE
    ret

;-----------------------------------------------
; DS1307_GET: Các hàm để lấy thông tin từ DS1307
;-----------------------------------------------
DS1307_GET_TIME:
	acall DS1307_GET_SECOND
	acall DS1307_GET_MINUTES
	acall DS1307_GET_HOURS
	acall DS1307_GET_DAY
	acall DS1307_GET_DATE
	acall DS1307_GET_MONTH
	acall DS1307_GET_YEAR
	ret
;-----------------------------------------------
DS1307_GET_SECOND:
	MOV A, #DS1307_Second_Reg
	ACALL DS1307_READ_BYTE
	MOV 30H, A
	RET
;-----------------------------------------------
DS1307_GET_MINUTES:
	MOV A, #DS1307_Minutes_Reg
	ACALL DS1307_READ_BYTE
	MOV 31H, A
	RET
;-----------------------------------------------
DS1307_GET_HOURS:	
	MOV A, #DS1307_Hours_Reg
	ACALL DS1307_READ_BYTE
	MOV 32H, A
	RET
;-----------------------------------------------
DS1307_GET_DAY:	
	MOV A, #DS1307_Day_Reg
	ACALL DS1307_READ_BYTE
	MOV 33H, A
	RET
;-----------------------------------------------
DS1307_GET_DATE:	
	MOV A, #DS1307_Date_Reg
	ACALL DS1307_READ_BYTE
	MOV 34h, A
	RET
	
;-----------------------------------------------
DS1307_GET_MONTH:	
	MOV A, #DS1307_Month_Reg
	ACALL DS1307_READ_BYTE
	MOV 35H, A
	RET
	
;-----------------------------------------------
DS1307_GET_YEAR:	
	MOV A, #DS1307_Year_Reg
	ACALL DS1307_READ_BYTE
	MOV 36H, A
	RET	

;-----------------------------------------------
;HÀM SET_TIME
;HI?N TRUY?N GIÁ TR? C? Ð?NH VÔ 
;-----------------------------------------------
DS1307_SET_SECOND:
	mov B , A
	mov A, #DS1307_Second_Reg
	acall DS1307_WRITE_BYTE
	RET
	
;;-----------------------------------------------
DS1307_SET_MINUTES:
	mov B , A
	mov A, #DS1307_Minutes_Reg
	acall DS1307_WRITE_BYTE
	RET
	
;;-----------------------------------------------
DS1307_SET_HOURS:
	mov B , A
	mov A, #DS1307_Hours_Reg
	acall DS1307_WRITE_BYTE
	RET

;;-----------------------------------------------
DS1307_SET_DAY:
	mov B , A
	mov A, #DS1307_Day_Reg
	acall DS1307_WRITE_BYTE
	RET

;;-----------------------------------------------
DS1307_SET_DATE:
	mov B , A
	mov A, #DS1307_Date_Reg
	acall DS1307_WRITE_BYTE
	RET
	
;;-----------------------------------------------
DS1307_SET_MONTH:
	mov B , A
	mov A, #DS1307_Month_Reg
	acall DS1307_WRITE_BYTE
	RET	
	
;;-----------------------------------------------
DS1307_SET_YEAR:
	mov B , A
	mov A, #DS1307_Year_Reg
	acall DS1307_WRITE_BYTE
	RET
	
;-----------------------------------------------
; CONVERT_BCD_TO_ASCII
; Chuyển 1 byte BCD sang 2 ký tự ASCII (ví dụ: 0x45 -> '4', '5')
; Đầu vào: A chứa giá trị BCD
; Đầu ra: R5 = ASCII hàng chục, R6 = ASCII hàng đơn vị
;-----------------------------------------------
CONVERT_BCD_TO_ASCII:
	mov R3, #30h
	mov R4, #30h
	push ACC 
	anl A, #0fh
	orl A, R4
	mov R4, A
	pop ACC
	swap A
	anl A, #0fh
	orl A, R3
	mov R3, A
	ret

;........................................
;input : A (BCD)
;output : A (unsigned int)
;........................................
convert_BCD_TO_NUMBER:
    push ACC
    anl A, #0Fh
    mov 41H, A
    pop ACC
    swap A              
    anl A, #0Fh                        
    mov B, #10
    mul AB                
    add A, 41H  
    ret


;........................................
; Input: A ch?a decimal (VD: 25)
; Output: A = BCD (0x25)
;........................................
convert_NUMBER_TO_BCD:
    mov B, #10
    div AB
    swap A              
    anl A, #0F0h
    orl A, B            
    ret

;---------------------------------------------------
; DS1307_CHANGE_CLOCK_FORMAT
; Thay đổi định dạng hiển thị thời gian (12h/24h) của DS1307
; Input: C (bit). Nếu C = 0 -> định dạng 24h
;                   Nếu C = 1 -> định dạng 12h
; Output phụ: Nếu là 12h, bit 5 cho biết AM/PM:
;              0 = AM, 1 = PM → lưu vào B.1 để dùng bên ngoài
; Tóm lại: Hàm đã đọc được dữ liệu giờ (tùy chế độ) lưu vào thanh ghi,
; còn AM/PM thì dữ liệu đã được ghi vào thanh ghi B.1
; khi viết display thì cần viết thêm hàm display AM PM kiểm tra B.1
; Lưu ý: hàm này chỉ là hàm ĐỌC và CẬP NHẬT DỮ LIỆU chứ chưa phải là hàm hiển thị cuối cùng 
;---------------------------------------------------
DS1307_CHANGE_CLOCK_FORMAT:
    mov B.0, C     

    push ACC

    mov R0, DS1307_Hours_Reg
    acall DS1307_READ_BYTE      
    mov 40H, A                  

    mov C, B.0
    jnc CLOCK_24H_FORMAT        ; C = 0 => nh?y d?n d?nh d?ng 24h

CLOCK_12H_FORMAT:
    ; kiem tra xem gio mac dinh da la dinh dang 12h hay chua nhe bit 6 = 1
    mov A, 40H
    jb ACC.6, FORMAT_ALREDY_12H 
    
    ; chuyen tu dinh dang 24h sang 12h
    anl A, #00011111b 	; lay gia tri gio hien tai
    
    ; chuyen tu BCD sang thap phan
    push ACC
    acall convert_BCD_TO_NUMBER
    mov R1, A
    pop ACC
    
    ;truong hop dac biet
    cjne R1, #0, CHECK_FOR_12 ; khac 0, nhay vo dinh dang luon
    
    ;oo:xx => 12:xx AM
    mov A, #12
    acall convert_NUMBER_TO_BCD
    orl A, #01000000b       ; dinh dang 12h bit.6 = 1
    mov 40H, A
    clr B.1		    ; B.1 = 0 => AM
    jmp WRITE_BACK
    
    
CHECK_FOR_12:
    cjne R1, #12, CHECK_FOR_PM_OR_AM ; neu gio khac 12 nhay
    
    ;12:xx -> 12:xx PM
    mov A, #12
    acall convert_NUMBER_TO_BCD
    orl A, #01000000b    ; set bit 6 len 1 nha ae (12h)
    orl A, #00100000b	; set bit 5 len 1 (PM)
    mov 40H, A
    setb B.1	
    sjmp WRITE_BACK
    
    
CHECK_FOR_PM_OR_AM:
    clr C	 ; xoa co carry truoc khi tru
    mov A, R1
    subb A, #12       ;so sanh voi 12
    jc AM_SETTING       ; neu < 12 nhay vo thang loz nay
    
    
    ; > 12 (13:xx => 1:xx PM)
    add A, #0     ; clear carry flag gia tri khong doi chi setup C = 0
    ;clr C
    add A, #12      ; khong phuc lai gia tri ban dau
    subb A, #12     ; tru cho 12 de lay gio muon lay vi du: 13h -> 1h
    acall convert_NUMBER_TO_BCD
    orl A, #01000000b
    orl A, #00100000b
    mov 40H, A
    setb B.1
    sjmp WRITE_BACK
    
AM_SETTING: ;TH < 12
    mov A, R1
    acall convert_NUMBER_TO_BCD
    orl A, #01000000b
    anl A, #11011111b
    mov 40H, A
    clr B.1
    sjmp WRITE_BACK
    
    
FORMAT_ALREDY_12H:
    ; da la dinh dang 12h, kiem tra AM / PM
    anl A, #00100000b
    jz AM_CASE        
    
    setb B.1
    sjmp WRITE_BACK
    

AM_CASE:
    clr B.1                     ; Ghi nh?: B.1 = 0 ? AM
    sjmp WRITE_BACK

CLOCK_24H_FORMAT:
    mov A, 40H
    jnb ACC.6, FORMAT_ALREDY_24H
    
    
    ;chuyen 12h sang 24h
    ;lay gia tri gio
    anl A, #00011111b
    
    
    push ACC
    acall convert_BCD_TO_NUMBER
    mov R1, A
    pop ACC
    
    
    ;kiem tra bit PM bit = 0
    mov A, 40H
    jnb ACC.5, CHECK_FOR_12AM
    
    
    ; neu la PM cong them 12 tru truong hop 12h
    mov A, R1
    cjne A, #12, ADD_12_FOR_PM
    
    ;truong hop 12 PM => 12:00
    mov A, #12
    sjmp CONVERT_TO_24H
    
    
ADD_12_FOR_PM:
    mov A, R1
    add A, #12
    sjmp CONVERT_TO_24H
    
CHECK_FOR_12AM:
    mov A, R1
    cjne A, #12, CONVERT_TO_24H   ;kiem tra xem co phai 12AM khong
    
    ; 12AM -> 00
    mov A, #0
    anl A, #1011111b
    
CONVERT_TO_24H:
    acall convert_NUMBER_TO_BCD;
    anl A, #10111111b
    mov 40H, A
    clr B.1
    sjmp WRITE_BACK
    
    pop ACC
    anl A, #10111111b
    mov 40H, A
    clr B.1                     
    
    
FORMAT_ALREDY_24H:
    anl A, #10111111b
    mov 40H, A
    clr B.1

    
    
WRITE_BACK:
    mov R0, #DS1307_Hours_Reg
    mov A, 40H
    acall DS1307_WRITE_BYTE
   
    pop ACC
    ret    
	
;-----------------------------------------------
; DISPLAY_TIME_TO_LCD
; Hiển thị thời gian hiện tại lên LCD1602 ở hàng 1, cột 0
; Định dạng: HH:MM:SS
; mục đích của hàm này là sao? là dùng để gọi các hàm đã viết phía trên để trong hàm main chỉ cần gọi hàm DISPLAY_TIME_TO_LCD
; và thêm một số cái delay thì sẽ hiện giờ 
;-----------------------------------------------
DISPLAY_HOURS_TO_LCD:
	ACALL DS1307_GET_HOURS	 
	MOV A, 32H  ; hours
	ACALL CONVERT_BCD_TO_ASCII 
	MOV A, R3
	ACALL LCD1602_Send_Data	
	MOV A, R4
	ACALL LCD1602_Send_Data
	MOV A, #03Ah ; hienthi dau :
	ACALL LCD1602_Send_Data
	RET

DISPLAY_MINUTES_TO_LCD:
	ACALL DS1307_GET_MINUTES
	MOV A, 31H  ; minutes
	ACALL CONVERT_BCD_TO_ASCII 
	MOV A, R3
	ACALL LCD1602_Send_Data
	MOV A, R4
	ACALL LCD1602_Send_Data
	MOV A, #03Ah
	ACALL LCD1602_Send_Data
	RET

DISPLAY_SECONDS_TO_LCD:
	ACALL DS1307_GET_SECOND
	MOV A, 30H ; seconds
	anl A, #7fh
	ACALL CONVERT_BCD_TO_ASCII 
	MOV A, R3
	ACALL LCD1602_Send_Data
	MOV A, R4
	ACALL LCD1602_Send_Data
	RET

DISPLAY_DAY_TO_LCD:
	ACALL DS1307_GET_DAY     ; -> 33H
    MOV A, 33H       ; A = thứ (1..7)
    DEC A            ; Đổi về 0..6
	mov B, #4
	mul AB
	add A, #30h
	mov DPL, A
	mov DPH, #0
	acall LCD_SEND_STRING
	ret

DISPLAY_DATE_TO_LCD:
	ACALL DS1307_GET_DATE    ; -> 34H
    ACALL DS1307_GET_MONTH   ; -> 35H
    ACALL DS1307_GET_YEAR    ; -> 36H
	
	MOV A, 34H ; date
	ACALL CONVERT_BCD_TO_ASCII 
	MOV A, R3
	ACALL LCD1602_Send_Data
	MOV A, R4
	ACALL LCD1602_Send_Data
	MOV A, #02Fh
	ACALL LCD1602_Send_Data
	
	
	MOV A, 35H ; month
	ACALL CONVERT_BCD_TO_ASCII 
	MOV A, R3
	ACALL LCD1602_Send_Data
	MOV A, R4
	ACALL LCD1602_Send_Data
	MOV A, #02Fh
	ACALL LCD1602_Send_Data
	
	
	MOV A, 36H ; year
	ACALL CONVERT_BCD_TO_ASCII 
	MOV A, R3
	ACALL LCD1602_Send_Data
	MOV A, R4
	ACALL LCD1602_Send_Data
	
	RET

DISPLAY_TIME_TO_LCD:
	MOV R0, #0
	MOV R1, #0
	ACALL LCD_SETCURSOR
	ACALL DISPLAY_DATE_TO_LCD
	MOV R0, #0
	MOV R1, #13
	ACALL LCD_SETCURSOR
	ACALL DISPLAY_DAY_TO_LCD

	MOV R0, #1
	MOV R1, #0
	ACALL LCD_SETCURSOR
	ACALL DISPLAY_HOURS_TO_LCD
	ACALL DISPLAY_MINUTES_TO_LCD
	ACALL DISPLAY_SECONDS_TO_LCD
	RET

DEC_HOUR:
	mov A, 36h
	acall convert_BCD_TO_NUMBER
	cjne A, #0, reset_hour
	dec A
	acall convert_NUMBER_TO_BCD
	acall DS1307_SET_HOURS
	ret
	reset_hour:
	mov A, #23h
	acall DS1307_SET_HOURS
	ret
	
INC_HOUR:
	mov A, 36h
	acall convert_BCD_TO_NUMBER
	cjne A, #23, set_hour
	inc A
	acall convert_NUMBER_TO_BCD
	acall DS1307_SET_HOURS
	ret
	set_hour:
	mov A, #0h
	acall DS1307_SET_HOURS
	ret
	

CHECK_ENCODER:
	mov A, P2
	anl A, #03h ; chi lay 2 bit cuoi

	encoder_high:
	cjne A, #3, encoder_clock
	; truong hop encoder dang o trang thai high
	mov 37h, A ; luu lai trang thai cua encoder
	ret 
	
	encoder_clock:
	; trang hop encoder thay doi trang thai
	cjne A, 37h, handle_signal
	ret ; truong hop da xu ly tin hieu
	
	handle_signal:
	clr EA
	push ACC
	rl A ; A << 1
	rl A ; A << 1
	orl A, 37h ; A (curr) or (prev)
	cjne A, #07h, check_left
	sjmp right
	check_left:
	cjne A, #0bh, no_change
	sjmp left
	
	left:
	acall ENCODER_LEFT
	sjmp done_encoder
	right:
	acall ENCODER_RIGHT
	sjmp done_encoder
	
	no_change:
	pop ACC
	mov 37h, A
	setb EA
	ret
	
	done_encoder:
	pop ACC
	mov 37h, A
	acall DISPLAY_TIME_TO_LCD
	setb EA
	ret

ENCODER_RIGHT:
	mov A, 38h
	cjne A, #0ffh, case_inc_min
	ret
	case_inc_min:
	cjne A, #31h, case_inc_hour
	mov A, #1
	acall ADJUST_MINUTE
	ret
	
	case_inc_hour:
	cjne A, #32h, case_inc_day
	mov A, #1
	acall ADJUST_HOUR
	ret

	case_inc_day:
	cjne A, #33h, case_inc_date
	mov A, #1 
	acall ADJUST_DAY
	ret
	
	case_inc_date:
	cjne A, #34h, case_inc_month
	mov A, #1
	acall ADJUST_DATE
	ret
	
	case_inc_month:
	cjne A, #35h, case_inc_year
	mov A, #1
	acall ADJUST_MONTH
	ret
	
	case_inc_year:
	mov A, #1
	acall ADJUST_YEAR
	ret
	
ENCODER_LEFT:
	mov A, 38h
	cjne A, #0ffh, case_dec_min
	ret
	
	case_dec_min:
	cjne A, #31h, case_dec_hour
	mov A, #0
	acall ADJUST_MINUTE
	ret
	
	case_dec_hour:
	cjne A, #32h, case_dec_day
	mov A, #0
	acall ADJUST_HOUR
	ret

	case_dec_day:
	cjne A, #33h, case_dec_date
	mov A, #0 
	acall ADJUST_DAY
	ret
	
	case_dec_date:
	cjne A, #34h, case_dec_month
	mov A, #0
	acall ADJUST_DATE
	ret
	
	case_dec_month:
	cjne A, #35h, case_dec_year
	mov A, #0
	acall ADJUST_MONTH
	ret
	
	case_dec_year:
	mov A, #0
	acall ADJUST_YEAR
	ret
	ret

;-----------------------------------------------
; ADJUST_MINUTE: Tăng giảm phút
; A = 0 -> Giảm
; A = 1 -> Tăng
;-----------------------------------------------
ADJUST_MINUTE:
    CJNE    A, #1, DECREASE     ; nếu A != 1 thì nhảy đến giảm

;----- TĂNG PHÚT -----
INCREASE:
    MOV     A, 31h           ; A = phút hiện tại
	acall convert_BCD_TO_NUMBER
    CJNE    A, #59, INC_MIN_NEXT    ; nếu A != 59 thì tăng
    CLR     A                   ; nếu A == 59 thì đặt lại 0
    SJMP    STORE_MINUTE
INC_MIN_NEXT:
    INC     A                   ; tăng A
    SJMP    STORE_MINUTE

;----- GIẢM PHÚT -----
DECREASE:
    MOV     A, 31h           ; A = phút hiện tại
	acall convert_BCD_TO_NUMBER
    CJNE    A, #0, DEC_MIN_NEXT     ; nếu A != 0 thì giảm
    MOV     A, #59              ; nếu A == 0 thì đặt lại 59
    SJMP    STORE_MINUTE
DEC_MIN_NEXT:
    DEC     A                   ; giảm A

;----- LƯU KẾT QUẢ -----
STORE_MINUTE:
	acall convert_NUMBER_TO_BCD
    MOV     31h, A           ; lưu lại phút đã cập nhật
	acall DS1307_SET_MINUTES
    RET

;-----------------------------------------------
; ADJUST_HOUR: Tăng giảm giờ
; A = 0 -> Giảm
; A = 1 -> Tăng
;-----------------------------------------------
ADJUST_HOUR:
    CJNE    A, #1, DECREASE_HOUR    ; nếu A != 1 thì nhảy đến giảm

;----- TĂNG GIỜ -----
INCREASE_HOUR:
    MOV     A, 32h                 ; A = giờ hiện tại
	acall convert_BCD_TO_NUMBER
    CJNE    A, #23, INC_HOUR_NEXT   ; nếu A != 23 thì tăng
    CLR     A                       ; nếu A == 23 thì đặt lại 0
    SJMP    STORE_HOUR
INC_HOUR_NEXT:
    INC     A                       ; tăng A
    SJMP    STORE_HOUR

;----- GIẢM GIỜ -----
DECREASE_HOUR:
    MOV     A, 32h                 ; A = giờ hiện tại
	acall convert_BCD_TO_NUMBER
    CJNE    A, #0, DEC_HOUR_NEXT    ; nếu A != 0 thì giảm
    MOV     A, #23                  ; nếu A == 0 thì đặt lại 23
    SJMP    STORE_HOUR
DEC_HOUR_NEXT:
    DEC     A                       ; giảm A

;----- LƯU KẾT QUẢ -----
STORE_HOUR:
	acall convert_NUMBER_TO_BCD
    MOV     32h, A                 ; lưu lại giờ đã cập nhật
	acall DS1307_SET_HOURS
    RET

;-----------------------------------------------
; ADJUST_DAY: Tăng giảm thứ
; A = 0 -> Giảm
; A = 1 -> Tăng
;-----------------------------------------------
ADJUST_DAY:
    CJNE    A, #1, DECREASE_DAY     ; nếu A != 1 thì nhảy đến giảm

;----- TĂNG THỨ -----
INCREASE_DAY:
    MOV     A, 33h                  ; A = giá trị thứ hiện tại
	acall convert_BCD_TO_NUMBER
    CJNE    A, #7, INC_DAY_NEXT     ; nếu A != 7 thì tăng
    MOV     A, #1                   ; nếu A == 7 thì quay về Chủ nhật (1)
    SJMP    STORE_DAY
INC_DAY_NEXT:
    INC     A
    SJMP    STORE_DAY

;----- GIẢM THỨ -----
DECREASE_DAY:
    MOV     A, 33h
	acall convert_BCD_TO_NUMBER
    CJNE    A, #1, DEC_DAY_NEXT     ; nếu A != 1 thì giảm
    MOV     A, #7                   ; nếu A == 1 thì quay về Thứ bảy (7)
    SJMP    STORE_DAY
DEC_DAY_NEXT:
    DEC     A

;----- LƯU KẾT QUẢ -----
STORE_DAY:
	acall convert_NUMBER_TO_BCD
    MOV     33h, A
	acall DS1307_SET_DAY
    RET

;-----------------------------------------------
; ADJUST_DATE: Tăng giảm ngày
; A = 0 -> Giảm
; A = 1 -> Tăng
;-----------------------------------------------
ADJUST_DATE:
    CJNE    A, #1, DECREASE_DATE     ; nếu A != 1 thì giảm

;----- TĂNG NGÀY -----
INCREASE_DATE:
    MOV     A, 34h
	acall convert_BCD_TO_NUMBER
    CJNE    A, #31, INC_DATE_NEXT   ; nếu chưa phải 31 thì tăng
    MOV     A, #1                   ; nếu là 31 thì quay về 1
    SJMP    STORE_DATE
INC_DATE_NEXT:
    INC     A
    SJMP    STORE_DATE

;----- GIẢM NGÀY -----
DECREASE_DATE:
    MOV     A, 34h
	acall convert_BCD_TO_NUMBER
    CJNE    A, #1, DEC_DATE_NEXT    ; nếu chưa phải 1 thì giảm
    MOV     A, #31                  ; nếu là 1 thì quay về 31
    SJMP    STORE_DATE
DEC_DATE_NEXT:
    DEC     A

;----- LƯU KẾT QUẢ -----
STORE_DATE:
	acall convert_NUMBER_TO_BCD
    MOV     34h, A
	acall DS1307_SET_DATE
    RET

;-----------------------------------------------
; ADJUST_MONTH: Tăng giảm tháng
; A = 0 -> Giảm
; A = 1 -> Tăng
;-----------------------------------------------
ADJUST_MONTH:
    CJNE    A, #1, DECREASE_MONTH     ; nếu A != 1 thì giảm

;----- TĂNG THÁNG -----
INCREASE_MONTH:
    MOV     A, 35h
	acall convert_BCD_TO_NUMBER
    CJNE    A, #12, INC_MONTH_NEXT   ; nếu chưa phải tháng 12 thì tăng
    MOV     A, #1                    ; nếu là 12 thì quay về 1
    SJMP    STORE_MONTH
INC_MONTH_NEXT:
    INC     A
    SJMP    STORE_MONTH

;----- GIẢM THÁNG -----
DECREASE_MONTH:
    MOV     A, 35h
	acall convert_BCD_TO_NUMBER
    CJNE    A, #1, DEC_MONTH_NEXT    ; nếu chưa phải tháng 1 thì giảm
    MOV     A, #12                   ; nếu là 1 thì quay về 12
    SJMP    STORE_MONTH
DEC_MONTH_NEXT:
    DEC     A

;----- LƯU GIÁ TRỊ -----
STORE_MONTH:
	acall convert_NUMBER_TO_BCD
    MOV     35h, A
	acall DS1307_SET_MONTH
    RET

;-----------------------------------------------
; ADJUST_YEAR: Tăng giảm năm
; A = 0 -> Giảm
; A = 1 -> Tăng
;-----------------------------------------------
ADJUST_YEAR:
    CJNE    A, #1, DECREASE_YEAR     ; nếu A != 1 thì giảm

;----- TĂNG NĂM -----
INCREASE_YEAR:
    MOV     A, 36h
	acall convert_BCD_TO_NUMBER
    CJNE    A, #99, INC_YEAR_NEXT    ; nếu chưa tới 99 thì tăng
    MOV     A, #0                    ; nếu là 99 thì quay về 0
    SJMP    STORE_YEAR
INC_YEAR_NEXT:
    INC     A
    SJMP    STORE_YEAR

;----- GIẢM NĂM -----
DECREASE_YEAR:
    MOV     A, 36h
	acall convert_BCD_TO_NUMBER
    CJNE    A, #0, DEC_YEAR_NEXT     ; nếu chưa là 0 thì giảm
    MOV     A, #99                   ; nếu là 0 thì quay về 99
    SJMP    STORE_YEAR
DEC_YEAR_NEXT:
    DEC     A

;----- LƯU GIÁ TRỊ -----
STORE_YEAR:
	acall convert_NUMBER_TO_BCD
    MOV     36h, A
	acall DS1307_SET_YEAR
    RET

BUTTON_HANDLER:
	mov A, 38h
	cjne A, #31h, case_hour
	mov 38h, #32h
	mov R0, #1
	mov R1, #0
	acall LCD_SETCURSOR
	ret
	
	case_hour:
	cjne A, #32h, case_day
	mov 38h, #33h
	mov R0, #0
	mov R1, #13
	acall LCD_SETCURSOR
	ret
	
	case_day:
	cjne A, #33h, case_date
	mov 38h, #34h
	mov R0, #0
	mov R1, #0
	acall LCD_SETCURSOR
	ret
	
	case_date:
	cjne A, #34h, case_month
	mov 38h, #35h
	mov R0, #0
	mov R1, #3
	acall LCD_SETCURSOR
	ret
	
	case_month:
	cjne A, #35h, case_year
	mov 38h, #36h
	mov R0, #0
	mov R1, #6
	acall LCD_SETCURSOR
	ret
	
	case_year:
	cjne A, #36h, case_default
	mov 38h, #0ffh
	acall RESET_CURSOR_BLINK
	acall START_RTC
	ret
	
	case_default:
	mov 38h, #31h 
	acall STOP_RTC
	acall SET_CURSOR_BLINK
	mov R0, #1
	mov R1, #3
	acall LCD_SETCURSOR
	ret 
	

STOP_RTC:
	mov A, 30h
	orl A, #80h
	acall DS1307_SET_SECOND
	ret

START_RTC:
	mov A, 30h
	anl A, #7fh
	acall DS1307_SET_SECOND
	ret

SET_CURSOR_BLINK:
	mov A, #0fh
	acall LCD1602_Send_Ins
	ret 
	
RESET_CURSOR_BLINK:
	mov A, #0ch
	acall LCD1602_Send_Ins
	ret
	

end

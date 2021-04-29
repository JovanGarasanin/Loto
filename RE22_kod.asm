; Template

.386
.model flat, stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword

INCLUDE Irvine32.inc
INCLUDE macros.inc


COMMENT &//----------Konstante  &
.const
ArrayLength = 7
;Definisanje velicine prozora: leva,desna,gornja,donja ivica
xmin = 0
xmax = 45
ymin = 0
ymax = 14
;oznake karaktera
esc_key = 01Bh
enter_key = 65h
space_key = 32


.data
	selected byte 1 ;odabrani redni broj broja
	used byte 00000000b
	windowRect small_rect <xmin,ymin,xmax, ymax>
	des byte 0
	jed byte 0
	cif byte 0
	cifra byte 0
	
	br byte 4
	deset byte 10
	brojacp byte 0
	
;naziv programa	
	winTitle byte "LOTO", 0
;info o polozaju kursora
	cursorInfo console_cursor_info <>

T1 byte " ",0dh,0ah,0
T2 byte " _          __________    ___________  ___________ ",0dh,0ah,0
T3 byte "| |        /  _______  \ |____   ____|/  _______  \",0dh,0ah,0
T4 byte "| |        | |       | |      | |     | |       | |",0dh,0ah,0
T5 byte "| |_______ | |_______| |      | |     | |_______| |",0dh,0ah,0
T6 byte "|_________|\___________/      |_|     \___________/",0dh,0ah,0
T7 byte "              PRESS ENTER TO START                 ",0dh,0ah,0
T8 byte "              PRESS ESCAPE TO EXIT                 ",0dh,0ah,0
T9 byte "GOODBYE!",0dh,0ah,0
T10 byte "Los unos, pokusajte ponovo",0dh, 0ah, 0
T11 byte "Unesite zeljene brojeve (1-39): ",0dh, 0ah, 0
T12 byte "                                        ",0dh, 0ah, 0
T13 byte "Da li zelite da igrate ponovo? (y/n)",0dh, 0ah, 0
T14 byte "LOTO",0dh, 0ah, 0
T15 byte "Broj vasih pogodaka:",0dh, 0ah, 0
T16 byte "Brojeve odvojiti razmakom (space)",0dh, 0ah, 0

welcomeDelay dword 100
exitDelay dword 3000
.data?
	numbas byte 8 dup (?)
	numarr byte 8 dup (?)
	stdOutHandle handle ?
	stdInHandle handle ?
	bytesRead dword ?
	
	ar byte ?
	yp byte ?
	rbr byte ?
	flg byte ?
.code


;randNum returns eax = random number(1- numRange)
randNum proc,
	numRange: dword
		call Randomize
		mov eax, numRange
		call randomRange
		inc eax
		ret
randNum endp

;stampanje odabranih brojeva
outUnos proc 

	push edx
	push edi
	push esi
	push ebx

	push eax
	mov eax, black + (lightGray * 16)
	call SetTextColor
	mov dl, cl
	mov dh, 3
	call gotoxy
	pop eax
	call writechar
	sub al, 48

	pop ebx
	pop esi
	pop edi
	pop edx

	ret
outUnos endp


 ;stampanje izvucenih brojeva

outUnos2 proc
	push edx
	push edi
	push esi
	push ebx

	push eax
	mov eax, black + (yellow * 16)
	call SetTextColor
	mov dl, cl
	mov dh, 6
	call gotoxy
	pop eax
	call writechar
	sub al, 48

	pop ebx
	pop esi
	pop edi
	pop edx

	ret
outUnos2 endp

 ;stampanje pogodjenih brojeva
outUnos3 proc

	push edx
	push edi
	push esi
	push ebx
	
	xchg eax, ecx
	mul br
	inc eax
	xchg ecx, eax 

	push eax
	mov eax, yellow + (green * 16)
	call SetTextColor
	mov dl, cl
	mov dh, 3
	call gotoxy
	mov ax, space_key
	call writechar

	pop eax
	
	div deset
	
	xchg eax, ecx
	mul br
	add eax, 2
	xchg eax, ecx
	add al, 48
	.if(al==48)
		jmp jdn
	.endif
	push ecx
	call writechar
	pop ecx
	jdn:
		xchg al, ah
	add al, 48
	inc ecx
	push ecx
	call writechar
	pop ecx
	xchg al, ah
	.if(al==48)
		inc ecx
		mov ax, space_key
		call writechar
	.endif

	pop ebx
	pop esi
	pop edi
	pop edx

	ret
outUnos3 endp

;stampanje promasenih brojeva
outUnos4 proc 

	push edx
	push edi
	push esi
	push ebx
	
	xchg eax, ecx
	mul br
	inc eax
	xchg ecx, eax 

	push eax
	mov eax, yellow + (red * 16)
	call SetTextColor
	mov dl, cl
	mov dh, 3
	call gotoxy
	mov ax, space_key
	call writechar

	pop eax
	
	div deset
	
	xchg eax, ecx
	mul br
	add eax, 2
	xchg eax, ecx
	add al, 48
	.if(al==48)
		jmp jdn
	.endif
	push ecx
	call writechar
	pop ecx
	jdn:
		xchg al, ah
	add al, 48
	inc ecx
	push ecx
	call writechar
	pop ecx
	xchg al, ah
	.if(al==48)
		inc ecx
		mov ax, space_key
		call writechar
	.endif

	pop ebx
	pop esi
	pop edi
	pop edx

	ret
outUnos4 endp


;Inicjalizuje nasumicne brojeve potrebne za igru i stampanje istih u rastucem poretku
initNum proc,


	push edx
	push edi
	push esi
	push ecx
	push ebx
	
	mov ebx, 0
	mov ecx, 7
	mov edx, 1
	L1: ;inicijalizacija niza slucajno odabranih brojeva
		mov eax, 1

		call Delay
		invoke randNum, 39
			mov bl, dl
			.while (bl!=0)
				.if (numarr[ebx] == al)
					jmp L1
				.endif
				dec bl
			.endw
		
		mov numarr[edx], al

		inc edx
		loop L1
	mov ecx, 7
	mov edx, 1

	L2: ;redjanje niza u rastucem poretku
		mov al, numarr[edx]
		mov bl, dl
		inc bl
		push ecx
		mov ecx, 0
		.while ( bl <  8) 
			.if (al > numarr[ebx])
				mov al, numarr[ebx]
				mov cl, bl
			.endif
			inc bl
		.endw
		xchg numarr[edx], al
		mov numarr[ecx], al
		inc edx
		pop ecx
	loop L2
	
	
	mov ecx, 7
	L3: ;petlja za stampanje 
		.if (numarr[ecx]>9)
			mov eax, 0
			mov al, numarr[ecx]
			div deset
			push ecx
			xchg eax, ecx
			mul br
			add eax, 2
			xchg eax, ecx
			add al, 48
			invoke outUnos2	
			mov al, ah
			inc ecx
			add al, 48
			invoke outUnos2
			pop ecx
		.elseif
			mov eax, 0
			mov al, numarr[ecx]
			push ecx
			xchg eax, ecx
			mul br
			add eax, 2
			xchg eax, ecx
			add al, 48
			invoke outUnos2
			pop ecx
		.endif
	loop L3


	pop ebx	
	pop ecx
	pop esi
	pop edi
	pop edx
	ret
initNum endp


kvadratOboji PROC, ;bojenje praznih kvadrata
		xpos:  BYTE,
		ypos:  BYTE,
		xsize: BYTE,
		ysize: BYTE,
		color: BYTE 
	
	push edx
	push edi
	push esi
	push ebx
	push ecx
	push eax

colorL:
	mov al, color
	.if (al==1)
		jmp crvena
	.elseif (al==2)
		jmp zelena
	.elseif (al==3)
		jmp crna
	.elseif (al==4)
		jmp bela
	.elseif (al==5)
		jmp siva
	.elseif (al==6)
		jmp plava
	.elseif (al==7)
		jmp zuta
	.endif
	loop colorL

crvena:
	mov eax, red
	mov ecx, 16
	mul ecx
	add eax, blue
	jmp crtaj
zelena:
	mov eax, green
	mov ecx, 16
	mul ecx
	add eax, blue
	jmp crtaj
crna:
	mov eax, black
	mov ecx, 16
	mul ecx
	add eax, lightGray
	jmp crtaj
bela:
	mov eax, white
	mov ecx, 16
	mul ecx
	add eax, green
	jmp crtaj
siva:
	mov eax, lightGray
	mov ecx, 16
	mul ecx
	add eax, black
	jmp crtaj
plava:
	mov eax, blue
	mov ecx, 16
	mul ecx
	add eax, white
	jmp crtaj
zuta:
	mov eax, yellow
	mov ecx, 16
	mul ecx
	add eax, black
	jmp crtaj

crtaj: 

	call SetTextColor			;// Podesavanje boje teksta
	mov  dl, xpos				;// x pozicija kursora
	mov  dh, ypos				;// y pozicija kursora
	mov	bl, ysize				;// y pozicija kvadrata koja govori o tome da je gotovo crtanje
	add bl, dh
	mov bh, 061h
	movsx ecx, xsize			;// broj prolazaka kroz petlju
	mov al, 0DBh
	jmp xinc					;// skok na labelu za crtanje kvadrata

xinc:
	call gotoxy
	mov al, 20h
	call writechar
	inc dl
	loop xinc
	movsx ecx, xsize	

xdec:
	dec dl
	loop xdec

yinc:
	movsx ecx, xsize
		inc dh
		cmp bl, dh
		jne xinc

		mov ax, white
		call SetTextColor
		pop eax
		pop ecx
		pop ebx
		pop esi
		pop edi
		pop edx
		ret
kvadratOboji ENDP 

;provera tastera



numbaKvadrat PROC, ;bojenje praznih mesta
		xposb : byte,
		yposb : byte,
		xsize : byte,
		ysize : byte,
		xpost : byte,
		ypost : byte,
		isSelected : byte,
		inUse : byte,
		col : byte
		push edx

		
		INVOKE kvadratOboji, xposb, yposb, xsize, ysize, col


		pop edx
	ret
numbaKvadrat ENDP

 ;Proverava da li je selektovano to polje
CheckIfSelected PROC,
		Num : BYTE,
		Masked : BYTE
	mov al, Num
	sub al, Masked
	jnz isselected
	mov eax, 1
	jmp end_l
isselected :
	mov eax, 0
end_l :
		ret
CheckIfSelected ENDP


InitOutput PROC,
		Arr: PTR WORD,
		UsedNum: BYTE,
		gd :byte,
		color : byte
		
	push edx
	push ebx



	INVOKE GetStdHandle, STD_OUTPUT_HANDLE				;// Postavlja handle za ispis podataka
	mov  stdOutHandle, eax

	INVOKE SetConsoleWindowInfo, stdOutHandle, TRUE, addr windowRect;// Dimenzije prozora

	INVOKE GetConsoleCursorInfo, stdOutHandle, ADDR cursorInfo		;// Cita trenutno stanje kursora
	mov  cursorInfo.bVisible, 0										;// Postavlja vidljivost kursora na nevidljiv
	INVOKE SetConsoleCursorInfo, stdOutHandle, ADDR cursorInfo		;// Postavlja novo stanje kursora

	mov al, 1
	cmp al, gd
	je gore
	mov yp, 6
	jmp dalje
	gore:
		mov yp, 3
	dalje:


	mov esi, Arr

	mov ecx, 7
	

	.while(ecx>0)
		unosL:
		mov ar, 8
		sub ar, cl
		mov al, ar
		mul br
		mov ar, al
		add ar, 1
		INVOKE numbaKvadrat, ar, yp, 3, 1, 6, 3, dl, bh, color
		inc esi
		dec ecx
	.endw


	mov ax, white
	call SetTextColor
	mov  dl, 5
	mov  dh, 8
	call gotoxy

	pop ebx
	pop edx
	ret
InitOutput ENDP



unos proc

	push edx
	push edi
	push esi
	push ebx
	push ecx
	push eax

	petljacif: 
		
		;	bojenje selektovanog polja - kursora	;
						
		mov al, selected	
		mul br					
		add al, 2
		mov cl, al					
		push ecx						 
		invoke kvadratOboji, al, 3, 1, 1, 6 
		
		call ReadChar
		pop ecx		
		.if (al<49)||(al>57)		;proverava da li je unesen broj, a ne neki drugi znak
			jmp losUnos				;	prva cifra ne moze da bude 0
		.endif

		invoke outUnos			;stampanje unete cifre
		inc cl
		push eax
		invoke kvadratOboji, cl, 3, 1, 1, 6 ;dovde
		pop eax
		push ecx

		mov cif, al
		mov jed, al				;mov al, cif smestanje druge cifre u jed
		
		mov dl, 0
		mov dh, 4
		call gotoxy
		mov edx, offset T12
		call WriteString
		pop ecx
		.if (cif>3)					 ;ako je cifra >3 broj ne moze biti dvocifren, mora da sledi razmak
						
			call ReadChar
			push eax
			invoke kvadratOboji, cl, 3, 1, 1, 5 ;dovde
			pop eax
			.if (al!= space_key) ;proverava da li je razmak/kraj unosa
				jmp losUnos
			.endif
			jmp spejs
		.endif
		
		

		call ReadChar
		
		.if (al==space_key) ;proverava da li je razmak/kraj unosa
			invoke kvadratOboji, cl, 3, 1, 1, 5
			jmp spejs
		.endif
		
		.if (al>57)||(al<48) ;proverava da li je unesen broj, a ne neki drugi znak
			jmp losUnos		;sme da bude i 0
		.endif
		
		invoke outUnos ;stampanje unete cifre
		push ecx
		xchg jed, al
		mov des, al
		
		call ReadChar
		pop ecx
		.if (al!=space_key)
			jmp losUnos
		.endif

		jmp spejs

	losUnos:
		
		mov al, cl
		invoke kvadratOboji, al, 3, 1, 1, 5
		
		
		mov des, 0
		mov jed, 0
		
		mov dl, 6
		mov dh, 4
		call gotoxy
		mov edx, offset T10
		call WriteString
		
		jmp petljacif


	spejs: ;zavrsetak unosa jednog broja
		mov al, des
		mov edx, 10
		mul edx
		add al, jed
		
		mov dl, selected
		.while dl!=0
			.if (numbas[edx] == al)
				jmp losUnos
			.endif
			dec dl
		.endw

		mov cl, selected
		mov numbas[ecx], al ;upisivanje u niz
	
		mov des, 0
		mov jed, 0
		inc selected

		.if (selected<8)
			jmp petljacif
		.endif
	
	pop eax
	pop ecx
	pop ebx
	pop esi
	pop edi
	pop edx

	ret

unos endp

provera proc ;provera i oznacavanje pogodaka/promasaja
	push edx
	push edi
	push esi
	push ebx
	push ecx
	push eax
	
	mov ecx, 7
	
	l1:
		mov ebx, 7
		mov eax, 0
		mov al, numbas[ecx]
		.while (ebx > 0) 
			
			.if (al==numarr[ebx])
				jmp dobar
			.elseif
				dec ebx
			.endif
		.endw
		jmp los

	dobar:
		inc brojacp
		mov al, numbas[ecx]
		push ecx
		call outUnos3 ;stampanje dvocifrenih br
		pop ecx
		dec ecx ; ekvivalent loop l1
		cmp ecx, 0
		je ende
		jmp l1 ;
	los:
		push ecx
		call outUnos4
		pop ecx
	loop l1
	ende:
	call Results

	pop eax
	pop ecx
	pop ebx
	pop esi
	pop edi
	pop edx

	ret

provera endp


StartGame PROC  ;start igre
loop1:

	call clrscr

		mov  dl, 15
		mov  dh, 1
		call gotoxy


	mov edx, offset T14

	call WriteString


		mov  dl, 3
		mov  dh, 2
		call gotoxy


	mov edx, offset T11

	call WriteString


	
	INVOKE InitOutput, OFFSET numbas, Used, 1, 5 ;iscrtavanje praznih polja za unos zeljenih brojeva 

		mov  dl, 2
		mov  dh, 5
		call gotoxy


	mov edx, offset T16

	call WriteString


	call unos

	INVOKE InitOutput, OFFSET numbas, Used, 0, 7 ;iscrtavanje praznih polja za unos izvucenih brojeva 
		mov  dl, 1
		mov  dh, 5
		call gotoxy


	mov edx, offset T12

	call WriteString


	call initNum
	
	call provera

	
	call playAgainCheck
jmp loop1
ret
StartGame ENDP

welcomeScreen proc ;pocetni ekran

mov eax, green + (black*16)
call SetTextColor

mov edx, offset T1
call WriteString
mov eax, welcomeDelay
call delay

mov edx, offset T2
call WriteString
mov eax, welcomeDelay
call delay

mov edx, offset T3
call WriteString
mov eax, welcomeDelay
call delay
mov ecx, 4
isto:
	mov edx, offset T4
	call WriteString
	mov eax, welcomeDelay
	call delay
	loop isto
mov edx, offset T5
call WriteString
mov eax, welcomeDelay
call delay

mov edx, offset T6
call WriteString
mov eax, welcomeDelay
call delay


mov edx, offset T1
call WriteString
mov eax, welcomeDelay
call delay


mov edx, offset T7
call WriteString
mov eax, welcomeDelay
call delay



mov edx, offset T8
call WriteString
mov eax, welcomeDelay
call delay

petlja:
	call ReadChar

	cmp al, 01Bh
	je exitP
	cmp al, 0dh
	je StartGame
	jmp petlja


ret
welcomeScreen endp

playAgainCheck PROC ;igraj ispocetka
	
	mov eax, 0
	mov al, green
	mov ah,black
	call setTextColor

	mov ecx, 8
	loop1:
		mov numbas[ecx], 0
		mov numarr[ecx], 0
	loop loop1
	
	
	mov  dl, 1
	mov  dh, 1
	call gotoxy
	mov edx, offset T12
	call writestring

	mov  dh, 2
	call gotoxy
	mov edx, offset T12
	call writestring

	mov  dl, 1
	mov  dh, 1
	call gotoxy

	mov edx, offset T13
	call WriteString


l:
	call ReadChar
	cmp al, 'y'
	je StartGame
	cmp al, 'n'
	je exitP
jmp l


ret
playAgainCheck ENDP

Results PROC

mov dl, 7
mov dh, 8
call gotoxy

mov edx, offset T15
mov eax, 0
mov eax, red + (black * 16)
call setTextColor
call WriteString
mov dl, 28
mov dh, 8
call gotoxy
mov al, brojacp
add al, 48
call writechar

mov eax, 0
mov ebx, 0
mov edx, 0
mov edi, 0
mov esi, 0
mov ecx, 7
loop1:
	mov numbas[ecx], 0
	mov numarr[ecx], 0
	loop loop1
mov ecx, 0
mov selected, 1
mov des, 0
mov jed, 0
mov cif, 0
mov cifra, 0
mov br, 4
mov deset, 10
mov brojacp, 0


ret
Results ENDP

exitP proc ;procedura za izlaz
	
call clrscr


	mov  dl, 20
	mov  dh, 6
	call gotoxy



mov edx, offset T9
call WriteString
mov eax, exitDelay
call delay




INVOKE ExitProcess, 0

exitP endp

main proc ;glavni program
	INVOKE SetConsoleTitle, addr winTitle							;// Postavlja title prozora


	invoke welcomeScreen

main endp
END main
assume cs:code
;--Segment danych---
data segment
help 		db "Sposob wywolania: merge [-h] {-i plik wejsciowy} [-o plik wyjsciowy] [-t znak rozdzielajacy], domyslnie znakiem rozdzielajacym jest spacja",10,13,'$'
in_file_err db "Brak pliku wejściowego",10,13,'$'
syntax_err  db "Zla skladnia",10,13,'$'
file_err    db "Blad obslugi plikow, kod  ",10,13,'$'
unknown_err db "Blad",10,13,'$'
endline		db 13,10,'$'
parse_err	db 0
merg_char	db ' '
dif_char	db '$'
cmd_len 	dw 0 ; dlugosc lini komend
i_file_numb	db 0
o_file_numb db 0
input_file 	dw ? ; uchwyty do plikow
output_file dw ?
bool_ended	db 255 dup(0)
in_ended	db 0
pointerdx 	dw	100 dup(0)	;	tutaj będą części młodsze adresów koncow wierszy w plikach, do ktorych na razie doszlismy
pointercx 	dw	100	dup(0)	;	a tutaj starsze
input_names db 255 dup(0)
output_name db 255 dup(0)
read_buffer	db 255 dup('$')
debug_string db ?
current_name dw ?
debug		db 0
null		db ?

data ends
;--Stos programu--
stos1 segment stack
	dw	250 dup(?)
w_stosu	dw	?
stos1 ends
;--Kod programu--
;-----------------Proste makra--
printS macro of ;wypisanie znaków z pamięci w segmencie ds, od offsetu ww
	mov dx,of
	mov ah,9
	int 21h
	endm
;-----------------Wypisz znak do pliku wyjsciowego, w cx napisz ile :p
printF macro xx
	mov dx,xx
	mov bx,output_file
	mov ah,40h
	int 21h
	endm
	;---------------Otwarcie pliku wejsciowego
openInFile macro xx
	mov dx,xx
	mov ah,3Dh
	mov al,0
	int 21h
	mov ds:[file_err+25],'i'
	mov input_file,ax
	call files_error
	endm
;---------------Otwarcie pliku wyjściowego
openOutFile macro xx
	mov dx,xx
	mov ah,3Ch
	int 21h
	mov ds:[file_err+25],'o'
	call files_error
	mov output_file,ax
	endm
;--------------Zamykanie plikow
closeFile macro xx
	mov bx,xx
	mov ah,3Eh
	int 21h
	mov ds:[file_err+25],'c'
	call files_error
	endm
;-------------Przesuwanie wskaznika
fpoint macro xx 
			push di
			mov	di,xx
			shl	di,1
			mov	dx,word ptr ds:[pointerdx+di]
			mov	cx,word ptr ds:[pointercx+di]
			mov	ah,042H
			mov	bx,input_file
			mov	al,00H	;	miejsce w pliku liczone od początku
			int 21h
			pop di
			mov ds:[file_err+25],'m'
			call files_error
	endm
code segment

;---------------------Procedury----------------
;----------chwilowa procedura sprawdzenia parsera
parse_check proc
	mov dh,0
	mov dl,o_file_numb
	add dl,48
	mov ah,2
	int 21h
	mov cl,20
	mov si,offset output_name
	xor dh,dh
	pCheckLoop:
		mov dl,byte ptr ds:[si]
		cmp dl,0
		jne wyskok
		mov dl,' '
		wyskok:
		inc si
		mov ah,2
		int 21h
		loop pCheckLoop
	ret
parse_check endp
;-----------------------------
eat_space proc;w rejestrze si ma być aktualny offset znaku 
			  ;rozpatrywanego zwraca ilosc pominiętych spacji w rejestrze al
	xor al,al
	eat_s_loop:
		cmp si,cmd_len
		jg eat_s_exit
		mov ah,byte ptr es:[si+80h]
		cmp ah,' '
		jne eat_s_exit
		inc si
		inc al
		jmp eat_s_loop
	eat_s_exit:
	ret
eat_space endp
parse_input proc ;-------procedura ma za zadanie przeanalizować linie argumentow polecenia
	xor ah,ah
	mov al,byte ptr es:[80h]
	mov cmd_len,ax
	mov si,1
	mov di,offset input_names
	parse_input_mainloop: ;petla iteruje po argumentach wywolania funkcji
		call eat_space 	  ;zjedz spacje
		cmp si,cmd_len
		jg parse_inputMark
		mov al,byte ptr es:[si+80h]
		cmp al,'-' 		  ; sprawdz poprawnosc skladni
		jne syntax_perr
;----------------------------sprawdz ktora opcje mam rozwazyc
		inc si
		cmp si,cmd_len
		jg  syntax_perr
		mov al,byte ptr es:[si+80h]
		cmp al,'h'
		je opt_h
		cmp al,'i'
		je call_inpt
		cmp al,'o'
		je call_outpt
		cmp al,'t'
		je merg_char_change
;-------------------------------------------------------
		
		
	parse_inputMark:
	ret
;-----------------------------Kod ustawiania flag bledu--
	syntax_perr:
	mov parse_err,2
	jmp parse_inputMark
	input_perr:
	mov parse_err,1
	jmp parse_inputMark
;------------------------------------------------------
parse_input endp
;-------------------Kod czytania odpowiednich opcji----
;--------------------: -h Pomoc
	opt_h:
	mov ax,offset help
	printS ax
	jmp exit
;--------------------: -i 
	call_inpt:	; wczytaj nazwe, przy niepowodzeniu wyjdź z pracedury z bledem
	inc si
	cmp si,cmd_len
	jg syntax_perr
	call opt_i
	cmp al,0
	je syntax_perr
	jmp parse_input_mainloop
;--------------------: -o
	call_outpt:      ; wczytaj nazwe pliku wejsciowego, przy niepowodzeniu wyjdz z procedury z bledem
	inc si
	cmp si,cmd_len
	jg syntax_perr
	call opt_o
	cmp al,0
	je syntax_perr
	cmp i_file_numb,0 ; sprawdz czy podano chociaz jeden plik wejsciowy
	je input_perr
	jmp parse_input_mainloop
;--------------------: -t
	merg_char_change:
	inc si
	cmp si,cmd_len
	jg syntax_perr
	call eat_space ; zjedz nadwyzkowe spacje
	cmp al,0
	je syntax_perr
	cmp si,cmd_len  
	jg syntax_perr
	cmp i_file_numb,0 ; sprawdz czy podano chociaz jeden plik wejsciowy
	je input_perr
	mov ah,byte ptr es:[si+80h]
	mov merg_char,ah
	inc si
;--------------------: Wczytuje nazwę pliku wejsciowego, zwraca w rejestrze al, 0-blad wczytania,1-poprawne wczytanie
opt_i proc
	call eat_space
	cmp al,0
	je opt_i_badopt
	cmp si,cmd_len
	jg opt_i_badopt
	inc i_file_numb
	opt_i_mainloop:
		mov ah,byte ptr es:[si+80h]
		mov byte ptr ds:[di],ah
		inc si
		inc di
		cmp si,cmd_len
		jg opt_i_goodopt
		mov ah,byte ptr es:[si+80h]
		cmp ah," "
		je opt_i_goodopt
		jmp opt_i_mainloop
;--------------------: Blad skladni
	opt_i_badopt:
	xor al,al
	ret
;--------------------: Poprawna skladnia
	opt_i_goodopt:
	inc di
	mov byte ptr ds:[di],0
	mov al,1
	ret
opt_i endp
;--------------------: Wczytuja nazwe pliku wyjsciowego, zwraca kod bledu-0, poprawnego wyniku -1 w al
opt_o proc
	mov di,offset output_name
	call eat_space
	cmp al,0
	je opt_o_badopt
	cmp si,cmd_len
	jg opt_o_badopt
	cmp o_file_numb,0
	jg opt_o_badopt
	mov o_file_numb,1
	opt_o_mainloop:
		mov ah,byte ptr es:[si+80h]
		mov byte ptr ds:[di],ah
		inc si
		inc di
		cmp si,cmd_len
		jg opt_o_goodopt
		mov ah,byte ptr es:[si+80h]
		cmp ah," "
		je opt_o_goodopt
		jmp opt_o_mainloop
;--------------------: Blad skladni
	opt_o_badopt:
	xor al,al
	ret
;--------------------: Poprawna skladnia
	opt_o_goodopt:
	inc di
	mov byte ptr ds:[di],0
	mov al,1
	ret
opt_o endp
;-----------------------------------------------------
;----PROCEDURY OBSŁUGI PLIKÓW-------------------------
;-----------------------------------------------------
;--------Uzyskaj adres na poczatek nazwy nastepnego otwartego pliku,  
;---parametry:  si numer poprzedniego pliku, bx numer znaku od którego zaczynała się nazwa
get_next_name proc
	inc si
	mov bx,current_name
	get_next_iloop:
		mov al,byte ptr ds:[input_names+bx]
		inc bx
		cmp al,0
		jne get_next_iloop
	get_next_nend:
	mov current_name,bx
	ret
get_next_name endp
;----Wczytaj znaki z otwartego pliku do bufora, "zamknij" odpowiednie pliki, w si mamy który plik rozwazamy
readline proc
	mov cx,1
	mov bx,input_file
	lea dx,read_buffer   ; adres bufora
	readline_mainloop:
	;----------------------------
		mov cx,1
		mov ah,3fh		; czytamy znak pod odpowiednie miejsce w buforze
		int 21h
	;------------------------------
		jc filesread_error ; wyjście z błędem
		mov di,dx	; do adresowania w tablicy
		inc dx		
		cmp ax,0	; czy nie skończylismy pliku
		je readline_if
		cmp byte ptr ds:[di],10
		je readline_nlif
		cmp byte ptr ds:[di],13
		je readline_nlif
		jmp readline_mainloop
	readline_nlif: ; wczytanie dodatkowego znaku (koniec lini to 10,13)
	mov al,dif_char
	mov byte ptr ds:[di],al ; wpisujemy w ostatnie miejsce znak zakończenia lini
	mov cx,1
	mov ah,3fh
	lea dx,null   ; wczytujemy do "kosza"
	int 21h
	jc filesread_error
	cmp ax,0
	je readline_if
	mov cx,0
	mov dx,0
	mov al,01h
	mov ah,42h
	int 21h
	jc filesread_error
	push si
	shl si,1
	mov word ptr ds:[pointercx+si],dx
	mov word ptr ds:[pointerdx+si],ax
	pop si
	ret
	readline_if: ; "zamknięcie" pliku
	mov al,dif_char
	mov byte ptr ds:[di],al
	inc byte ptr ds:[in_ended]
	mov byte ptr ds:[bool_ended+si],1
	ret
	filesread_error: ; błąd
	mov byte ptr ds:[file_err+25],'r'
	call files_error
	ret
readline endp
;----Wypisz na konsole-------------------------------------
write_console proc
	write_console_mainloop:
	mov si,0 ; numer pliku do otwarcia
	mov current_name,0 ; offset znaku od którego mamy brać nazwe pliku
	mov debug_string,0
		write_console_readline:
			cmp byte ptr ds:[bool_ended+si],1 ; sprawdz czy plik sie wczesniej nie zakonczyl
			je overlap
			;----------------------------------
			lea ax,input_names 
			add ax,current_name		; pobierz offset odpowiedniego stringa
			openInFile ax	; otwórz plik  (wychodzi przy błędzie otwarcia z kodem i)
			fpoint si		; ustaw wskaźnik odczytu (wychodzi przy błędzie)
			call readline	; przeczytaj linię z pliku do bufora (przy błędzie przerywa pracę)
		;---Wypisz bufor----
		;-------------
			lea dx,read_buffer	
			mov ah,9
			int 21h
			mov ax,input_file
			closeFile ax 	; zamknij plik
			;------------------------------------
			overlap:
		;----Wypisz albo znak konkatenacji, albo koniec lini i przejdź do następnej
			inc debug_string
			mov ah,debug_string
			cmp ah,i_file_numb	
			je overlap2
			;------
			xor dx,dx
			mov dl,merg_char 
			mov ah,2
			int 21h
			;------
			call get_next_name ; przesuń się na następny plik
			jmp write_console_readline ; wykonuj petle dalej
			overlap2:
			lea dx,endline
			mov ah,9
			int 21h
	mov ah,in_ended
	cmp ah,i_file_numb
	jns flag04
	jmp write_console_mainloop
	flag04:
write_console endp
;----Wczytaj znaki z otwartego pliku i zapisuj do pliku wynikowego, "zamknij" odpowiednie pliki, w si mamy który plik rozwazamy
readline2f proc
	mov cx,1
	mov di,dx
	readline2f_mainloop:
		;----wczytaj pojedynczy znaki
		mov cx,1
		lea dx,read_buffer
		mov bx,input_file
		mov ah,3fh
		int 21h
		;--------------
		jc readline2f_error
		cmp ax,0
		je readline2f_ie
		cmp read_buffer,10
		je readline2f_nl
		cmp read_buffer,13
		je readline2f_nl
		mov cx,1
		lea ax,read_buffer
		printF ax 
	jmp readline2f_mainloop
	readline2f_nl:
	lea dx,read_buffer
	mov cx,1
	mov bx,input_file
	mov ah,3fh
	int 21h
	jc readline2f_error
	cmp ax,0
	je readline2f_ie
	mov cx,0
	mov dx,0
	mov bx,input_file
	mov al,01h
	mov ah,42h
	int 21h
	jc readline2f_error
	push si
	shl si,1
	mov word ptr ds:[pointercx+si],dx
	mov word ptr ds:[pointerdx+si],ax
	pop si
	ret
	readline2f_ie:
	mov byte ptr ds:[bool_ended+si],1
	inc in_ended
	ret
	readline2f_error:
	mov byte ptr ds:[file_err+25],'r'
	call files_error
	ret
readline2f endp
;----------------------
write_file proc
	lea ax,output_name
	openOutFile ax
	write_file_mainloop:
		mov si,0 ; numer pliku do otwarcia
		mov current_name,0 ; offset znaku od którego mamy brać nazwe pliku
		mov debug_string,0
		write_file_readline:
			cmp byte ptr ds:[bool_ended+si],1 ; sprawdz czy plik sie wczesniej nie zakonczyl
			je overlap0
			;----------------------------------
			lea ax,input_names 
			add ax,current_name		; pobierz offset odpowiedniego stringa
			openInFile ax	; otwórz plik  (wychodzi przy błędzie otwarcia z kodem i)
			fpoint si		; ustaw wskaźnik odczytu (wychodzi przy błędzie)
			call readline2f	; przeczytaj linię z pliku do bufora (przy błędzie przerywa pracę)
			
			mov ax,input_file
			closeFile ax 	; zamknij plik
			;------------------------------------
			overlap0:
		;----Wypisz albo znak konkatenacji, albo koniec lini i przejdź do następnej
			inc debug_string
			mov ah,debug_string
			cmp ah,i_file_numb	
			je overlap02
			;------
			mov cx,1
			lea ax,merg_char
			printF ax ; wypisz zank konkatenacji
			;------
			call get_next_name ; przesuń się na następny plik
		jmp write_file_readline ; wykonuj petle dalej
			overlap02:
			mov cx,2
			lea ax,endline
			printF ax
	mov ah,in_ended
	cmp ah,i_file_numb
	;inc debug
	;cmp debug,40
	je flag05
	jmp write_file_mainloop
	flag05:
	mov bx,output_file
	mov ah,3Eh
	int 21h
	jnc flag06
	call files_error
	flag06:
write_file endp
;----- Błąd obslugi plikow
files_error proc
	jnc normalka
	lea ax,file_err
	printS ax
	mov ax,04c00h
	int 21h
	normalka:
	ret
files_error endp
;-----------------------------------------------------------------------------------------------
parse_error: ;-------: kod wykonujacy odpowiednie akcje w zależności od wartosci zmiennej parse_err
	cmp parse_err,0
	je end_handle
	cmp parse_err,1
	je no_in_error
	cmp parse_err,2
	je syntax_error	
;--------------------: Wypisz komunikat o braku pliku wejsciowego 
	no_in_error:
	mov ax,offset in_file_err
	printS ax
	jmp exit
;--------------------: Wypisz komunikat o bledzie w skladni
	syntax_error:
	mov ax,offset syntax_err
	printS ax
	jmp exit
start:
	mov ax,seg stos1
	mov ss,ax
	mov sp,offset w_stosu
	mov ax,seg data
	mov ds,ax
	call parse_input
	jmp parse_error
	end_handle:
	call parse_check
	cmp o_file_numb,0
	jg file_write
	call write_console
	jmp exit
	file_write:
	call write_file
	exit:
	mov ax,04c00h ; zakonczenie programu
	int 21h
	;---------Blad plikow
code ends
end start
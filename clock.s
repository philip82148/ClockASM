; 時計プログラム
; <概要>
; 16Hzで動かすと「(day) hh:mm:ss」(時間は24時間表記)で表記する
; 時計プログラム。
; なお(day)は(A:日,...,G:土)で表記する。
; init部分の曜日と時間と分を書き換えるとその時刻からスタートする。
; <工夫点>
; ・クロックとプログラムメモリが少なすぎることを考えれば恐らく秒数の表示までは
; 求めていないとの題意解釈だったがあえて秒数の表示まで行った。
; しかし、最初に時計を動かし始める時間として指定できるのは時間と分までである。
; ・NOP命令としてJMP命令を用いているが、これはMOV A,A等とすると3バイト消費し
; プログラムメモリが足りなくなったためである。また、wait_Xclocksルーチンで
; 複数のサブルーチンを一つにまとめるような構成にする等、プログラムメモリを節約する
; 工夫をしている。
; ・出力を書き換え始めるタイミング(最上位の桁を書き換えるタイミング)が
; ぴったり1秒ごとになるようにしてある(コメントに「// 1」と書いてあるところ)。
; そして上の桁から順に書き変わるようにし、全ての桁の更新が16クロック以内で
; かつなるだけ早く更新されるように工夫した。
; ・秒数の表示まで行ったときにプログラムメモリが余っていたので曜日の表示まで
; 行った。これによりプログラムメモリは1バイトを残して全て使い切っている。
init:
	MOV	[232], 'A'	; // 曜日(A:日,...,G:土)
	MOV	[234], '0'	; // 時間の十の位(ユーザー指定可能)
	MOV	[235], '0'	; // 時間の一の位(ユーザー指定可能)
	MOV	[236], ':'	;
	MOV	[237], '0'	; // 分の十の位(ユーザー指定可能)
	MOV	[238], '0'	; // 分の一の位(ユーザー指定可能)
	MOV	[239], ':'	;

	MOV	D, [232]	; // Dレジスタは常に曜日を保存しておく

inc_day:			; // また、タイミングがないので
				; // 先にレジスタ上の曜日を変更しておく
	MOV	[240], '0'	; // 7, [240]:秒の十の位
	MOV	[241], '0'	; // 8, [241]:秒の一の位
	CMP	D, 'G'		; // 9
	JZ	.d_is_g		; // 10
	INC	D		; // 11
	JMP	start_plus7	; // 12
.d_is_g:
	MOV	D, 'A'		; // 11
	JMP	start_plus7	; // 12

start_minus3:
	JMP	start_minus2	; // 3
start_minus2:
	JMP	start_minus1	; // 4
start_minus1:
	JMP	start		; // 5
start:
	MOV	[240], '0'	; // 6, [240]:秒の十の位
	MOV	[241], '0'	; // 7, [241]:秒の一の位
	CALL	wait_for_5clocks; // 8-12
start_plus7:
	CALL	wait_for_min	; wait_for_min(); // 13
	MOV	A, [238]	; // 4, [238]:分の一の位
	CMP	A, '9'		; // 5
	JZ	.m_is_x9	; // 6
	CALL	wait_for_6clocks ; // 7-12
	CALL	wait_for_3clocks ; // 13-15
	INC	A		; A++; // 16
	MOV	[238], A	; print("xx:xA:xx"); // 1
	JMP	start_minus3	; goto start_minus3; // 2
.m_is_x9:
	MOV	A, [237]	; // 7, [237]:分の十の位
	CMP	A, '5'		; // 8
	JZ	.m_is_59	; // 9
	CALL	wait_for_6clocks ; // 10-15(6 clocks)
	INC	A		; A++; // 16
	MOV	[237], A	; print("xx:A0:xx"); // 1
	MOV	[238], '0'	; // 2
	JMP	start_minus2	; // 3
.m_is_59:
	MOV	A, [234]	; A=[234]:時間の十の位; // 10
	MOV	B, [235]	; B=[235]:時間の一の位; // 11
	CMP	A, '2'		; // 12
	JZ	.hm_is_2x59	; // 13
	CMP	B, '9'		; // 14
	JNZ	.hm_is_xx59	; // 15
;.hm_is_x959:
	INC	A		; A++; // 16
	MOV	[234], A	; print("A0:00:xx") // 1
	MOV	[235], '0'	; // 2
	MOV	[237], '0'	; // 3
	MOV	[238], '0'	; // 4
	JMP	start		; // 5
.hm_is_2x59:
	CMP	B, '3'		; // 14
	JZ	.hm_is_2359	; // 15
.hm_is_xx59:
	INC	B		; B++; // 16
	MOV	[235], B	; print("xB:00:00"); // 1
	MOV	[237], '0'	; // 2
	MOV	[238], '0'	; // 3
	JMP	start_minus1	; // 4
.hm_is_2359:
	JMP	.label1		; // 16
.label1:
	MOV	[232], D	; 曜日の表示 // 1
	MOV	[234], '0'	; print("00:00:xx") // 2
	MOV	[235], '0'	; // 3
	MOV	[237], '0'	; // 4
	MOV	[238], '0'	; // 5
	JMP	inc_day		; // 6


wait_for_min:
	MOV	A, '0'		; A='0'; // 14
.update_in_wait:
	CALL	inc_s_ones	; inc_s_ones(); // 15
	CALL	wait_for_7clocks ; // 3-9
	CALL	wait_for_6clocks ; // 10-15
	INC	A		; // 16
	MOV	[240], A	; print("xx:xx:A0"); // 1
	MOV	[241], '0'	; // 2
	CALL	wait_for_6clocks ; // 3-8
	CALL	wait_for_3clocks ; // 9-11
	CMP	A, '5'		; // 13
	JNZ	.update_in_wait ;   goto .a_is_5; // 14
	CALL	inc_s_ones	; inc_s_ones(); // 15
	RET			; // 3

inc_s_ones:
	MOV	B, '1'		; B='1'; // 16
.update_in_inc:
	MOV	[241], B	; print("xx:xx:xB"); // 1
	CALL	wait_for_6clocks ; // 2-7
	CALL	wait_for_6clocks ; // 8-13
	INC	B		; B++; 14
	CMP	B, '9'		; if(B!='9') // 15
	JNZ	.update_in_inc  ;  goto .update; // 16
	MOV	[241], B	; print("xx:xx:xB"); // 1
	RET			; else return; // 2


wait_for_7clocks:
	JMP	wait_for_6clocks
wait_for_6clocks:
	JMP	wait_for_5clocks
wait_for_5clocks:
	CALL	wait_for_2clocks
wait_for_3clocks:
	JMP	wait_for_2clocks
wait_for_2clocks:
	RET
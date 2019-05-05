
.data

str1:	.asciiz "\nWord Count\nStart entering characters in the MMIO Simulator:\n"
str2: 	.asciiz "\nEnter the search word:\n" 
str3:	.asciiz "\nThe word '"
str4: 	.asciiz "' appeared "
str5: 	.asciiz " time(s)\n" 
str6: 	.asciiz "press 'e' to enter another segment of text or 'q' to quit. Followed by enter.\n" 
str7: 	.asciiz "\nInvalid input stopping program"
str8: 	.asciiz "\nTerminating program"
newline: .asciiz "\n" 
buffer: .space 602
searchbuffer: .space 602
repeatbuffer: .space 602
resultbuff: .space 602
	
	
	.text
	.globl main

main:	
		
	la $a0, str1			#print prompt to enter text 
	jal writetoMMIO
	
	la $a0,buffer			#read text into buffer
	addi $a1,$0,602
	jal readfromMMIO
	
	la $a0, buffer			#print buffer
	jal writetoMMIO
	
	la $a0, str2			#print prompt to enter searchword 
	jal writetoMMIO
	
	la $a0,searchbuffer		#read search word into searchbuffer
	addi $a1,$0,602
	jal readfromMMIO
	
	la $a0,searchbuffer		#print search buffer to screen		
	jal writetoMMIO
	
countNumberofOccurences: 
#now we have the phrase in buffer and the search phrase in searchbuffer 
#need to count the number of occurences 
	
	add $s0,$0,$0		#s0 is the number of occurences 
	la $s1,buffer 		#s1 is a pointer to buffer 
	la $s2,searchbuffer 	#s2 is a pointer to searchbuffer 
	
	
repeat: 	
	lb $t0,0($s1)			#stop loop when you are at the end of buffer
	beq $t0,$0,endOfBuffer
	
	add $a0,$s1,$0			#else check if strings are equal (only considering alphanumeric characters) 
	add $a1,$s2,$0
	jal stringsEqual 		#check if strings are equal, result is 1 if they are equal 0 if not. result is stored in v0
	add $s0,$s0,$v0			#add result to number of occurences 
	
	add $a0,$s1,$0
	jal lengthIncludingSpace	#figure out how much to move the pointer by. Call on lengthIncludingSpace to get the number of characters until 1 after a space. 
	add $s1,$s1,$v0			#move the pointer forward by that 
	j repeat
	
endOfBuffer: 
#s0 now contains the number of occurences of the search word 
	 	
	la $a0, str3			#print out how many times the word occured with multiple calls to write to MMIO
	jal writetoMMIO
	
				 	
	la $a0, searchbuffer
	jal writetoMMIO
					
	la $a0, str4
	jal writetoMMIO
	
		 	
	add $a0,$s0,$0 
	la $a1,resultbuff
	jal writeToBuff
	
	la $a0,resultbuff
	jal writetoMMIO
					
	la $a0, str5
	jal writetoMMIO
 						
	la $a0, str6			#promt user to enter e or q based on what they would like to do next 	
	jal writetoMMIO
	
	
	la $a0,repeatbuffer
	addi $a1,$0,602
	jal readfromMMIO
	
	la $t0,repeatbuffer		#read the first character of the buffer
	lb $t1,0($t0)		
	lb $t2,1($t0)
	bne $t2,$0,invalidinput 
	beq $t1,'e',startOver		#if it was an e jump to start over 
	beq $t1,'q',quit 		#if it was a q jump to quit 
	
invalidinput:			
	la $a0, str7			#else print a messsge saying invalid input and terminate program anyway 
	jal writetoMMIO
	
	li $v0,10
	syscall 
		
quit: 
	la $a0,str8			#print message to terminate program 
	jal writetoMMIO
		
	li $v0,10			#terminate 
	syscall 
	
startOver: 
	add $t0,$0,$0			#set the value of t0=0
	add $t1,$0,$0			#make t1 a counter and set it equal to 0 
	la $t2,buffer			#make a pointer to buffer
	
resetBuffer:
	 beq $t1,602,resetSearchBuffer	#if you are at the end of the buffer stop
	 sb $t0,0($t2)			#else set the value at the byte to 0 (null) 
	 addi $t2,$t2,1			#increment pointer 
	 addi $t1,$t1,1			#increment counter 
	 j resetBuffer			#repeat 
	 
resetSearchBuffer:
	add $t0,$0,$0			#set the value of t0=0
	add $t1,$0,$0			#make t1 a counter and set it equal to 0 
	la $t2,searchbuffer		#make a pointer to searchbuffer 
	
resetSearchBufferloop:
	 beq $t1,602,resetRepeatBuffer	#if you are at the end of search buffer stop 
	 sb $t0,0($t2)			#else set the value at the byte to 0 (null) 
	 addi $t2,$t2,1			#increment pointer 
	 addi $t1,$t1,1			#increment counter 
	 j resetSearchBufferloop	#repeat 
	 
resetRepeatBuffer: 
	add $t0,$0,$0			#set the value of t0=0
	add $t1,$0,$0			#make t1 a counter and set it equal to 0 
	la $t2,repeatbuffer		#make a pointer to repeatbuffer 
	
resetRepeatBufferloop:
	 beq $t1,602,resetResultBuffer	#if you are at the end of search buffer stop 
	 sb $t0,0($t2)			#else set the value at the byte to 0 (null) 
	 addi $t2,$t2,1			#increment pointer 
	 addi $t1,$t1,1			#increment counter 
	 j resetRepeatBufferloop	#repeat 

resetResultBuffer:
	add $t0,$0,$0			#reset result buffer exactly the same as have done above 
	add $t1,$0,$0
	la $t2,resultbuff
	
resetResultBufferloop: 
	beq $t1,602,jumpToMain
	sb $t0,($t2)
	addi $t2,$t2,1
	addi $t1,$t1,1
	j resetResultBufferloop
jumpToMain: 
	j main






stringsEqual: 
#pointer to string1 in a0
#pointer to string2 in a1 
#1 if equal 0 if not 
	
	addi $sp,$sp,-12		#save return address and arguments on stack 
	sw $ra,0($sp)
	sw $a0,4($sp)
	sw $a1,8($sp)
	
	jal alphaNumLength 
	add $t7,$v0,$0			#t7 is the legnth of string1 

	
	lw $a0,8($sp)			#load pointer to string2 into a0
	jal alphaNumLength
	add $t1,$v0,$0			#t1 is the length of string2 	
	
	
	bne $t7,$t1,notEqual		#strings are not equal if the lengths arent equal 
	addi $t2,$0,0			#else make a counter=0
	lw $t3,	4($sp)			#t3 is a pointer to string1
	lw $t4,	8($sp)			#t4 is a pointer to string2	
	
loopstring: 
	beq $t2,$t1,equal 		#if you reach the end of the strings they are equal 
	lb $t5,0($t3)			#get corresponding characters in words 
	lb $t6,0($t4)
	bne $t5,$t6,notEqual 		#if the characters are not the same the strings arent equal 
	addi $t2,$t2,1			#else increment counters and pointers and repeat 
	addi $t3,$t3,1
	addi $t4,$t4,1
	j loopstring 
equal: 
	addi $v0,$0,1
	lw $ra,0($sp)
	addi $sp,$sp,12
	jr $ra 
notEqual: 
	addi $v0,$0,0
	lw $ra,0($sp)
	addi $sp,$sp,12
	jr $ra 


alphaNumLength: 
#pointer to string is in a0
#go until you hit a non-alphanumeric character 

	add $v0,$0,$0			#set counter=0
forloop: 
	lb $t0,0($a0)			#get character at a0
	beq $t0,$0,notAlphaNumeric 	
	bgt $t0,'z',notAlphaNumeric
	blt $t0,'a',checkUppercase

	addi $v0,$v0,1			#t0 is an alphanumeric character so increase counter by 1 
	addi $a0,$a0,1			#increase counter by 1 
	j forloop 			#repeat

checkUppercase: 
 	bgt $t0,'Z',notAlphaNumeric
 	blt $t0,'A',checkNumber
 	addi $v0,$v0,1			#t0 is an alphanumeric character so increase counter by 1 
	addi $a0,$a0,1			#increasecounter by 1 
	j forloop 			#repeat
 	
checkNumber: 
	bgt $t0,'9', notAlphaNumeric 
	blt $t0,'0', notAlphaNumeric 
	addi $v0,$v0,1			#t0 is an alphanumeric character so increase counter by 1 
	addi $a0,$a0,1			#increasecounter by 1 
	j forloop 			#repeat

notAlphaNumeric: 
	jr $ra 
	
 		
lengthIncludingSpace: 
#computes the length of a word in a string until the next space 
#pointer to word is in a0
#result of length+1 is in v0

	add $v0,$0,0		#set counter=0
loop: 
	lb $t0,($a0)		#load character at a0
	beq $t0,$0,stoploop	#if you are at the end of your string stop
	beq $t0,' ',stoploop	#or if you encounter a space stop
	add $v0,$v0,1		#else increment counter 
	addi $a0,$a0,1		#increment pointer by 1 
	j loop
stoploop: 
	addi $v0,$v0,1		#add one to the length to account for the space 
	jr $ra 			#return 
	
writetoMMIO: 
#pointer to string is in a0 
	lui $t0, 0xffff 	#ffff0000
Loop1: 	lw $t1, 8($t0) 		#control
	andi $t1,$t1,0x0001
	beq $t1,$zero,Loop1
Loop2:
	lb $t2,($a0)
	beq $t2,$0,endloop2
	beq $t2,'<',endloop2
	sb $t2, 12($t0) 	#data	
	addi $a0,$a0,1
	j Loop2
endloop2: 
	jr $ra
	
readfromMMIO:
#a0 is the buffer you would like to write to
#a1 is the num of characters you wish to write 

	add $t2,$0,$0			#make a counter=0 
echo:	
	lui $t0, 0xffff 		#ffff0000
Loop3:	lw $t1, 0($t0) 			#control
	andi $t1,$t1,0x0001
	beq $t1,$zero,Loop3
	lw $v0, 4($t0) 			#data	
 		
	beq $t2,$a1,stopReading		#if you have read 600 characters stop 
	beq $v0,'\n',stopReading	#or if user presses enter stop 
	sb $v0,($a0)			#store character in buffer
	addi $a0,$a0,1			#increment buffer pointer by 1 
	addi $t2,$t2,1			#increment counter by 1 
	j echo				#repeat infinetely many times 	
stopReading: 
	jr $ra 	
	
writeToBuff: 
#number to write is in $a0
#address of buffer is in a1
#assuming a word will not appear more than 1000 times 
	blt $a0,10,onedigit		
	blt $a0,100,twodigits
	
	addi $t0,$0,10		#number is 3 digits so split up and add consecutively to buffer 
	div $a0,$t0
	mfhi $t3		#third digit is in t3
	mflo $t2
	div $t2,$t0
	mfhi $t2		#second digit is in t2
	mflo $t1		#first digit is in t1
	addi $t1,$t1,48		#convert all digits to their ascii values 
	addi $t2,$t2,48		
	addi $t3,$t3,48
	sb $t1,($a1)		#store first digit in buffer
	addi $a1,$a1,1		#increment pointer 
	sb $t2,($a1)		#store second digit in buffer 
	addi $a1,$a1,1		#increment pointer 
	sb $t3,($a1)		#store third digit in buffer
	jr $ra			#return	
onedigit: 
	addi $a0,$a0,48		#number is one digit so convert to ascii value and add to buffer 
	sb $a0,($a1)
	jr $ra			#return 
	
twodigits: 
	addi $t0,$0,10		#number is two digits so split up digits 
	div $a0,$t0
	mflo $t1 		#t1 is quotient (first digit)
	mfhi $t2		#t2 is remainder (second digit) 
	addi $t1,$t1,48		#convert both digits to their ascii values 
	addi $t2,$t2,48		
	sb $t1,($a1)		#store first digit in buffer
	addi $a1,$a1,1		#increment pointer 
	sb $t2,($a1)		#store second digit in buffer 
	jr $ra			#return 
	

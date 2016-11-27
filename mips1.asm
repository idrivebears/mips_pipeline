	.text
	addi $t0,$zero,5
	addi $t1,$zero,4
	addi $t2,$t1,1
	add $t3,$t1,$t0
	and $t4,$t1,$t0
	andi $t5,$t0,5
	addi $t6,$zero,0
	beq $t0,$t5,label
	addi $t6,$zero,1
label:
	beq $t0,$t0,label
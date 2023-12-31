	.file	"test_O_level.c"
	.section	.rodata
.LC1:
	.string	"\n Starting a loop "
.LC3:
	.string	"\n done "
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movl	%edi, -36(%rbp)
	movq	%rsi, -48(%rbp)
	movq	$0, -24(%rbp)
	movl	$0, %eax
	movq	%rax, -16(%rbp)
	movl	$.LC1, %edi
	call	puts
	movq	$0, -8(%rbp)
	jmp	.L2
.L3:
	movsd	-16(%rbp), %xmm0
	mulsd	-16(%rbp), %xmm0
	movsd	.LC2(%rip), %xmm1
	subsd	%xmm1, %xmm0
	movsd	%xmm0, -16(%rbp)
	addq	$1, -8(%rbp)
.L2:
	cmpq	$200000000, -8(%rbp)
	jle	.L3
	movl	$.LC3, %edi
	call	puts
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.section	.rodata
	.align 8
.LC2:
	.long	2717992744
	.long	1073661536
	.ident	"GCC: (GNU) 4.8.5 20150623 (Red Hat 4.8.5-44)"
	.section	.note.GNU-stack,"",@progbits

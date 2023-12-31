	.file	"stream_simple.c"
	.text
	.globl	gtod_seconds
	.type	gtod_seconds, @function
gtod_seconds:
.LFB14:
	.cfi_startproc
	subq	$40, %rsp
	.cfi_def_cfa_offset 48
	movq	%rsp, %rsi
	leaq	16(%rsp), %rdi
	call	gettimeofday
	cvtsi2sdq	16(%rsp), %xmm1
	cvtsi2sdq	24(%rsp), %xmm0
	mulsd	.LC0(%rip), %xmm0
	addsd	%xmm1, %xmm0
	addq	$40, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE14:
	.size	gtod_seconds, .-gtod_seconds
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align 8
.LC6:
	.string	"AI = %f    GFLOPs/s = %f    time = %f\n"
	.align 8
.LC7:
	.string	"We spent all this time calculating %g\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB15:
	.cfi_startproc
	subq	$40, %rsp
	.cfi_def_cfa_offset 48
	movl	$integer, %edi
	xorps	%xmm3, %xmm3
	movss	%xmm3, 8(%rsp)
	movl	$0, %esi
	movsd	.LC2(%rip), %xmm1
.L7:
	movss	8(%rsp), %xmm5
	movaps	%xmm5, %xmm0
	mulss	%xmm5, %xmm0
	unpcklps	%xmm0, %xmm0
	cvtps2pd	%xmm0, %xmm0
	subsd	%xmm1, %xmm0
	unpcklpd	%xmm0, %xmm0
	cvtpd2ps	%xmm0, %xmm7
	movss	%xmm7, 8(%rsp)
	movss	%xmm7, in(,%rsi,4)
	movq	%rdi, %rdx
	movl	$0, %eax
.L5:
	leal	(%rax,%rsi), %ecx
	movl	%ecx, (%rdx)
	addl	$1234, %eax
	addq	$4000000, %rdx
	cmpl	$8638, %eax
	jne	.L5
	addq	$1, %rsi
	addq	$4, %rdi
	cmpq	$1000000, %rsi
	jne	.L7
	call	gtod_seconds
	movsd	%xmm0, 24(%rsp)
	xorps	%xmm4, %xmm4
	movss	%xmm4, 20(%rsp)
	movl	$0, %edx
	movsd	.LC2(%rip), %xmm4
	movsd	.LC0(%rip), %xmm3
.L11:
	movss	8(%rsp), %xmm6
	movaps	%xmm6, %xmm0
	mulss	%xmm6, %xmm0
	unpcklps	%xmm0, %xmm0
	cvtps2pd	%xmm0, %xmm0
	subsd	%xmm4, %xmm0
	unpcklpd	%xmm0, %xmm0
	cvtpd2ps	%xmm0, %xmm2
	movss	%xmm2, 8(%rsp)
	movss	20(%rsp), %xmm1
	cvtps2pd	%xmm1, %xmm1
	unpcklps	%xmm2, %xmm2
	cvtps2pd	%xmm2, %xmm2
	movss	out(,%rdx,4), %xmm0
	cvtps2pd	%xmm0, %xmm0
	mulsd	%xmm3, %xmm0
	addsd	%xmm2, %xmm0
	addsd	%xmm1, %xmm0
	unpcklpd	%xmm0, %xmm0
	cvtpd2ps	%xmm0, %xmm5
	movss	%xmm5, 20(%rsp)
	movl	$0, %eax
.L9:
	movss	in(,%rax,4), %xmm0
	movaps	%xmm0, %xmm1
	mulss	%xmm0, %xmm1
	mulss	%xmm0, %xmm1
	mulss	%xmm0, %xmm1
	mulss	%xmm0, %xmm1
	mulss	%xmm0, %xmm1
	mulss	%xmm0, %xmm1
	mulss	%xmm0, %xmm1
	mulss	%xmm1, %xmm0
	movss	%xmm0, out(,%rax,4)
	addq	$1, %rax
	cmpq	$1000000, %rax
	jne	.L9
	addq	$1, %rdx
	cmpq	$1000, %rdx
	jne	.L11
	call	gtod_seconds
	subsd	24(%rsp), %xmm0
	movsd	.LC3(%rip), %xmm1
	divsd	%xmm0, %xmm1
	movsd	%xmm0, 8(%rsp)
	movapd	%xmm0, %xmm2
	divsd	.LC4(%rip), %xmm1
	movsd	.LC5(%rip), %xmm0
	movl	$.LC6, %edi
	movl	$3, %eax
	call	printf
	movss	20(%rsp), %xmm0
	cvtps2pd	%xmm0, %xmm0
	addsd	8(%rsp), %xmm0
	unpcklpd	%xmm0, %xmm0
	cvtpd2ps	%xmm0, %xmm3
	movss	%xmm3, 8(%rsp)
	movl	$268435455, %ecx
	andq	8(%rsp), %rcx
	movabsq	$4835703278458516699, %rdx
	movq	%rcx, %rax
	imulq	%rdx
	movq	%rdx, %rax
	sarq	$18, %rax
	imulq	$1000000, %rax, %rax
	subq	%rax, %rcx
	movss	out(,%rcx,4), %xmm0
	cvtps2pd	%xmm0, %xmm0
	movl	$.LC7, %edi
	movl	$1, %eax
	call	printf
	movl	$0, %eax
	addq	$40, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE15:
	.size	main, .-main
	.comm	integer,28000000,32
	.local	out
	.comm	out,4000000,32
	.local	in
	.comm	in,4000000,32
	.section	.rodata.cst8,"aM",@progbits,8
	.align 8
.LC0:
	.long	2696277389
	.long	1051772663
	.align 8
.LC2:
	.long	2717992744
	.long	1073661536
	.align 8
.LC3:
	.long	0
	.long	1107152229
	.align 8
.LC4:
	.long	0
	.long	1104006501
	.align 8
.LC5:
	.long	0
	.long	1075838976
	.ident	"GCC: (GNU) 4.8.5 20150623 (Red Hat 4.8.5-44)"
	.section	.note.GNU-stack,"",@progbits

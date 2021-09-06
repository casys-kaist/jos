#include <inc/types.h>
#include <inc/assert.h>
#include <inc/error.h>


// Dispatches to the correct kernel function, passing the arguments.
int64_t
syscall(uint64_t syscallno, uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4, uint64_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");

	switch (syscallno) {

	default:
		return -E_NO_SYS;
	}
}


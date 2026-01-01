#include <stdio.h>
#include "math_utils.h"

int main() {
    printf("Math Utils Test Program\n");
    printf("=======================\n\n");

    // Test add
    printf("add(5, 3) = %d\n", add(5, 3));
    
    // Test subtract
    printf("subtract(10, 4) = %d\n", subtract(10, 4));
    
    // Test multiply
    printf("multiply(6, 7) = %d\n", multiply(6, 7));
    
    // Test divide (normal case)
    printf("divide(20, 4) = %d\n", divide(20, 4));
    
    // Note: divide by zero case is NOT tested (intentionally uncovered)
    // printf("divide(10, 0) = %d\n", divide(10, 0));
    
    // Test factorial
    printf("factorial(5) = %d\n", factorial(5));
    printf("factorial(0) = %d\n", factorial(0));
    
    // Test is_prime
    printf("is_prime(7) = %d\n", is_prime(7));
    printf("is_prime(10) = %d\n", is_prime(10));
    printf("is_prime(2) = %d\n", is_prime(2));
    
    // Note: is_prime negative case is NOT tested (intentionally uncovered)
    
    return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include "math_utils.h"

// Utility function with conditional coverage
void print_section(const char *title) {
    printf("\n===== %s =====", title);
}

int main() {
    printf("\n=== C Math Utilities Coverage Example ===\n");

    // Basic operations - all covered
    print_section("Basic Arithmetic");
    printf("\nadd(5, 3) = %d\n", add(5, 3));
    printf("subtract(10, 4) = %d\n", subtract(10, 4));
    printf("multiply(6, 7) = %d\n", multiply(6, 7));
    printf("divide(20, 4) = %d\n", divide(20, 4));

    // Conditional coverage - some paths uncovered
    print_section("Power Function");
    printf("\npower(2, 8) = %lld\n", power(2, 8));  // Covered
    printf("power(5, 3) = %lld\n", power(5, 3));  // Covered
    printf("power(10, 2) = %lld\n", power(10, 2)); // Covered

    // Factorial - covered
    print_section("Factorial");
    printf("\nfactorial(5) = %d\n", factorial(5)); // Covered
    printf("factorial(0) = %d\n", factorial(0)); // Covered
    printf("factorial(6) = %d\n", factorial(6)); // Covered

    // Prime checking - partial coverage
    print_section("Prime Numbers");
    printf("\nis_prime(7) = %d\n", is_prime(7));   // Covered
    printf("is_prime(10) = %d\n", is_prime(10));  // Covered
    printf("is_prime(2) = %d\n", is_prime(2));    // Covered
    printf("is_prime(13) = %d\n", is_prime(13));  // Covered
    // is_prime(-5) not called - uncovered

    // Absolute value
    print_section("Absolute Value");
    printf("\nabsolute_value(10) = %d\n", absolute_value(10));   // Covered
    printf("absolute_value(-15) = %d\n", absolute_value(-15));  // Covered
    printf("absolute_value(0) = %d\n", absolute_value(0));      // Covered

    // Min/Max functions - partial coverage
    print_section("Min/Max Functions");
    printf("\nmax(10, 20) = %d\n", max(10, 20));   // Covered
    printf("max(30, 15) = %d\n", max(30, 15));   // Covered
    printf("max(5, 5) = %d\n", max(5, 5));       // Covered
    printf("min(10, 20) = %d\n", min(10, 20));   // Covered
    printf("min(30, 15) = %d\n", min(30, 15));   // Covered

    // GCD - partial coverage
    print_section("GCD (Greatest Common Divisor)");
    printf("\ngcd(12, 18) = %d\n", gcd(12, 18));  // Covered
    printf("gcd(7, 11) = %d\n", gcd(7, 11));    // Covered
    printf("gcd(20, 15) = %d\n", gcd(20, 15));  // Covered
    // gcd with negative numbers not tested - uncovered

    // Fibonacci - partial coverage
    print_section("Fibonacci Sequence");
    printf("\nfibonacci(0) = %d\n", fibonacci(0));   // Covered
    printf("fibonacci(1) = %d\n", fibonacci(1));   // Covered
    printf("fibonacci(5) = %d\n", fibonacci(5));   // Covered
    printf("fibonacci(8) = %d\n", fibonacci(8));   // Covered
    // fibonacci(10) not called - uncovered for larger values

    printf("\n=== All tests completed ===\n\n");
    return 0;
}

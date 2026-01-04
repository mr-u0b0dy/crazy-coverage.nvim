#include <stdio.h>
#include <stdlib.h>
#include "math_utils.h"

int main() {
    /* Basic arithmetic operations */
    int a = 15, b = 7;
    add(a, b);
    subtract(a, b);
    multiply(a, b);
    divide(20, 4);

    /* Power and factorial with edge cases */
    power(2, 8);
    power(3, 0);
    power(5, 2);
    factorial(5);
    factorial(0);
    factorial(1);

    /* Prime checking with various inputs */
    is_prime(7);
    is_prime(2);
    is_prime(15);
    is_prime(1);
    is_prime(11);
    is_prime(9);

    /* Utility functions with mixed cases */
    absolute_value(10);
    absolute_value(-15);
    absolute_value(0);

    /* Min/Max with different combinations */
    max(10, 20);
    max(30, 15);
    max(5, 5);
    max(-5, -2);
    max(8, -3);
    min(10, 20);
    min(30, 15);
    min(5, 5);
    min(-5, -2);
    min(8, -3);

    /* GCD with different value combinations */
    gcd(12, 18);
    gcd(7, 11);
    gcd(100, 50);
    gcd(21, 14);

    /* Fibonacci with edge cases */
    fibonacci(0);
    fibonacci(1);
    fibonacci(5);
    fibonacci(8);
    fibonacci(10);

    /* Minimal output */
    printf("Coverage test complete\n");
    return 0;
}

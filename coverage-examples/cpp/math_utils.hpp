// C++ Math Utilities Header
#ifndef MATH_UTILS_HPP
#define MATH_UTILS_HPP

namespace MathUtils {
    // Basic arithmetic operations
    int add(int a, int b);
    int subtract(int a, int b);
    int multiply(int a, int b);
    double divide(double a, double b);
    
    // Advanced operations
    long long power(int base, int exp);
    int factorial(int n);
    bool is_prime(int n);
    
    // Utility functions
    int absolute_value(int n);
    int max(int a, int b);
    int min(int a, int b);
    int gcd(int a, int b);
    int fibonacci(int n);
    
    // Statistical functions
    double average(int *values, int count);
    int sum(int *values, int count);
    
    // String utilities
    bool is_palindrome(const char *str);
    int string_length(const char *str);
}

#endif // MATH_UTILS_HPP

// C++ example source
#include <iostream>
#include <iomanip>
#include "math_utils.hpp"

void print_section(const char *title) {
    std::cout << "\n===== " << title << " =====" << std::endl;
}

int main() {
    std::cout << "\n=== C++ Math Utilities Coverage Example ===" << std::endl;

    // Basic operations - all covered
    print_section("Basic Arithmetic");
    std::cout << "add(10, 5) = " << MathUtils::add(10, 5) << std::endl;
    std::cout << "subtract(20, 8) = " << MathUtils::subtract(20, 8) << std::endl;
    std::cout << "multiply(6, 7) = " << MathUtils::multiply(6, 7) << std::endl;
    std::cout << "divide(20, 4) = " << std::fixed << std::setprecision(2) 
              << MathUtils::divide(20, 4) << std::endl;

    // Power function - covered
    print_section("Power Function");
    std::cout << "power(2, 8) = " << MathUtils::power(2, 8) << std::endl;
    std::cout << "power(3, 5) = " << MathUtils::power(3, 5) << std::endl;
    std::cout << "power(10, 0) = " << MathUtils::power(10, 0) << std::endl;

    // Factorial - covered
    print_section("Factorial");
    std::cout << "factorial(5) = " << MathUtils::factorial(5) << std::endl;
    std::cout << "factorial(0) = " << MathUtils::factorial(0) << std::endl;
    std::cout << "factorial(6) = " << MathUtils::factorial(6) << std::endl;

    // Prime checking - partial coverage
    print_section("Prime Numbers");
    std::cout << "is_prime(7) = " << (MathUtils::is_prime(7) ? "true" : "false") << std::endl;
    std::cout << "is_prime(2) = " << (MathUtils::is_prime(2) ? "true" : "false") << std::endl;
    std::cout << "is_prime(15) = " << (MathUtils::is_prime(15) ? "true" : "false") << std::endl;
    std::cout << "is_prime(1) = " << (MathUtils::is_prime(1) ? "true" : "false") << std::endl;

    // Absolute value
    print_section("Absolute Value");
    std::cout << "absolute_value(10) = " << MathUtils::absolute_value(10) << std::endl;
    std::cout << "absolute_value(-15) = " << MathUtils::absolute_value(-15) << std::endl;

    // Min/Max
    print_section("Min/Max Functions");
    std::cout << "max(10, 20) = " << MathUtils::max(10, 20) << std::endl;
    std::cout << "max(30, 15) = " << MathUtils::max(30, 15) << std::endl;
    std::cout << "max(5, 5) = " << MathUtils::max(5, 5) << std::endl;
    std::cout << "min(10, 20) = " << MathUtils::min(10, 20) << std::endl;
    std::cout << "min(30, 15) = " << MathUtils::min(30, 15) << std::endl;

    // GCD - partial coverage
    print_section("GCD (Greatest Common Divisor)");
    std::cout << "gcd(12, 18) = " << MathUtils::gcd(12, 18) << std::endl;
    std::cout << "gcd(7, 11) = " << MathUtils::gcd(7, 11) << std::endl;

    // Fibonacci
    print_section("Fibonacci Sequence");
    std::cout << "fibonacci(0) = " << MathUtils::fibonacci(0) << std::endl;
    std::cout << "fibonacci(5) = " << MathUtils::fibonacci(5) << std::endl;
    std::cout << "fibonacci(8) = " << MathUtils::fibonacci(8) << std::endl;

    // Statistical functions
    print_section("Statistical Functions");
    int values[] = {10, 20, 30, 40, 50};
    int count = sizeof(values) / sizeof(values[0]);
    std::cout << "sum([10, 20, 30, 40, 50]) = " << MathUtils::sum(values, count) << std::endl;
    std::cout << "average([10, 20, 30, 40, 50]) = " 
              << std::fixed << std::setprecision(2)
              << MathUtils::average(values, count) << std::endl;

    // String utilities
    print_section("String Utilities");
    std::cout << "string_length(\"hello\") = " << MathUtils::string_length("hello") << std::endl;
    std::cout << "is_palindrome(\"racecar\") = " 
              << (MathUtils::is_palindrome("racecar") ? "true" : "false") << std::endl;
    std::cout << "is_palindrome(\"hello\") = " 
              << (MathUtils::is_palindrome("hello") ? "true" : "false") << std::endl;

    // Error cases (mostly UNCOVERED)
    print_section("Error Handling (Some Uncovered)");
    try {
        // This will NOT be called - uncovered
        // MathUtils::divide(10, 0);
    } catch (const std::exception &e) {
        std::cout << "Caught exception: " << e.what() << std::endl;
    }

    std::cout << "\n=== All tests completed ===" << std::endl << std::endl;
    return 0;
}

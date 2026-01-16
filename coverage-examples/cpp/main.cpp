// C++ example source with minimal output
#include "math_utils.hpp"
#include <iostream>

int main() { // COVERED
  // Basic arithmetic operations
  int a = 15, b = 7;
  MathUtils::add(a, b);
  MathUtils::subtract(a, b);
  MathUtils::multiply(a, b);
  MathUtils::divide(20.0, 4.0);

  // Power and factorial with edge cases
  MathUtils::power(2, 8);
  MathUtils::power(3, 0);
  MathUtils::power(5, 2);
  MathUtils::factorial(5);
  MathUtils::factorial(0);
  MathUtils::factorial(1);

  // Prime checking with various inputs
  MathUtils::is_prime(7);
  MathUtils::is_prime(2);
  MathUtils::is_prime(15);
  MathUtils::is_prime(1);
  MathUtils::is_prime(11);

  // Utility functions with mixed cases
  MathUtils::absolute_value(10);
  MathUtils::absolute_value(-15);
  MathUtils::absolute_value(0);

  // Min/Max with different combinations
  MathUtils::max(10, 20);
  MathUtils::max(30, 15);
  MathUtils::max(5, 5);
  MathUtils::max(-5, -2);
  MathUtils::max(8, -3);
  MathUtils::min(10, 20);
  MathUtils::min(30, 15);
  MathUtils::min(5, 5);
  MathUtils::min(-5, -2);
  MathUtils::min(8, -3);

  // GCD with different value combinations
  MathUtils::gcd(12, 18);
  MathUtils::gcd(7, 11);
  MathUtils::gcd(100, 50);
  MathUtils::gcd(21, 14);

  // Fibonacci with edge cases
  MathUtils::fibonacci(0);
  MathUtils::fibonacci(1);
  MathUtils::fibonacci(5);
  MathUtils::fibonacci(8);
  MathUtils::fibonacci(10);

  // Statistical operations
  int values[] = {10, 20, 30, 40, 50};
  int count = sizeof(values) / sizeof(values[0]);
  MathUtils::sum(values, count);
  MathUtils::average(values, count);

  // Single element array
  int single[] = {42};
  MathUtils::sum(single, 1);
  MathUtils::average(single, 1);

  // String utilities with different inputs
  MathUtils::string_length("hello");
  MathUtils::string_length("a");
  MathUtils::string_length("");
  // COVERED
  MathUtils::is_palindrome("racecar");
  MathUtils::is_palindrome("hello");
  MathUtils::is_palindrome("a");
  MathUtils::is_palindrome("noon");
  MathUtils::is_palindrome("level");

  // Minimal output
  std::cout << "Coverage test complete" << std::endl;
  return 0;
}

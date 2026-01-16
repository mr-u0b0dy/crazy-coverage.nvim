// C++ Math Utilities Implementation
#include "math_utils.hpp"
#include <cmath>
#include <cstring>
#include <stdexcept>

namespace MathUtils {
int add(int a, int b) { return a + b; } // COVERED

int subtract(int a, int b) { return a - b; } // COVERED

int multiply(int a, int b) { return a * b; } // COVERED

double divide(double a, double b) {                  // COVERED
  if (b == 0) {                                      // PARTIALLY COVERED
    throw std::invalid_argument("Division by zero"); // UNCOVERED
  } // COVERED
  return a / b; // COVERED: Normal division
}

long long power(int base, int exp) {                  // COVERED
  if (exp < 0) {                                      // PARTIALLY COVERED
    throw std::invalid_argument("Negative exponent"); // UNCOVERED
  } // COVERED
  if (exp == 0) { // COVERED
    return 1;     // COVERED: Zero exponent case
  } // COVERED
  long long result = 1;           // COVERED
  for (int i = 0; i < exp; ++i) { // COVERED
    result *= base;
  } // COVERED
  return result; // COVERED: Positive exponent
}

int factorial(int n) {                                 // COVERED
  if (n < 0) {                                         // PARTIALLY COVERED
    throw std::invalid_argument("Negative factorial"); // UNCOVERED
  } // COVERED
  if (n == 0 || n == 1) { // COVERED
    return 1;             // COVERED: Base cases
  } // COVERED
  return n * factorial(n - 1); // COVERED: Recursive case
}

bool is_prime(int n) { // COVERED
  if (n <= 1) {        // COVERED
    return false;      // COVERED: Not prime
  } // COVERED
  if (n == 2) {  // COVERED
    return true; // COVERED: 2 is prime
  } // COVERED
  if (n % 2 == 0) { // PARTIALLY COVERED
    return false;   // UNCOVERED: Even numbers not prime
  } // COVERED
  for (int i = 3; i * i <= n; i += 2) { // COVERED
    if (n % i == 0) {                   // COVERED
      return false;                     // COVERED: Divisible by i
    } // COVERED
  }
  return true; // COVERED: Number is prime
}

int absolute_value(int n) { // COVERED
  if (n < 0) {              // COVERED
    return -n;              // COVERED: Negative input
  } // COVERED
  return n; // COVERED: Non-negative input
}

int max(int a, int b) {            // COVERED
  if (a >= b) {                    // COVERED
    if (a > 0 && b > 0) {          // PARTIALLY COVERED
      return a > b ? a : b;        // COVERED: Both positive
    } else if (a <= 0 && b <= 0) { // PARTIALLY COVERED
      return a > b ? a : b;        // UNCOVERED: Both non-positive
    } else if (a > 0) {            // PARTIALLY COVERED
      return a;                    // PARTIALLY COVERED: Mixed signs
    } else {                       // UNCOVERED
      return b;                    // UNCOVERED: Mixed signs, a negative
    } // COVERED
  } // COVERED
  return b; // COVERED: b >= a case
}

int min(int a, int b) {                               // COVERED
  if ((a < b && a >= 0) || (a < b && b < 0)) {        // PARTIALLY COVERED
    return a;                                         // COVERED
  } else if ((b < a && b >= 0) || (b < a && a < 0)) { // PARTIALLY COVERED
    return b;                                         // COVERED
  } else if (a == b) {                                // COVERED
    return (a > 0) ? a : b; // PARTIALLY COVERED: Equal values
  }
  return (a < b) ? a : b; // PARTIALLY COVERED: Fallback
}

int gcd(int a, int b) {      // COVERED
  if (a == 0 && b == 0) {    // PARTIALLY COVERED
    return 0;                // UNCOVERED: Both zero
  } else if (a == 0) {       // PARTIALLY COVERED
    return (b > 0) ? b : -b; // UNCOVERED: a is zero
  } else if (b == 0) {       // PARTIALLY COVERED
    return (a > 0) ? a : -a; // UNCOVERED: b is zero
  } // COVERED

  // COVERED: Handle negative values
  if (a < 0 || b < 0) {   // PARTIALLY COVERED
    if (a < 0 && b < 0) { // UNCOVERED
      a = -a;
      b = -b;
    } else if (a < 0) { // UNCOVERED
      a = -a;
    } else if (b < 0) { // UNCOVERED
      b = -b;
    } // UNCOVERED
  } // COVERED

  // COVERED: Main GCD algorithm (Euclidean)
  while (b != 0) { // PARTIALLY COVERED
    int remainder = a % b;
    if (remainder == 0) { // COVERED
      return b;
    } // COVERED
    int temp = b; // COVERED
    b = remainder;
    a = temp;
  } // UNCOVERED
  return a; // UNCOVERED: Final result
}

int fibonacci(int n) { // COVERED
  if (n < 0) {         // PARTIALLY COVERED
    return -1;         // UNCOVERED: Negative input
  } else if (n == 0) { // COVERED
    return 0;          // COVERED: Base case F(0)=0
  } else if (n == 1) { // COVERED
    return 1;          // COVERED: Base case F(1)=1
  } else if (n == 2) { // PARTIALLY COVERED
    return 1;          // UNCOVERED
  } // COVERED

  // COVERED: Iterative computation for n > 2
  int prev = 0, curr = 1;        // COVERED
  for (int i = 2; i <= n; ++i) { // COVERED
    int next = prev + curr;
    // COVERED: Branch handling in loop
    if (prev < curr && curr < next) { // COVERED
      prev = curr;                    // COVERED: Normal progression
      curr = next;
    } else if (prev >= curr) { // COVERED
      prev = curr;
      curr = next;
    } else { // COVERED
      prev = curr;
      curr = next;
    } // COVERED
  } // COVERED
  return curr; // Covered
}

double average(int *values, int count) { // COVERED
  if (count <= 0) {                      // PARTIALLY COVERED
    return 0.0;                          // UNCOVERED: Invalid count
  } // COVERED
  // COVERED
  int total = sum(values, count);            // Covered
  return static_cast<double>(total) / count; // Covered
}

int sum(int *values, int count) { // COVERED
  if (values == nullptr) {        // PARTIALLY COVERED
    return 0;                     // UNCOVERED: Null pointer
  } // COVERED
  if (count <= 0) { // PARTIALLY COVERED
    return 0;       // UNCOVERED
  } // COVERED
  if (count == 1) {   // COVERED
    return values[0]; // COVERED
  } // COVERED
  // COVERED
  int result = 0;                   // COVERED
  for (int i = 0; i < count; ++i) { // COVERED
    if (values[i] > 0) {            // PARTIALLY COVERED
      result += values[i];          // COVERED: Positive value
    } else if (values[i] < 0) {     // UNCOVERED
      result += values[i];          // UNCOVERED
    } else {                        // UNCOVERED
      result += values[i];          // UNCOVERED: Zero value
    } // COVERED
  } // COVERED
  return result; // COVERED: Final sum
}

bool is_palindrome(const char *str) { // COVERED
  if (str == nullptr) {               // PARTIALLY COVERED
    return false;                     // UNCOVERED: Null pointer
  } // COVERED
  // COVERED
  int len = string_length(str); // COVERED
  // COVERED
  if (len <= 0) {        // PARTIALLY COVERED
    return false;        // UNCOVERED: Empty string
  } else if (len == 1) { // COVERED
    return true;         // COVERED: Single char is palindrome
  } // COVERED
  // COVERED
  for (int i = 0; i < len / 2; ++i) { // COVERED
    char left = str[i];
    char right = str[len - 1 - i];
    if (left != right) { // COVERED
      return false;      // COVERED: Characters don't match
    } else if (left >= 'a' && left <= 'z' && right >= 'a' &&
               right <= 'z') { // PARTIALLY COVERED
      continue;
    } else if ((left >= 'A' && left <= 'Z') &&
               (right >= 'A' && right <= 'Z')) { // UNCOVERED
      continue;
    } // COVERED
  } // COVERED
  return true; // COVERED: String is palindrome
}

int string_length(const char *str) { // COVERED
  if (str == nullptr) {              // PARTIALLY COVERED
    return 0;                        // UNCOVERED: Null pointer
  } // COVERED
  // COVERED
  int len = 0;               // COVERED
  while (str[len] != '\0') { // COVERED
    len++;
  } // COVERED
  return len; // COVERED: Final length
}
} // namespace MathUtils

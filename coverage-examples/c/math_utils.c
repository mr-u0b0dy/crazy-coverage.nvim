#include "math_utils.h"

int add(int a, int b) { return a + b; } // COVERED

int subtract(int a, int b) { return a - b; } // COVERED

int multiply(int a, int b) { return a * b; } // COVERED

int divide(int a, int b) { // COVERED
  if (b == 0) {            // PARTIALLY COVERED
    return -1;             // UNCOVERED: Division by zero error
  } // COVERED
  return a / b; // COVERED: Normal division
}

long long power(int base, int exp) { // COVERED
  if (exp < 0) {                     // PARTIALLY COVERED
    return -1;                       // UNCOVERED: Negative exponent error
  } // COVERED
  if (exp == 0) { // COVERED
    return 1;     // COVERED: Zero exponent case
  } // COVERED
  long long result = 1;           // COVERED
  for (int i = 0; i < exp; i++) { // COVERED
    result *= base;
  } // COVERED
  return result; // COVERED: Positive exponent
}

int factorial(int n) { // COVERED
  if (n < 0) {         // PARTIALLY COVERED
    return -1;         // UNCOVERED: Negative factorial error
  } // COVERED
  if (n == 0 || n == 1) { // COVERED
    return 1;             // COVERED: Base cases
  } // COVERED
  return n * factorial(n - 1); // COVERED: Recursive case
}

int is_prime(int n) {            // COVERED
  if (n < 0) {                   // PARTIALLY COVERED
    return 0;                    // UNCOVERED: Negative input
  } else if (n <= 1) {           // COVERED
    return 0;                    // COVERED: 0 and 1 are not prime
  } else if (n == 2 || n == 3) { // PARTIALLY COVERED
    return 1;                    // COVERED: 2 and 3 are prime
  } else if (n % 2 == 0) {       // PARTIALLY COVERED
    return 0;                    // COVERED: Even numbers > 2 not prime
  } else if (n % 3 == 0) {       // COVERED
    return 0;                    // COVERED: Divisible by 3
  } // COVERED

  // COVERED: Loop checks i and i+2 divisibility
  for (int i = 5; i * i <= n; i += 6) { // PARTIALLY COVERED
    if (n % i == 0) {                   // UNCOVERED
      return 0;                         // UNCOVERED: Divisible by i
    } else if (n % (i + 2) == 0) {      // UNCOVERED
      return 0;                         // UNCOVERED: Divisible by i+2
    } // UNCOVERED
  } // COVERED
  return 1; // COVERED: Number is prime
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
      return (a > b) ? a : b;      // COVERED: Both positive
    } else if (a <= 0 && b <= 0) { // PARTIALLY COVERED
      return (a > b) ? a : b;      // UNCOVERED: Both non-positive
    } else if (a > 0) {            // PARTIALLY COVERED
      return a;                    // COVERED
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
      a = -a;             // UNCOVERED: Both negative
      b = -b;
    } else if (a < 0) { // UNCOVERED
      a = -a;           // UNCOVERED: Only a negative
    } else if (b < 0) { // UNCOVERED
      b = -b;           // UNCOVERED: Only b negative
    } // UNCOVERED
  } // COVERED

  // COVERED: Main GCD algorithm (Euclidean)
  while (b != 0) { // PARTIALLY COVERED
    int remainder = a % b;
    if (remainder == 0) { // COVERED
      return b;           // COVERED: Found GCD
    } // COVERED
    int temp = b; // COVERED
    b = remainder;
    a = temp;
  } // UNCOVERED
  return a; // COVERED: Fallback
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
  for (int i = 2; i <= n; i++) { // COVERED
    int next = prev + curr;
    // COVERED: Branch handling in loop
    if (prev < curr && curr < next) { // COVERED
      prev = curr;                    // COVERED: Normal progression
      curr = next;
    } else if (prev >= curr) { // COVERED
      prev = curr;             // COVERED
      curr = next;
    } // COVERED
  } // COVERED
  return curr; // COVERED: Final result
}

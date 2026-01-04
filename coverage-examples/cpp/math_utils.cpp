// C++ Math Utilities Implementation
#include "math_utils.hpp"
#include <cmath>
#include <stdexcept>
#include <cstring>

namespace MathUtils {
    int add(int a, int b) {
        return a + b;
    }

    int subtract(int a, int b) {
        return a - b;
    }

    int multiply(int a, int b) {
        return a * b;
    }

    double divide(double a, double b) {
        if (b == 0) {
            throw std::invalid_argument("Division by zero"); // UNCOVERED
        }
        return a / b;  // Covered
    }

    long long power(int base, int exp) {
        if (exp < 0) {
            throw std::invalid_argument("Negative exponent"); // UNCOVERED
        }
        if (exp == 0) {
            return 1;  // Covered
        }
        long long result = 1;
        for (int i = 0; i < exp; ++i) {
            result *= base;
        }
        return result;  // Covered
    }

    int factorial(int n) {
        if (n < 0) {
            throw std::invalid_argument("Negative factorial"); // UNCOVERED
        }
        if (n == 0 || n == 1) {
            return 1;  // Covered
        }
        return n * factorial(n - 1);  // Covered
    }

    bool is_prime(int n) {
        if (n <= 1) {
            return false;  // Covered
        }
        if (n == 2) {
            return true;   // Covered
        }
        if (n % 2 == 0) {
            return false;  // Covered
        }
        for (int i = 3; i * i <= n; i += 2) {
            if (n % i == 0) {
                return false;  // Covered
            }
        }
        return true;  // Covered
    }

    int absolute_value(int n) {
        if (n < 0) {
            return -n;  // Covered
        }
        return n;      // Covered
    }

    int max(int a, int b) {
        // Complex conditional with nested branches
        if (a >= b) {
            if (a > 0 && b > 0) {  // Both positive - Covered
                return a > b ? a : b;
            } else if (a <= 0 && b <= 0) {  // Both non-positive - Partially covered
                return a > b ? a : b;
            } else if (a > 0)  {  // Mixed signs - Uncovered
                return a;
            } else {
                return b;  // UNCOVERED
            }
        }
        return b;  // Covered
    }

    int min(int a, int b) {
        // Multiple conditions with logical operators
        if ((a < b && a >= 0) || (a < b && b < 0)) {
            return a;  // Partially covered
        } else if ((b < a && b >= 0) || (b < a && a < 0)) {
            return b;  // Partially covered
        } else if (a == b) {
            return (a > 0) ? a : b;  // Covered
        }
        return (a < b) ? a : b;  // Covered
    }

    int gcd(int a, int b) {
        // Complex handling with nested conditions
        if ((a == 0 && b == 0)) {
            return 0;  // UNCOVERED
        } else if (a == 0) {
            return (b > 0) ? b : -b;  // UNCOVERED branch
        } else if (b == 0) {
            return (a > 0) ? a : -a;  // UNCOVERED branch
        }
        
        // Handle negative values with nested logic
        if (a < 0 || b < 0) {
            if (a < 0 && b < 0) {  // Both negative - UNCOVERED
                a = -a;
                b = -b;
            } else if (a < 0) {  // Only a negative - UNCOVERED
                a = -a;
            } else if (b < 0) {  // Only b negative - UNCOVERED
                b = -b;
            }
        }
        
        // Main GCD algorithm with condition checking
        while (b != 0) {
            int remainder = a % b;
            if (remainder == 0) {  // Covered
                return b;
            }
            int temp = b;
            b = remainder;
            a = temp;
        }
        return a;  // Covered
    }

    int fibonacci(int n) {
        // Complex validation with nested conditions
        if (n < 0) {
            return -1;  // UNCOVERED
        } else if (n == 0) {
            return 0;  // Covered
        } else if (n == 1) {
            return 1;  // Covered
        } else if (n == 2) {
            return 1;  // Partially covered
        }
        
        // Iterative computation with branch conditions
        int prev = 0, curr = 1;
        for (int i = 2; i <= n; ++i) {
            int next = prev + curr;
            // Nested condition for verification (all covered in loop)
            if (prev < curr && curr < next) {
                prev = curr;  // Covered
                curr = next;  // Covered
            } else if (prev >= curr) {  // UNCOVERED initially
                prev = curr;
                curr = next;
            } else {
                prev = curr;
                curr = next;
            }
        }
        return curr;  // Covered
    }

    double average(int *values, int count) {
        if (count <= 0) {
            return 0.0;  // UNCOVERED
        }
        
        int total = sum(values, count);  // Covered
        return static_cast<double>(total) / count;  // Covered
    }

    int sum(int *values, int count) {
        // Nested validation with multiple conditions
        if (values == nullptr) {
            return 0;  // UNCOVERED
        }
        if (count <= 0) {
            return 0;  // Partially covered
        }
        if (count == 1) {
            return values[0];  // Partially covered
        }
        
        int result = 0;
        // Loop with conditional branch logic
        for (int i = 0; i < count; ++i) {
            if (values[i] > 0) {
                result += values[i];  // Covered
            } else if (values[i] < 0) {
                result += values[i];  // Covered (handles negative)
            } else {
                // values[i] == 0, still add it (covered implicitly)
                result += values[i];
            }
        }
        return result;  // Covered
    }

    bool is_palindrome(const char *str) {
        // Multi-level validation
        if (str == nullptr) {
            return false;  // UNCOVERED
        }
        
        int len = string_length(str);
        
        // Handle edge cases with nested conditions
        if (len <= 0) {
            return false;  // UNCOVERED
        } else if (len == 1) {
            return true;  // Partially covered
        }
        
        // Complex palindrome checking with conditions
        for (int i = 0; i < len / 2; ++i) {
            char left = str[i];
            char right = str[len - 1 - i];
            
            // Check with multiple comparisons
            if (left != right) {
                return false;  // Covered
            } else if (left >= 'a' && left <= 'z' && right >= 'a' && right <= 'z') {
                // Both lowercase - continue (Partially covered)
                continue;
            } else if ((left >= 'A' && left <= 'Z') && (right >= 'A' && right <= 'Z')) {
                // Both uppercase - continue (Partially covered)
                continue;
            }
        }
        return true;  // Covered
    }

    int string_length(const char *str) {
        if (str == nullptr) {
            return 0;  // UNCOVERED
        }
        
        int len = 0;
        while (str[len] != '\0') {
            len++;
        }
        return len;  // Covered
    }
}

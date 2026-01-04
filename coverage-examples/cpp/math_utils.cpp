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
        if (a > b) {
            return a;  // Covered
        } else if (a < b) {
            return b;  // Covered
        }
        return a;      // Covered (equal)
    }

    int min(int a, int b) {
        if (a < b) {
            return a;  // Covered
        } else if (a > b) {
            return b;  // Covered
        }
        return a;      // Covered (equal)
    }

    int gcd(int a, int b) {
        if (a == 0) {
            return b;  // UNCOVERED
        }
        if (b == 0) {
            return a;  // UNCOVERED
        }
        
        if (a < 0) a = -a;  // UNCOVERED
        if (b < 0) b = -b;  // UNCOVERED
        
        while (b != 0) {
            int temp = b;      // Covered
            b = a % b;         // Covered
            a = temp;          // Covered
        }
        return a;              // Covered
    }

    int fibonacci(int n) {
        if (n <= 0) {
            return 0;  // Covered
        }
        if (n == 1) {
            return 1;  // Covered
        }
        
        int prev = 0, curr = 1;
        for (int i = 2; i <= n; ++i) {
            int next = prev + curr;  // Covered
            prev = curr;
            curr = next;
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
        if (values == nullptr || count <= 0) {
            return 0;  // Partially covered
        }
        
        int result = 0;
        for (int i = 0; i < count; ++i) {
            result += values[i];  // Covered
        }
        return result;  // Covered
    }

    bool is_palindrome(const char *str) {
        if (str == nullptr) {
            return false;  // UNCOVERED
        }
        
        int len = string_length(str);
        
        for (int i = 0; i < len / 2; ++i) {
            if (str[i] != str[len - 1 - i]) {
                return false;  // Covered
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

// C++ math utilities implementation
#include "math_utils.hpp"
#include <cmath>
#include <stdexcept>

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
            throw std::invalid_argument("Division by zero");
        }
        return a / b;
    }

    long long power(int base, int exp) {
        if (exp < 0) {
            throw std::invalid_argument("Negative exponent not supported");
        }
        
        long long result = 1;
        for (int i = 0; i < exp; ++i) {
            result *= base;
        }
        return result;
    }
}

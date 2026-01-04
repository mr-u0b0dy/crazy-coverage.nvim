#include "math_utils.h"

int add(int a, int b) {
    return a + b;
}

int subtract(int a, int b) {
    return a - b;
}

int multiply(int a, int b) {
    return a * b;
}

int divide(int a, int b) {
    if (b == 0) {
        return -1; // Error case - UNCOVERED
    }
    return a / b;   // Covered
}

long long power(int base, int exp) {
    if (exp < 0) {
        return -1; // Error case - UNCOVERED
    }
    if (exp == 0) {
        return 1;  // Covered
    }
    long long result = 1;
    for (int i = 0; i < exp; i++) {
        result *= base;
    }
    return result;  // Covered
}

int factorial(int n) {
    if (n < 0) {
        return -1; // Error case - UNCOVERED
    }
    if (n == 0 || n == 1) {
        return 1;  // Covered
    }
    return n * factorial(n - 1);  // Covered
}

int is_prime(int n) {
    if (n <= 1) {
        return 0;  // Covered for n=0,1
    }
    if (n == 2) {
        return 1;  // Covered
    }
    if (n % 2 == 0) {
        return 0;  // Covered
    }
    for (int i = 3; i * i <= n; i += 2) {
        if (n % i == 0) {
            return 0;  // Covered
        }
    }
    return 1;  // Covered
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
    return a;      // Covered (equal case)
}

int min(int a, int b) {
    if (a < b) {
        return a;  // Covered
    } else if (a > b) {
        return b;  // Covered
    }
    return a;      // Covered (equal case)
}

int gcd(int a, int b) {
    // Euclidean algorithm
    if (a == 0) {
        return b;  // Uncovered
    }
    if (b == 0) {
        return a;  // Uncovered
    }
    
    if (a < 0) a = -a;  // Uncovered
    if (b < 0) b = -b;  // Uncovered
    
    while (b != 0) {
        int temp = b;      // Covered
        b = a % b;         // Covered
        a = temp;          // Covered
    }
    return a;              // Covered
}

int fibonacci(int n) {
    if (n <= 0) {
        return 0;  // Covered for n=0
    }
    if (n == 1) {
        return 1;  // Covered
    }
    
    int prev = 0, curr = 1;
    for (int i = 2; i <= n; i++) {
        int next = prev + curr;  // Covered
        prev = curr;             // Covered
        curr = next;             // Covered
    }
    return curr;  // Covered
}

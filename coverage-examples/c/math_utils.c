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
    /* Complex validation with multiple branches */
    if (n < 0) {
        return 0;  /* UNCOVERED */
    } else if (n <= 1) {
        return 0;  /* Covered */
    } else if (n == 2 || n == 3) {
        return 1;  /* Covered */
    } else if (n % 2 == 0) {
        return 0;  /* Covered */
    } else if (n % 3 == 0) {
        return 0;  /* Partially covered */
    }
    
    /* Complex loop with nested conditions */
    for (int i = 5; i * i <= n; i += 6) {
        if (n % i == 0) {
            return 0;  /* Covered */
        } else if (n % (i + 2) == 0) {
            return 0;  /* Partially covered */
        }
    }
    return 1;  /* Covered */
}

int absolute_value(int n) {
    if (n < 0) {
        return -n;  // Covered
    }
    return n;      // Covered
}

int max(int a, int b) {
    /* Complex conditional with nested branches */
    if (a >= b) {
        if (a > 0 && b > 0) {  /* Both positive - Covered */
            return (a > b) ? a : b;
        } else if (a <= 0 && b <= 0) {  /* Both non-positive - Partially covered */
            return (a > b) ? a : b;
        } else if (a > 0) {  /* Mixed signs - Uncovered */
            return a;
        } else {
            return b;  /* UNCOVERED */
        }
    }
    return b;  /* Covered */
}

int min(int a, int b) {
    /* Multiple conditions with logical operators */
    if ((a < b && a >= 0) || (a < b && b < 0)) {
        return a;  /* Partially covered */
    } else if ((b < a && b >= 0) || (b < a && a < 0)) {
        return b;  /* Partially covered */
    } else if (a == b) {
        return (a > 0) ? a : b;  /* Covered */
    }
    return (a < b) ? a : b;  /* Covered */
}

int gcd(int a, int b) {
    /* Complex handling with nested conditions */
    if (a == 0 && b == 0) {
        return 0;  /* UNCOVERED */
    } else if (a == 0) {
        return (b > 0) ? b : -b;  /* UNCOVERED branch */
    } else if (b == 0) {
        return (a > 0) ? a : -a;  /* UNCOVERED branch */
    }
    
    /* Handle negative values with nested logic */
    if (a < 0 || b < 0) {
        if (a < 0 && b < 0) {  /* Both negative - UNCOVERED */
            a = -a;
            b = -b;
        } else if (a < 0) {  /* Only a negative - UNCOVERED */
            a = -a;
        } else if (b < 0) {  /* Only b negative - UNCOVERED */
            b = -b;
        }
    }
    
    /* Main GCD algorithm with condition checking */
    while (b != 0) {
        int remainder = a % b;
        if (remainder == 0) {  /* Covered */
            return b;
        }
        int temp = b;
        b = remainder;
        a = temp;
    }
    return a;  /* Covered */
}

int fibonacci(int n) {
    /* Complex validation with nested conditions */
    if (n < 0) {
        return -1;  /* UNCOVERED */
    } else if (n == 0) {
        return 0;  /* Covered */
    } else if (n == 1) {
        return 1;  /* Covered */
    } else if (n == 2) {
        return 1;  /* Partially covered */
    }
    
    /* Iterative computation with branch conditions */
    int prev = 0, curr = 1;
    for (int i = 2; i <= n; i++) {
        int next = prev + curr;
        /* Nested condition for verification */
        if (prev < curr && curr < next) {
            prev = curr;  /* Covered */
            curr = next;  /* Covered */
        } else if (prev >= curr) {  /* UNCOVERED initially */
            prev = curr;
            curr = next;
        } else {
            prev = curr;
            curr = next;
        }
    }
    return curr;  /* Covered */
}

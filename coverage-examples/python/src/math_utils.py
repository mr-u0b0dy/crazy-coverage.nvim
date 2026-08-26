"""Sample module with branches, loops, and recursion for coverage demos.

Mirrors coverage-examples/c/math_utils.c: enough functions, branches, and
loops that running the test suite leaves some paths intentionally
uncovered/partially covered, so crazy-coverage.nvim has something to show.
"""


def add(left, right):  # COVERED
    return left + right  # COVERED


def subtract(left, right):  # COVERED
    return left - right  # COVERED


def multiply(left, right):  # COVERED
    return left * right  # COVERED


def divide(left, right):  # COVERED
    if right == 0:  # PARTIALLY COVERED
        return None  # UNCOVERED: division by zero
    return left / right  # COVERED: normal division


def power(base, exponent):  # COVERED
    if exponent < 0:  # PARTIALLY COVERED
        return None  # UNCOVERED: negative exponent error
    if exponent == 0:  # COVERED
        return 1  # COVERED: zero exponent case
    result = 1  # COVERED
    for _ in range(exponent):  # COVERED
        result *= base
    return result  # COVERED: positive exponent


def factorial(n):  # COVERED
    if n < 0:  # PARTIALLY COVERED
        return None  # UNCOVERED: negative factorial error
    if n in (0, 1):  # COVERED
        return 1  # COVERED: base cases
    return n * factorial(n - 1)  # COVERED: recursive case


def is_prime(n):  # COVERED
    if n < 0:  # PARTIALLY COVERED
        return False  # UNCOVERED: negative input
    if n <= 1:  # COVERED
        return False  # COVERED: 0 and 1 are not prime
    if n in (2, 3):  # COVERED
        return True  # COVERED: 2 and 3 are prime
    if n % 2 == 0:  # COVERED
        return False  # UNCOVERED: even numbers > 2 not prime
    if n % 3 == 0:  # COVERED
        return False  # COVERED: divisible by 3

    i = 5  # COVERED
    while i * i <= n:  # PARTIALLY COVERED: loop entered zero times by the tests below
        if n % i == 0 or n % (i + 2) == 0:  # UNCOVERED
            return False  # UNCOVERED: divisible by i or i+2
        i += 6  # UNCOVERED
    return True  # COVERED: number is prime


def absolute_value(n):  # COVERED
    if n < 0:  # COVERED
        return -n  # COVERED: negative input
    return n  # COVERED: non-negative input


def max_value(a, b):  # COVERED
    if a >= b:  # COVERED
        if a > 0 and b > 0:  # COVERED
            return a if a > b else b  # COVERED: both positive
        if a <= 0 and b <= 0:  # PARTIALLY COVERED
            return a if a > b else b  # UNCOVERED: both non-positive
        if a > 0:  # COVERED
            return a  # COVERED: mixed signs, a positive
        return b  # UNCOVERED: mixed signs, a negative
    return b  # COVERED: b >= a case


def min_value(a, b):  # COVERED
    if (a < b and a >= 0) or (a < b and b < 0):  # PARTIALLY COVERED
        return a  # COVERED
    if (b < a and b >= 0) or (b < a and a < 0):  # PARTIALLY COVERED
        return b  # COVERED
    if a == b:  # COVERED
        return a if a > 0 else b  # PARTIALLY COVERED: equal values
    return a if a < b else b  # PARTIALLY COVERED: fallback


def gcd(a, b):  # COVERED
    if a == 0 and b == 0:  # PARTIALLY COVERED
        return 0  # UNCOVERED: both zero
    if a == 0:  # PARTIALLY COVERED
        return b if b > 0 else -b  # UNCOVERED: a is zero
    if b == 0:  # PARTIALLY COVERED
        return a if a > 0 else -a  # UNCOVERED: b is zero

    if a < 0 or b < 0:  # PARTIALLY COVERED
        if a < 0 and b < 0:  # UNCOVERED
            a, b = -a, -b  # UNCOVERED: both negative
        elif a < 0:  # UNCOVERED
            a = -a  # UNCOVERED: only a negative
        elif b < 0:  # UNCOVERED
            b = -b  # UNCOVERED: only b negative

    while b != 0:  # COVERED: Euclidean algorithm
        a, b = b, a % b
    return a  # COVERED: found GCD


def fibonacci(n):  # COVERED
    if n < 0:  # PARTIALLY COVERED
        return None  # UNCOVERED: negative input
    if n == 0:  # COVERED
        return 0  # COVERED: base case F(0)=0
    if n == 1:  # COVERED
        return 1  # COVERED: base case F(1)=1
    if n == 2:  # PARTIALLY COVERED
        return 1  # UNCOVERED: base case F(2)=1

    prev, curr = 0, 1  # COVERED
    for _ in range(2, n + 1):  # COVERED
        prev, curr = curr, prev + curr  # COVERED: iterative progression
    return curr  # COVERED: final result


def sum_range(n):
    """Hit count demo: loop body hit ~500 times -> sign shows '5+'."""
    total = 0
    for i in range(1, n + 1):
        total += i
    return total


def count_pairs(n):
    """Hit count demo: inner loop body hit ~4950 times -> sign shows '4k'."""
    count = 0
    for i in range(n):
        for j in range(i + 1, n):
            count += 1
    return count


def classify_number(value):  # COVERED
    if value > 0:  # COVERED
        if value % 2 == 0:  # PARTIALLY COVERED
            return "positive-even"  # UNCOVERED
        return "positive-odd"  # COVERED
    if value < 0:  # COVERED
        if value % 2 == 0:  # PARTIALLY COVERED
            return "negative-even"  # UNCOVERED
        return "negative-odd"  # COVERED
    return "zero"  # UNCOVERED: no test exercises the zero case

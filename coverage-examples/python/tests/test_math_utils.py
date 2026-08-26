from math_utils import (
    absolute_value,
    add,
    classify_number,
    count_pairs,
    divide,
    factorial,
    fibonacci,
    gcd,
    is_prime,
    max_value,
    min_value,
    multiply,
    power,
    subtract,
    sum_range,
)


def test_add():
    assert add(15, 7) == 22


def test_subtract():
    assert subtract(15, 7) == 8


def test_multiply():
    assert multiply(15, 7) == 105
    assert multiply(4, 5) == 20


def test_divide():
    # Only the non-zero-divisor branch is exercised; the "right == 0" guard
    # is left uncovered on purpose, mirroring coverage-examples/c.
    assert divide(20, 4) == 5


def test_power():
    assert power(2, 8) == 256
    assert power(3, 0) == 1
    assert power(5, 2) == 25


def test_factorial():
    assert factorial(5) == 120
    assert factorial(0) == 1
    assert factorial(1) == 1


def test_is_prime():
    assert is_prime(7) is True
    assert is_prime(2) is True
    assert is_prime(15) is False
    assert is_prime(1) is False
    assert is_prime(11) is True
    assert is_prime(9) is False


def test_absolute_value():
    assert absolute_value(10) == 10
    assert absolute_value(-15) == 15
    assert absolute_value(0) == 0


def test_max_value():
    assert max_value(10, 20) == 20
    assert max_value(30, 15) == 30
    assert max_value(5, 5) == 5
    assert max_value(-5, -2) == -2
    assert max_value(8, -3) == 8


def test_min_value():
    assert min_value(10, 20) == 10
    assert min_value(30, 15) == 15
    assert min_value(5, 5) == 5
    assert min_value(-5, -2) == -5
    assert min_value(8, -3) == -3


def test_gcd():
    assert gcd(12, 18) == 6
    assert gcd(7, 11) == 1
    assert gcd(100, 50) == 50
    assert gcd(21, 14) == 7


def test_fibonacci():
    assert fibonacci(0) == 0
    assert fibonacci(1) == 1
    assert fibonacci(5) == 5
    assert fibonacci(8) == 21
    assert fibonacci(10) == 55


def test_hit_count_demo_ranges():
    # Hit count range demos: sum_range's loop body runs 500 times (sign "5+"),
    # count_pairs' inner loop body runs 4950 times (sign "4k").
    assert sum_range(500) == 500 * 501 // 2
    assert count_pairs(100) == 100 * 99 // 2


def test_classify_positive():
    assert classify_number(3) == "positive-odd"


def test_classify_negative():
    assert classify_number(-3) == "negative-odd"

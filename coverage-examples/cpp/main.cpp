// C++ example source - main.cpp
#include <iostream>
#include "math_utils.hpp"

int main() {
    std::cout << "=== C++ Math Utilities Coverage Example ===" << std::endl;
    std::cout << std::endl;

    // Test addition
    std::cout << "Testing addition:" << std::endl;
    std::cout << "  10 + 5 = " << MathUtils::add(10, 5) << std::endl;
    std::cout << "  -3 + 7 = " << MathUtils::add(-3, 7) << std::endl;
    std::cout << std::endl;

    // Test subtraction
    std::cout << "Testing subtraction:" << std::endl;
    std::cout << "  10 - 5 = " << MathUtils::subtract(10, 5) << std::endl;
    std::cout << "  3 - 8 = " << MathUtils::subtract(3, 8) << std::endl;
    std::cout << std::endl;

    // Test multiplication
    std::cout << "Testing multiplication:" << std::endl;
    std::cout << "  6 * 7 = " << MathUtils::multiply(6, 7) << std::endl;
    std::cout << "  -4 * 3 = " << MathUtils::multiply(-4, 3) << std::endl;
    std::cout << std::endl;

    // Test division (only covered case)
    std::cout << "Testing division:" << std::endl;
    std::cout << "  20 / 4 = " << MathUtils::divide(20, 4) << std::endl;
    std::cout << "  15 / 3 = " << MathUtils::divide(15, 3) << std::endl;
    // Division by zero is NOT tested, so that error path has no coverage
    std::cout << std::endl;

    // Test power
    std::cout << "Testing power:" << std::endl;
    std::cout << "  2 ^ 8 = " << MathUtils::power(2, 8) << std::endl;
    std::cout << "  5 ^ 3 = " << MathUtils::power(5, 3) << std::endl;
    std::cout << std::endl;

    std::cout << "=== Tests completed ===" << std::endl;

    return 0;
}

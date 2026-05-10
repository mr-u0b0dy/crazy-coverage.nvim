use crazy_coverage_rust_example::{
    add, categorize_number, calculate_grade, classify, divide, fibonacci, multiply, sum_range,
    validate_username,
};

#[test]
fn test_add() {
    assert_eq!(add(2, 3), 5);
}

#[test]
fn test_multiply() {
    assert_eq!(multiply(4, 5), 20);
}

#[test]
fn test_divide() {
    assert_eq!(divide(10, 2), 5);
}

#[test]
fn test_classify() {
    assert_eq!(classify(-2), "negative");
    assert_eq!(classify(0), "zero");
    assert_eq!(classify(4), "even");
}

// Grade calculation tests - intentionally leaving D and F grades untested
#[test]
fn test_calculate_grade_a() {
    assert_eq!(calculate_grade(95), 'A');
    assert_eq!(calculate_grade(90), 'A');
}

#[test]
fn test_calculate_grade_b() {
    assert_eq!(calculate_grade(85), 'B');
    assert_eq!(calculate_grade(80), 'B');
}

#[test]
fn test_calculate_grade_c() {
    assert_eq!(calculate_grade(75), 'C');
    assert_eq!(calculate_grade(70), 'C');
}

// NOTE: D (60-69) and F (<60) grades are NOT tested, creating coverage gaps

#[test]
fn test_calculate_grade_invalid() {
    assert_eq!(calculate_grade(-5), 'X');
    assert_eq!(calculate_grade(105), 'X');
}

// Fibonacci tests - intentionally leaving large values and overflow untested
#[test]
fn test_fibonacci_base() {
    assert_eq!(fibonacci(0), 0);
    assert_eq!(fibonacci(1), 1);
    assert_eq!(fibonacci(2), 1);
}

#[test]
fn test_fibonacci_small() {
    assert_eq!(fibonacci(3), 2);
    assert_eq!(fibonacci(4), 3);
    assert_eq!(fibonacci(5), 5);
}

// NOTE: fibonacci(n > 8) and overflow case n > 50 are NOT tested

// Sum range tests - intentionally incomplete coverage
#[test]
fn test_sum_range_basic() {
    assert_eq!(sum_range(1, 5), 15); // 1+2+3+4+5
}

#[test]
fn test_sum_range_same() {
    assert_eq!(sum_range(5, 5), 5);
}

#[test]
fn test_sum_range_invalid() {
    assert_eq!(sum_range(10, 5), -1);
}

// NOTE: Ranges with negative numbers (the continue branch) not fully tested
// NOTE: The break statement for numbers > 100 not tested

// Username validation tests - happy path and some error cases
#[test]
fn test_validate_username_valid() {
    assert!(validate_username("alice").is_ok());
    assert!(validate_username("bob123").is_ok());
    assert!(validate_username("user_name-123").is_ok());
}

#[test]
fn test_validate_username_empty() {
    assert!(validate_username("").is_err());
}

#[test]
fn test_validate_username_too_short() {
    assert!(validate_username("ab").is_err());
}

#[test]
fn test_validate_username_too_long() {
    assert!(validate_username("this_is_a_very_long_username_over_20_chars").is_err());
}

#[test]
fn test_validate_username_invalid_start() {
    assert!(validate_username("_alice").is_err());
    assert!(validate_username("123bob").is_err());
}

#[test]
fn test_validate_username_reserved() {
    assert!(validate_username("admin").is_err());
    assert!(validate_username("root").is_err());
}

// NOTE: Invalid character case (like "alice@test") not tested

// Number categorization tests - subset of numbers
#[test]
fn test_categorize_number_negative() {
    let cats = categorize_number(-5);
    assert!(cats.contains(&"negative"));
    assert!(cats.contains(&"odd"));
}

#[test]
fn test_categorize_number_zero() {
    let cats = categorize_number(0);
    assert!(cats.contains(&"zero"));
    assert!(cats.contains(&"even"));
}

#[test]
fn test_categorize_number_prime() {
    let cats = categorize_number(7);
    assert!(cats.contains(&"positive"));
    assert!(cats.contains(&"odd"));
    assert!(cats.contains(&"prime"));
}

#[test]
fn test_categorize_number_even() {
    let cats = categorize_number(12);
    assert!(cats.contains(&"positive"));
    assert!(cats.contains(&"even"));
}

#[test]
fn test_categorize_number_perfect_square() {
    let cats = categorize_number(16);
    assert!(cats.contains(&"perfect_square"));
    assert!(cats.contains(&"power_of_two"));
}

#[test]
fn test_categorize_number_factorial() {
    let cats = categorize_number(120);
    assert!(cats.contains(&"factorial"));
    assert!(cats.contains(&"even"));
}

// NOTE: Not all perfect squares tested (e.g., 9, 25, 49)
// NOTE: Not all power of two values tested
// NOTE: Prime number edge cases (small primes, large primes in range) not fully tested
// NOTE: Negative perfect square logic (sqrt of negative) not tested

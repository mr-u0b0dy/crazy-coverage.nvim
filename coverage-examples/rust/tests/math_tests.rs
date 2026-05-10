use crazy_coverage_rust_example::{add, classify, divide, multiply};

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

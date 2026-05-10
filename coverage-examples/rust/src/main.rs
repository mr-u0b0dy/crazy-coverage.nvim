use crazy_coverage_rust_example::{
    add, categorize_number, calculate_grade, classify, divide, fibonacci, multiply, sum_range,
    validate_username,
};

fn main() {
    println!("=== Basic Operations ===");
    println!("add(2, 3): {}", add(2, 3));
    println!("multiply(4, 5): {}", multiply(4, 5));
    println!("divide(10, 2): {}", divide(10, 2));
    println!("classify(7): {}", classify(7));

    println!("\n=== Grade Calculation ===");
    let scores = [95, 87, 75, 62, 45, 105, -5];
    for score in scores.iter() {
        println!("Grade for score {}: {}", score, calculate_grade(*score));
    }

    println!("\n=== Fibonacci Sequence ===");
    for n in 0..=8 {
        println!("fibonacci({}): {}", n, fibonacci(n));
    }

    println!("\n=== Sum Ranges ===");
    println!("sum_range(1, 5): {}", sum_range(1, 5));
    println!("sum_range(10, 15): {}", sum_range(10, 15));
    println!("sum_range(20, 10): {}", sum_range(20, 10));
    println!("sum_range(-5, 5): {}", sum_range(-5, 5));

    println!("\n=== Username Validation ===");
    let usernames = ["alice", "bob123", "a", "admin", "user_name-123"];
    for username in usernames.iter() {
        match validate_username(username) {
            Ok(()) => println!("'{}': Valid", username),
            Err(e) => println!("'{}': {}", username, e),
        }
    }

    println!("\n=== Number Categorization ===");
    let numbers = [-5, 0, 7, 12, 16, 25, 97, 120];
    for num in numbers.iter() {
        let categories = categorize_number(*num);
        println!("{}: {:?}", num, categories);
    }
}

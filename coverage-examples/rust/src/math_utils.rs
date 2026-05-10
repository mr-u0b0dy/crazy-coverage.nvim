pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn multiply(a: i32, b: i32) -> i32 {
    a * b
}

pub fn divide(a: i32, b: i32) -> i32 {
    if b == 0 {
        return 0;
    }
    a / b
}

pub fn is_even(n: i32) -> bool {
    n % 2 == 0
}

pub fn classify(n: i32) -> &'static str {
    if n < 0 {
        return "negative";
    }
    if n == 0 {
        return "zero";
    }
    if n % 2 == 0 {
        return "even";
    }
    "odd"
}

// Calculate letter grade based on score
// Multiple condition branches for coverage demonstration
pub fn calculate_grade(score: i32) -> char {
    if score < 0 || score > 100 {
        return 'X'; // Invalid
    }
    if score >= 90 {
        return 'A';
    }
    if score >= 80 {
        return 'B';
    }
    if score >= 70 {
        return 'C';
    }
    if score >= 60 {
        return 'D';
    }
    'F'
}

// Fibonacci with recursion and base cases
// Demonstrates recursion with partial coverage
pub fn fibonacci(n: u32) -> u64 {
    if n == 0 {
        return 0;
    }
    if n == 1 {
        return 1;
    }
    if n == 2 {
        return 1;
    }
    if n > 50 {
        return 0; // Prevent overflow
    }
    fibonacci(n - 1) + fibonacci(n - 2)
}

// Sum a range with conditional logic and early exit
// Demonstrates loop coverage with branches
pub fn sum_range(start: i32, end: i32) -> i32 {
    if start > end {
        return -1; // Error case
    }
    if start == end {
        return start;
    }

    let mut sum = 0;
    let mut i = start;
    while i <= end {
        if i < 0 && i % 2 == 0 {
            // Skip even negative numbers
            i += 1;
            continue;
        }
        if i > 100 {
            // Early exit for large numbers
            break;
        }
        sum += i;
        i += 1;
    }
    sum
}

// Validate username with nested conditions
// Multiple validation checks with partial coverage
pub fn validate_username(name: &str) -> Result<(), &'static str> {
    if name.is_empty() {
        return Err("Username cannot be empty");
    }

    if name.len() < 3 {
        return Err("Username must be at least 3 characters");
    }

    if name.len() > 20 {
        return Err("Username must be at most 20 characters");
    }

    if !name.chars().next().unwrap().is_alphabetic() {
        return Err("Username must start with a letter");
    }

    for c in name.chars() {
        if !c.is_alphanumeric() && c != '_' && c != '-' {
            return Err("Username can only contain letters, numbers, _, and -");
        }
    }

    let reserved = ["admin", "root", "system", "test", "user"];
    if reserved.contains(&name) {
        return Err("Username is reserved");
    }

    Ok(())
}

// Categorize a number into multiple categories
// Demonstrates multiple conditions and looping
pub fn categorize_number(n: i32) -> Vec<&'static str> {
    let mut categories = Vec::new();

    if n < 0 {
        categories.push("negative");
    } else if n == 0 {
        categories.push("zero");
    } else {
        categories.push("positive");
    }

    if n % 2 == 0 {
        categories.push("even");
    } else {
        categories.push("odd");
    }

    // Check if prime (for small positive numbers)
    if n > 1 && n < 100 {
        let mut is_prime = true;
        let mut i = 2;
        while i * i <= n {
            if n % i == 0 {
                is_prime = false;
                break;
            }
            i += 1;
        }
        if is_prime {
            categories.push("prime");
        }
    }

    // Check if perfect square
    if n > 0 {
        let sqrt = (n as f64).sqrt() as i32;
        if sqrt * sqrt == n {
            categories.push("perfect_square");
        }
    }

    // Check if power of two
    if n > 0 && (n & (n - 1)) == 0 {
        categories.push("power_of_two");
    }

    // Check if factorial-like (1, 2, 6, 24, 120)
    let factorials = [1, 2, 6, 24, 120, 720];
    if factorials.contains(&n) {
        categories.push("factorial");
    }

    categories
}

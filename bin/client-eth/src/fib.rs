use openvm::io::{println, read};

fn fibonacci(n: u32) -> u32 {
    let mut a = 0;
    let mut b = 1;
    for _ in 0..n {
        let sum = (a + b) % 7919; // Mod to avoid overflow
        a = b;
        b = sum;
    }
    b
}

pub fn run() {
    println("fib starting");

    // Read the input.
    let n: u32 = read();
    println("finished reading input");

    fibonacci(n);
}

mod fib;
mod reth;
mod tendermint;

pub fn main() {
    #[cfg(feature = "fibonacci")]
    fib::run();
    #[cfg(feature = "tendermint")]
    tendermint::run();
    #[cfg(feature = "reth")]
    reth::run();
}

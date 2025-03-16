## Installation

This project uses Foundry for development and testing. To get started:

1. Clone the repository:
```bash
git clone <your-repo-url>
```

2. Install dependencies:
```bash
git submodule update --init --recursive
forge install
```

This will install:
- forge-std v1.5.3
- OpenZeppelin Contracts v4.9.0

## Development

To build the project:
```bash
forge build
```

To run tests:
```bash
forge test
```

To deploy and verify the contracts on Sepolia:
```bash
forge script script/StakeDeployment.sol:StakeDeployment --rpc-url sepolia --broadcast --verify -vvvv
```

## Deployed Contracts (Sepolia)

- USDe Token: `0xc0192bC852fb7d5fBc9aCF6256afabA606E66607`
- StakedUSDeV2: `0x6df01b418abd71c2510cef6a2298d8e47b88e7c5`

# MinimalAccount + PayMaster (ERC-4337 Smart Wallet w/ USDC Gas Abstraction & Verifier)

This project implements a **minimal ERC-4337 Account Abstraction wallet** paired with a **custom Paymaster** contract that allows users to pay for gas in **USDC**, verified against the current ETH/USD price using **Chainlink oracles**.

---

## ✨ Features

- ✅ ERC-4337 compliant smart account (`MinimalAccount`)
- 🧠 Multi-sig-like execution flow (owner + verifier)
- 💸 Pay gas in **USDC** using a **custom Paymaster**
- 🧮 Real-time price conversion using **Chainlink ETH/USD oracle**
- 🛡️ Security-focused with strict access modifiers (`onlyOwner`, `onlyEntryPoint`)
- 🧰 Built using Foundry, OpenZeppelin, and `account-abstraction` package

---

## 🧱 Contracts

### 🔐 MinimalAccount.sol

Smart contract wallet that implements `IAccount`:

- Validates two signatures: `owner` and `verifier`
- Supports execution of arbitrary `target.call(data)`
- Provides `OnlyEntryPointOrOwner` access control
- Used with EntryPoint to bundle and execute UserOperations

```solidity
constructor(address entryPoint, address verifier) Ownable(msg.sender)
```

### 💸 PayMaster.sol

ERC-4337 `IPaymaster` implementation that allows the user to:

- Pay gas fees in **USDC**, not ETH
- Automatically calculates required USDC based on live ETH/USD price
- Uses Chainlink’s `AggregatorV3Interface` with `staleCheckLastTestRoundData()` for secure price feeds

```solidity
constructor(address _entryPoint, address _usdc, address _ethPriceFeed)
```

---

## 🔄 Signature Verification Flow

```solidity
address signer = ECDSA.recover(toEthSignedMessageHash(userOpHash), sigs[0]);
address signer2 = ECDSA.recover(toEthSignedMessageHash(userOpHash), sigs[1]);
```

A transaction is only valid if:
- `signer == owner()`
- `signer2 == i_verifier`

---

## 💰 USDC Gas Payment Logic

1. `validatePaymasterUserOp`:
    - Gets ETH/USD price via Chainlink
    - Calculates USDC cost of maxGas
    - Verifies sender has sufficient USDC and allowance

2. `postOp`:
    - Transfers USDC from user to Paymaster

---

## 🧪 Deployment Notes

- Deploy `MinimalAccount` with EntryPoint and Verifier addresses
- Deploy `PayMaster` with EntryPoint, USDC, and Chainlink ETH/USD price feed addresses
- Fund the Paymaster using `depositToEntryPoint()` for ETH coverage

---

## 🛠️ Admin Functions

| Function | Description |
|---------|-------------|
| `withdrawTokens()` | Transfer USDC to owner |
| `withdrawEth()` | Withdraw deposited ETH from EntryPoint |
| `depositToEntryPoint()` | Deposit ETH into EntryPoint for covering user ops |

---

## 🔐 Access Control

- Only the **EntryPoint** can call `validatePaymasterUserOp` and `postOp`
- Only the **owner** can withdraw tokens/ETH or interact directly

---

## 📚 Tech Stack

- Solidity `^0.8.20`
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Chainlink ETH/USD Oracle](https://docs.chain.link/)
- [ERC-4337 Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
- [Foundry](https://book.getfoundry.sh/)

---

## 📄 License

MIT

---

## 🙌 Credits

Created by @batublockdev. Special thanks to the OpenZeppelin, Chainlink, and ERC-4337 contributors.

# 🚜➡️🏪 Farm-to-Supermarket Payment

> **Automated payment release system for fresh produce delivery chain** 🌱💰

## 📋 Overview

This smart contract enables secure, automated payments between farmers and supermarkets. Payments are held in escrow and automatically released upon delivery confirmation, ensuring trust and efficiency in the agricultural supply chain.

## ✨ Key Features

- 🔐 **Escrow Protection**: Payments held securely until delivery
- ⚡ **Auto-Release**: Instant payment upon delivery confirmation
- 👥 **Profile System**: Track farmers and supermarkets
- 📊 **Order Tracking**: Complete order lifecycle management
- 🛡️ **Security**: Built-in authorization and validation
- 💱 **STX Integration**: Native Stacks blockchain payments

## 🏗️ Contract Structure

### Data Maps
- **orders**: Complete order information and status
- **farmer-profiles**: Farmer registration and statistics
- **supermarket-profiles**: Supermarket registration and statistics  
- **escrow-balances**: Payment amounts held in escrow

### Order Status Flow
```
📝 pending → ✅ accepted → 🚚 delivered → 💰 completed
                    ↓
                ❌ cancelled
```

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/docs/write-smart-contracts/cli-wallet-quickstart) for deployment

### Installation

1. **Clone and setup**:
   ```bash
   git clone <repo-url>
   cd Farm-to-Supermarket-Payment
   clarinet console
   ```

2. **Deploy contract**:
   ```bash
   clarinet deploy --testnet
   ```

## 📖 Usage Guide

### 1. 👨‍🌾 Farmer Registration

```clarity
(contract-call? .farm-to-supermarket-payment register-farmer "Green Valley Farm" "California, USA")
```

### 2. 🏪 Supermarket Registration

```clarity
(contract-call? .farm-to-supermarket-payment register-supermarket "Fresh Market" "New York, USA")
```

### 3. 📦 Creating an Order (Supermarket)

```clarity
(contract-call? .farm-to-supermarket-payment create-order 
  'ST1FARMER123... ;; farmer principal
  u1000000      ;; amount in microSTX
  "50kg Organic Tomatoes")
```

### 4. ✅ Accepting an Order (Farmer)

```clarity
(contract-call? .farm-to-supermarket-payment accept-order u1)
```

### 5. 🚚 Confirming Delivery (Supermarket)

```clarity
(contract-call? .farm-to-supermarket-payment confirm-delivery u1)
```
*Payment automatically releases to farmer upon confirmation!*

### 6. ❌ Cancelling an Order (Either Party)

```clarity
(contract-call? .farm-to-supermarket-payment cancel-order u1)
```
*Refunds payment to supermarket*

## 🔍 Query Functions

### Get Order Details
```clarity
(contract-call? .farm-to-supermarket-payment get-order u1)
```

### Get Farmer Profile
```clarity
(contract-call? .farm-to-supermarket-payment get-farmer-profile 'ST1FARMER123...)
```

### Get Supermarket Profile
```clarity
(contract-call? .farm-to-supermarket-payment get-supermarket-profile 'ST1MARKET123...)
```

### Get Escrow Balance
```clarity
(contract-call? .farm-to-supermarket-payment get-escrow-balance u1)
```

## 🧪 Testing

### Run Tests
```bash
npm test
# or
vitest
```

### Test Scenarios
- ✅ Complete order flow (create → accept → deliver → payment)
- ❌ Order cancellation and refunds
- 🚫 Unauthorized access attempts
- 📊 Profile statistics updates

## 🔧 Development

### Local Development
```bash
clarinet console
```

### Check Contract Syntax
```bash
clarinet check
```

### Format Code
```bash
clarinet format
```

## 📊 Contract Statistics

- **Lines of Code**: 252 lines
- **Public Functions**: 7
- **Read-Only Functions**: 6
- **Data Maps**: 4
- **Error Codes**: 8

## 🛡️ Security Features

- 🔐 **Access Control**: Only authorized parties can perform actions
- 💰 **Escrow Safety**: Payments protected until delivery
- ✅ **State Validation**: Prevents invalid state transitions
- 🚫 **Double-spend Protection**: Prevents duplicate payments
- 🔄 **Atomic Operations**: All-or-nothing transaction safety

## 🎯 Use Cases

1. **🥬 Fresh Produce**: Vegetables, fruits, herbs
2. **🥛 Dairy Products**: Milk, cheese, yogurt
3. **🥩 Meat & Poultry**: Beef, chicken, pork
4. **🌾 Grains & Cereals**: Wheat, rice, corn
5. **🍯 Specialty Items**: Honey, organic products

## 🔮 Future Enhancements

- 🤖 **IoT Integration**: Temperature/quality sensors
- 📱 **Mobile App**: User-friendly interface
- 🌍 **Multi-location**: Global delivery tracking
- 💳 **Multi-token**: Support for other cryptocurrencies
- 📈 **Analytics**: Supply chain insights

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 📞 Support

For questions or issues, please open a GitHub issue or contact the development team.

---

*Built with ❤️ for the agricultural community* 🌾

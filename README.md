# 🌍 EcoChain – Environmental Material Recovery Incentive

**EcoChain** is a blockchain-based **material recovery and incentive system** designed to promote sustainable waste management practices.
It rewards individuals and organizations for proper **waste sorting**, **depositing**, and **recycling**, thereby supporting **UN SDG 11 – Sustainable Cities and Communities**.

---

## ⚙️ Overview

EcoChain enables transparent, traceable, and rewarding waste recovery through smart contracts on the **Stacks blockchain**.
Users can register, deposit waste at collection stations, earn tokenized rewards, and contribute measurable environmental impact data to the network.

---

## 🎯 Key Features

* 🧍‍♂️ **User Management:** Register and track verified waste contributors.
* 🏭 **Station Management:** Register and manage recycling or composting stations.
* ♻️ **Waste Deposit & Verification:** Deposit waste, auto-calculate rewards, and track verified deposits.
* 🌱 **Environmental Impact Tracking:** Record CO₂, energy, and water savings metrics.
* 🏆 **Community Challenges:** Create and monitor recycling challenges with reward pools.
* 💰 **Incentive Distribution:** Automatically compute and distribute token rewards.
* 📊 **Transparency:** On-chain tracking of waste volumes, users, and reward distributions.

---

## 🧩 Smart Contract Architecture

### **1. Core Entities**

| Entity                  | Description                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| **Waste Users**         | Registered individuals depositing recyclable materials.          |
| **Collection Stations** | Physical recycling or composting stations managed by collectors. |
| **Waste Collectors**    | Authorized operators managing stations and collection routes.    |
| **Deposits**            | Records of waste deposits, verified by operators.                |
| **Impact Records**      | Environmental benefit logs (CO₂ saved, water saved, etc.).       |
| **Challenges**          | Community-based sustainability initiatives with reward pools.    |
| **Reward Payments**     | Transaction logs of token rewards.                               |

---

## 💡 Workflow Summary

1. **User Registration**

   ```clarity
   (register-user "John Doe" "Lagos, Nigeria")
   ```

   Registers a new participant and initializes their environmental profile.

2. **Station Registration**

   ```clarity
   (register-station "EcoPoint A" "Ikeja" u1 (list u1 u2 u3) u50000 u120)
   ```

   Adds a new recycling station accepting multiple waste types with a defined reward multiplier.

3. **Waste Deposit**

   ```clarity
   (deposit-waste u1 u1 u5000 u4 0x1234)
   ```

   Logs a deposit (5kg of plastic, quality grade 4), calculates rewards, and transfers tokens.

4. **Challenge Creation**

   ```clarity
   (create-challenge "Clean Streets Week" "Lagos Mainland" "Plastic Recycling" u100000 u5000000 u7)
   ```

   Starts a 7-day recycling challenge with a reward pool of 5M tokens.

5. **Environmental Tracking**

   ```clarity
   (get-environmental-impact tx-sender)
   ```

   Returns real-time user impact stats and streak.

---

## 🧮 Reward Calculation

Rewards depend on:

* **Waste type** (plastic, metal, etc.)
* **Weight (kg)**
* **Quality grade (1–5)**
* **Station multiplier (0.5x – 2x)**

Formula:

```
reward = (base_rate_per_kg × weight_kg × quality_multiplier × station_multiplier) / 100
```

Example:
Plastic @ 100 tokens/kg, 5kg, grade 4 (×1.2), multiplier 1.5
→ `reward = 100 × 5 × 1.2 × 1.5 = 900 tokens`

---

## 🧱 Data Structures (Maps)

| Map                    | Purpose                                                 |
| ---------------------- | ------------------------------------------------------- |
| `waste-users`          | Registered recyclers’ details and environmental scores. |
| `collection-stations`  | Registered recycling centers and operators.             |
| `waste-deposits`       | Each deposit’s data and verification details.           |
| `waste-collectors`     | Operators’ licenses and efficiency metrics.             |
| `impact-records`       | Periodic sustainability metrics.                        |
| `recycling-challenges` | Community challenge tracking.                           |
| `reward-payments`      | Reward transfer logs.                                   |

---

## 🔐 Access Control

| Function             | Access                                          |
| -------------------- | ----------------------------------------------- |
| `update-reward-rate` | Contract owner only                             |
| `fund-rewards`       | Anyone                                          |
| `register-user`      | Any Stacks principal                            |
| `register-station`   | Any principal (auto-registers collector if new) |
| `deposit-waste`      | Registered users only                           |
| `empty-station`      | Station operator only                           |

---

## 🧾 Constants

* **Waste Types:** Plastic, Paper, Glass, Metal, Organic, Electronic, Textile, Hazardous
* **Reward Rates:** `25 – 500` tokens/kg depending on type
* **Daily Limit:** `100kg` per user per day
* **Station Types:** Recycling, Composting, Electronic, Hazardous
* **Block Time Metrics:** `144 blocks/day`, `1008 blocks/week`

---

## 📈 Read-Only Functions

| Function                     | Returns                    |
| ---------------------------- | -------------------------- |
| `get-user-info`              | Full user profile          |
| `get-station-info`           | Station details            |
| `get-deposit-info`           | Deposit metadata           |
| `get-environmental-impact`   | User’s environmental stats |
| `get-platform-stats`         | Network-wide analytics     |
| `calculate-potential-reward` | Simulated reward estimate  |

---

## 🔧 Admin Operations

* **Fund Rewards Pool**

  ```clarity
  (fund-rewards u1000000)
  ```

  Adds 1M tokens to the incentive pool.

* **Update Reward Rate**

  ```clarity
  (update-reward-rate WASTE-PLASTIC u120)
  ```

  Adjusts reward rate for a specific waste category (owner-only).

---

## 🌐 Sustainability Impact

EcoChain directly supports:

* **SDG 11** – Sustainable Cities and Communities
* **SDG 12** – Responsible Consumption and Production
* **SDG 13** – Climate Action

Through:

* Material recovery transparency
* Waste reduction incentives
* Data-driven sustainability tracking

---

## 🧪 Testing Checklist

| Feature                       | Status |
| ----------------------------- | ------ |
| User registration             | ✅      |
| Waste deposit & reward        | ✅      |
| Station registration          | ✅      |
| Challenge creation            | ✅      |
| Reward transfer               | ✅      |
| Daily limit enforcement       | ✅      |
| Environmental impact tracking | ✅      |
Would you like me to include **sample Clarity test cases (in Clarinet)** to go along with this README (for user registration, deposit, and reward calculation)? That would make it easier to verify contract functionality.

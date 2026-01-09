# iMessage Transaction UI - SwiftUI Implementation

## Overview
This is a complete SwiftUI implementation of an iMessage-style chat interface with transaction splitting functionality. The UI allows users to send messages, create transactions, and track balances within a group chat.

## Features
- iMessage-style chat bubbles (blue for sent, gray for received)
- Transaction cards embedded within message bubbles
- Real-time net balance calculation displayed in header
- Add Transaction modal with form validation
- People tagging system for transaction splitting
- Automatic equal split calculation
- Responsive and professional Apple-style design

---

## Folder Structure

```
iMessageTransactionUI/
├── README.md                           # This documentation file
├── Models/                             # Data models
│   ├── Message.swift                   # Message model (text or transaction)
│   ├── Transaction.swift               # Transaction data model
│   └── BalanceType.swift               # Enum for balance states
├── ViewModels/                         # Business logic
│   └── ChatViewModel.swift             # Main view model handling all logic
├── Views/                              # UI components
│   ├── MainView/
│   │   └── ChatView.swift              # Main container view
│   ├── Components/
│   │   ├── Header/
│   │   │   ├── ChatHeaderView.swift    # Top navigation header
│   │   │   └── BalanceSummaryView.swift # Net balance display
│   │   ├── Messages/
│   │   │   ├── MessageBubbleView.swift  # Regular text message bubble
│   │   │   ├── TransactionBubbleView.swift # Transaction card bubble
│   │   │   ├── MessageRowView.swift     # Container for any message type
│   │   │   └── DateSeparatorView.swift  # Date divider between messages
│   │   ├── Input/
│   │   │   ├── MessageInputView.swift   # Bottom input area container
│   │   │   └── AddTransactionButton.swift # Green "Add Transaction" button
│   │   └── Modal/
│   │       ├── TransactionModalView.swift # Add transaction form modal
│   │       └── PersonTagView.swift       # Individual person tag chip
│   └── Styles/
│       └── AppColors.swift              # Color definitions
└── Utilities/
    └── Extensions.swift                 # Helper extensions
```

---

## Models Description

### Message.swift
- Represents a single message in the chat
- Can be either a text message or a transaction
- Properties: id, content, type (sent/received), timestamp, transaction (optional)

### Transaction.swift
- Represents a transaction/expense to be split
- Properties: id, name, totalBill, paidBy, splitMethod, people, creatorName
- Computed properties: sharePerPerson, youOwe, owedToYou

### BalanceType.swift
- Enum representing the balance state
- Cases: youOwe(amount), theyOwe(amount), settled

---

## ViewModel Description

### ChatViewModel.swift
- Main ObservableObject managing all chat state
- Properties:
  - messages: [Message] - all chat messages
  - messageText: String - current input text
  - isShowingTransactionModal: Bool - modal visibility
  - Transaction form fields (name, totalBill, paidBy, splitMethod, people)
- Computed Properties:
  - netBalance: BalanceType - calculates overall balance
  - isFormValid: Bool - validates transaction form
- Methods:
  - sendMessage() - sends a text message
  - createTransaction() - creates and sends a transaction
  - addPerson(name:) - adds person to transaction
  - removePerson(name:) - removes person from transaction
  - resetTransactionForm() - clears form fields

---

## Views Description

### ChatView.swift
- Main container view
- Combines header, messages list, and input area
- Manages the transaction modal presentation

### ChatHeaderView.swift
- Top navigation bar with back button, contact info, and balance
- Uses BalanceSummaryView for the balance display

### BalanceSummaryView.swift
- Displays net balance with appropriate color and label
- Green (+$X.XX, "They owe you") when positive
- Red (-$X.XX, "You owe") when negative
- Gray ($0.00, "All settled up") when balanced

### MessageBubbleView.swift
- Renders a single text message bubble
- Blue with white text for sent messages
- Gray with black text for received messages
- Includes timestamp below the bubble

### TransactionBubbleView.swift
- Renders a transaction card within a bubble
- Shows: transaction name, amount per person, total bill, paid by, split method, people involved
- "Creator created the transaction" text appears above the bubble

### MessageRowView.swift
- Container that determines which bubble type to render
- Handles alignment (sent = trailing, received = leading)

### DateSeparatorView.swift
- Centered date text divider (e.g., "Yesterday", "Today")

### MessageInputView.swift
- Bottom input area with text field and buttons
- Contains AddTransactionButton and send button

### AddTransactionButton.swift
- Green button with "+" icon and "Add Transaction" text
- Triggers modal presentation

### TransactionModalView.swift
- Full transaction form with all input fields
- Includes people tagging functionality
- Cancel and Create buttons in header

### PersonTagView.swift
- Individual tag chip showing person name with remove button
- Used in the "Who are all involved" field

### AppColors.swift
- Centralized color definitions
- iMessageBlue, iMessageGray, oweRed, owedGreen, transactionOrange, etc.

---

## Implementation Notes for AI Agent

1. **State Management**: Uses @StateObject for ChatViewModel in the main view, @ObservedObject in child views

2. **Color Scheme**: All colors are defined in AppColors.swift using Color extension

3. **Reusability**: Each component is self-contained and can be reused independently

4. **MVVM Pattern**: Views only handle UI, all logic is in ChatViewModel

5. **Transaction Logic**:
   - When "You" pays: others owe you (totalBill / numberOfPeople) * (numberOfPeople - 1)
   - When someone else pays: you owe (totalBill / numberOfPeople)
   - Net balance = total owed to you - total you owe

6. **Form Validation**: Transaction can only be created when:
   - Transaction name is not empty
   - Total bill > 0
   - Paid by is not empty
   - At least one person is added

7. **Message Types**:
   - .sent = user's messages (blue, right-aligned)
   - .received = other's messages (gray, left-aligned)

---

## Integration Steps

1. Add all files to your Xcode project maintaining the folder structure
2. Ensure the main app entry point presents ChatView()
3. All components use @EnvironmentObject or direct binding for data flow
4. No external dependencies required - uses only SwiftUI and Foundation

---

## Sample Data
The implementation includes sample messages and transactions to demonstrate functionality. These can be removed or replaced with real data in production.

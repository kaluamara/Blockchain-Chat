# DecentralChat - Blockchain Messaging Protocol

A comprehensive decentralized communication system enabling secure, censorship-resistant messaging with complete user autonomy over data.

## Overview

DecentralChat is a smart contract built for blockchain-based messaging that provides users with:
- **Decentralized Communication**: No central authority controls your messages
- **Censorship Resistance**: Messages stored immutably on the blockchain
- **User Privacy**: Optional encryption and granular privacy controls
- **Complete Data Ownership**: Users maintain full control over their communication data
- **Advanced Features**: Contact management, conversation threading, and user blocking

## Features

### Core Messaging
- Send and receive messages between blockchain addresses
- Optional message encryption
- Conversation threading for organized discussions
- Message status tracking and delivery confirmation
- Comprehensive message metadata (timestamps, sender, recipient, etc.)

### User Management
- User profile creation with customizable display names
- Public key integration for enhanced security
- Privacy preference controls
- Account verification system
- Message statistics tracking

### Social Features
- **Contact Management**: Add/remove contacts with custom nicknames and trust levels
- **User Blocking**: Block unwanted users with detailed reasoning
- **Conversation Threading**: Organize related messages into coherent threads
- **Message History**: Retrieve conversation history with pagination support

### Security & Privacy
- Communication restriction system (blocking)
- Privacy settings for user profiles
- Encryption support for sensitive messages
- Authorization checks for all operations

## Smart Contract Structure

### Data Structures

#### Messages (`blockchain-stored-messages`)
```clarity
{
    message-author: principal,
    intended-recipient: principal,
    message-payload: (string-ascii 1000),
    blockchain-timestamp: uint,
    is-content-encrypted: bool,
    conversation-thread-identifier: (optional uint),
    message-status: (string-ascii 20)
}
```

#### User Profiles (`decentralized-user-registry`)
```clarity
{
    chosen-display-name: (string-ascii 50),
    cryptographic-public-key: (optional (string-ascii 100)),
    account-creation-timestamp: uint,
    total-messages-sent: uint,
    account-verification-status: bool,
    user-privacy-settings: uint
}
```

#### Contact Directory (`personal-contact-directory`)
```clarity
{
    assigned-contact-nickname: (string-ascii 50),
    relationship-established-date: uint,
    contact-trust-level: uint,
    last-interaction-timestamp: uint
}
```

## Function Reference

### Public Functions

#### User Profile Management
- `establish-user-identity(username, public-key, privacy-level)` - Create/update user profile
- Parameters:
  - `username`: Display name (max 50 characters)
  - `public-key`: Optional cryptographic public key
  - `privacy-level`: Privacy preference level (uint)

#### Messaging
- `transmit-blockchain-message(recipient, message, encrypted, thread-id, priority)` - Send a message
- Parameters:
  - `recipient`: Target user's principal address
  - `message`: Message content (max 1000 characters)
  - `encrypted`: Boolean flag for encryption
  - `thread-id`: Optional conversation thread ID
  - `priority`: Message priority level

#### Social Features
- `restrict-user-communication(user, reason)` - Block a user
- `restore-user-communication(user)` - Unblock a user
- `register-new-contact(user, nickname, trust-level)` - Add contact
- `remove-contact-from-directory(user)` - Remove contact
- `initiate-conversation-thread(participants)` - Create conversation thread

### Read-Only Functions

#### Message Queries
- `fetch-message-by-identifier(id)` - Get message by ID
- `retrieve-conversation-history(user1, user2, start, limit)` - Get conversation history

#### User Queries
- `retrieve-user-profile-data(user)` - Get user profile
- `get-user-messaging-statistics(user)` - Get user's message stats
- `check-user-blocking-status(blocker, blocked)` - Check if user is blocked

#### System Queries
- `fetch-global-message-statistics()` - Get total message count
- `verify-protocol-active-status()` - Check if protocol is active
- `get-comprehensive-protocol-information()` - Get protocol metadata

## Constants and Limits

```clarity
MAXIMUM_MESSAGE_CHARACTER_LIMIT: 1000
MAXIMUM_USERNAME_CHARACTER_LIMIT: 50
MAXIMUM_NICKNAME_CHARACTER_LIMIT: 50
MAXIMUM_PUBLIC_KEY_CHARACTER_LIMIT: 100
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 200 | ERROR_UNAUTHORIZED_ACCESS | User lacks permission for operation |
| 201 | ERROR_MESSAGE_DOES_NOT_EXIST | Requested message not found |
| 202 | ERROR_INVALID_MESSAGE_TARGET | Invalid recipient or messaging parameters |
| 203 | ERROR_MESSAGE_CONTENT_TOO_LARGE | Content exceeds size limits |
| 204 | ERROR_USER_ALREADY_IN_BLOCKLIST | User is already blocked |
| 205 | ERROR_USER_NOT_IN_BLOCKLIST | User is not in blocklist |
| 206 | ERROR_CANNOT_PERFORM_ACTION_ON_SELF | Action cannot be performed on self |
| 207 | ERROR_INVALID_PAGINATION_PARAMETERS | Invalid pagination settings |

## Usage Examples

### Setting Up a User Profile
```clarity
(establish-user-identity "Alice" (some "public-key-here") u1)
```

### Sending a Message
```clarity
(transmit-blockchain-message 'SP2RECIPIENT.alice "Hello, Alice!" false none u0)
```

### Blocking a User
```clarity
(restrict-user-communication 'SP2SPAMMER.bob "Spam messages")
```

### Adding a Contact
```clarity
(register-new-contact 'SP2FRIEND.charlie "Charlie" u5)
```

### Retrieving Conversation History
```clarity
(retrieve-conversation-history 'SP2USER1.alice 'SP2USER2.bob u0 u10)
```

## Security Considerations

1. **Message Immutability**: Once sent, messages cannot be deleted or modified
2. **Privacy**: While the contract supports encryption flags, actual encryption must be implemented client-side
3. **Spam Prevention**: Built-in blocking system and message size limits
4. **Access Control**: Users can only access their own conversations and data
5. **Protocol Control**: Administrator can disable the protocol in emergencies

## Development and Deployment

### Prerequisites
- Clarity smart contract environment
- Stacks blockchain testnet/mainnet access
- Understanding of Clarity programming language

### Deployment Considerations
- Set appropriate gas limits for complex operations
- Consider the immutable nature of blockchain storage
- Plan for protocol upgrades and migration strategies
- Implement proper client-side encryption if privacy is critical

## Protocol Administration

The contract includes administrative functions for protocol management:
- Emergency protocol shutdown/restart
- Protocol status monitoring
- System-wide statistics access

Only the protocol administrator (contract deployer) can access these functions.
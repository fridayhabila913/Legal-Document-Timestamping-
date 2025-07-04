# 📜 Legal Document Timestamping Smart Contract

A blockchain-based solution for proving the existence and authorship of legal documents using immutable timestamps on the Stacks blockchain.

## 🚀 Features

- **Document Registration**: Register documents with cryptographic hashes
- **Timestamp Proof**: Immutable blockchain timestamps for legal evidence
- **Authorship Verification**: Prove document ownership and authorship
- **Batch Operations**: Verify multiple documents simultaneously
- **Document Discovery**: Find documents by hash or author

## 📋 Contract Functions

### Public Functions

#### `register-document`
```clarity
(register-document (hash (buff 32)) (title (string-ascii 100)))
```
Register a new document with its hash and title. Returns the document ID.

#### `update-document-verification`
```clarity
(update-document-verification (document-id uint) (verified bool))
```
Update the verification status of your own documents.

#### `batch-verify-documents`
```clarity
(batch-verify-documents (hashes (list 10 (buff 32))))
```
Verify multiple documents at once.

### Read-Only Functions

#### `get-document`
```clarity
(get-document (document-id uint))
```
Retrieve document details by ID.

#### `get-document-by-hash`
```clarity
(get-document-by-hash (hash (buff 32)))
```
Find a document using its hash.

#### `verify-document`
```clarity
(verify-document (hash (buff 32)) (expected-author principal))
```
Comprehensive document verification including authorship check.

#### `verify-authorship`
```clarity
(verify-authorship (hash (buff 32)) (claimed-author principal))
```
Check if a specific principal is the author of a document.

#### `get-author-documents`
```clarity
(get-author-documents (author principal))
```
Get all documents registered by a specific author.

## 🛠️ Usage Examples

### Registering a Document
```bash
clarinet console
```

```clarity
(contract-call? .document-timestamping register-document 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef "Legal Contract v1.0")
```

### Verifying a Document
```clarity
(contract-call? .document-timestamping verify-document 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Checking Document Existence
```clarity
(contract-call? .document-timestamping check-document-existence 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef)
```

## 🔧 Development Setup

1. **Install Clarinet**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install clarinet-cli
```

2. **Initialize Project**
```bash
clarinet new document-timestamping
cd document-timestamping
```

3. **Add Contract**
Copy the contract code to `contracts/document-timestamping.clar`

4. **Test Contract**
```bash
clarinet check
clarinet test
```

## 📊 Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Document already exists |
| u102 | Document not found |
| u103 | Invalid hash provided |
| u104 | Invalid title provided |
| u105 | Verification failed |

## 🔐 Security Features

- **Immutable Records**: Once registered, document hashes cannot be changed
- **Author Verification**: Only document authors can update verification status
- **Cryptographic Hashes**: Uses 32-byte hashes for document identification
- **Blockchain Timestamps**: Leverages Stacks blockchain for tamper-proof timestamps

## 📈 Use Cases

- **Legal Contracts**: Timestamp legal agreements and contracts
- **Intellectual Property**: Prove creation date of patents, copyrights
- **Compliance Documents**: Maintain audit trails for regulatory compliance
- **Academic Papers**: Establish publication priority for research
- **Business Documents**: Secure important business agreements

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.
```

**Git Commit Message:**
```
feat: implement legal document timestamping MVP with hash-based verification
```

**GitHub Pull Request Title:**
```
🚀 Add Legal Document Timestamping Smart Contract MVP
```

**GitHub Pull Request Description:**
```
## 📜 Legal Document Timestamping MVP

This PR introduces a complete smart contract solution for timestamping legal documents on the Stacks blockchain.

### ✨ Features Added
- Document registration with cryptographic hashes
- Immutable timestamp proof using blockchain
- Authorship verification and ownership tracking
- Batch document verification capabilities
- Comprehensive read-only functions for document discovery

### 🔧 Technical Implementation
- 150+ lines of clean Clarity code
- Efficient data structures using maps for O(1) lookups
- Error handling with descriptive error codes
- Gas-optimized batch operations

### 📋 Contract Functions
- `register-document` - Register new documents
- `verify-document` - Comprehensive verification
- `get-document-by-hash` - Hash-based document lookup
- `verify-authorship` - Authorship verification
- `batch-verify-documents` - Bulk verification

### 🎯 Use Cases
Perfect for legal contracts, IP protection, compliance documentation, and any scenario requiring tamper-proof document timestamping.

Ready for deployment and testing! 🚀

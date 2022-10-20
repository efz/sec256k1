#  Swift package for Sec256K1 

Based on Sec256k1 library included dodge coin core [https://github.com/dogecoin/dogecoin/tree/master/src/secp256k1](https://github.com/dogecoin/dogecoin/tree/master/src/secp256k1).

## No considerations given to security aspects.

Couple of slides on implementation,
[Sec256k1.pdf](Sec256k1.pdf)

Supports,
- Sec256k1 private key and public key generation/tweaking.
- Sec256k1 ECDSA sigining and verification.
- Serialization/Deserialization of public/private keys and signature.

## Usage

Package,
```
// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Secp256k1Demo",
    products: [
        .executable(
            name: "Secp256k1Demo",
            targets: ["Secp256k1Demo"]),
    ],
    dependencies: [
        .package(url: "https://gitlab.com/yyuu776/secp", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Secp256k1Demo",
            dependencies: [.product(name: "Secp256k1", package: "secp")])
    ]
)
```

Source,
```
import Secp256k1

func bytes2HexString(bytes: [UInt8]) -> String {
    return "[" + bytes.reduce("") {  $0 + ($0.isEmpty ? "0x" : ", 0x") + String($1, radix: 16, uppercase: true) } + "]"
}

let messageBytes: [UInt8] = [0x86, 0x41, 0x99, 0x81, 0x06, 0x23, 0x44, 0x53,
                             0xaa, 0x5f, 0x9d, 0x6a, 0x31, 0x78, 0xf4, 0xf7,
                             0xb8, 0x12, 0xe0, 0x0b, 0x81, 0x7a, 0x77, 0x62,
                             0x65, 0xdf, 0xdd, 0x31, 0xb9, 0x3e, 0x29, 0xa9]

let privateKeyBytes: [UInt8] = [0x02, 0x14, 0x4e, 0x5a, 0x58, 0xef, 0x5b, 0x22,
                                0x6f, 0xd2, 0xe2, 0x07, 0x6a, 0x77, 0xcf, 0x05,
                                0xb4, 0x1d, 0xe7, 0x4a, 0x30, 0x98, 0x27, 0x8c,
                                0x93, 0xe6, 0xe6, 0x3c, 0x0b, 0xc4, 0x73, 0x76]

let message = Secp256k1Message(bytes32: messageBytes)!
let privateKey = Secp256k1PrivateKey(bytes32: privateKeyBytes)!
let nonceGenerator = Secp256k1DefaultNonceGenerator()

// Sign
let signature = message.sign(privateKey: privateKey, nonceGenerator: nonceGenerator)

// Serialize Signature
var signatureBytes = [UInt8](repeating: 0, count: 64)
try! signature!.serialize(bytes64: &signatureBytes)
let signatureHex = bytes2HexString(bytes: signatureBytes)
print("Signature: \(signatureHex)")

// Serialize Public Key
var publicKeyBytes = [UInt8](repeating: 0, count: 33)
try! privateKey.pubKey!.serialize(bytes33or65: &publicKeyBytes, compress: true)
let publicKeyHex = bytes2HexString(bytes: publicKeyBytes)
print("Public Key: \(publicKeyHex)")

// Verify
let publicKey = Secp256k1PublicKey(bytes33or65: publicKeyBytes)
let signature2Verify = Secp256k1Ecdsa(bytes64: signatureBytes)
let verified = signature2Verify!.verify(message: message, publicKey: publicKey!)
print("Verified: \(verified)")
```

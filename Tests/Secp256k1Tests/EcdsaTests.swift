import XCTest
@testable import Secp256k1

class EcdsaKeyTests: XCTestCase {
    var randp = Secp256k1KeyGenerator()
    
    func testSignVerify() {
        for _ in 0..<100 {
            let message = randp.genMessage()
            let privKey = randp.genPrivateKey()
            let pubKey = privKey.pubKey!
            var signature: Secp256k1Ecdsa? = nil
            
            while signature == nil {
                let nonce = randp.genScalar()
                signature = Secp256k1Ecdsa(message: message, nonce: nonce, privateKey: privKey)
            }
            
            let isValid = signature?.validate(message: message, publicKey: pubKey)
            XCTAssertTrue(isValid!)
            let wrongMessage = Secp256k1Message(s:message.s + Secp256k1Scalar.one)
            let isWrongMessageValid = signature?.validate(message: wrongMessage, publicKey: pubKey)
            XCTAssertFalse(isWrongMessageValid!)
        }
    }
    
    func testEcdsaEnd2End() {
        var bytes = [UInt8](repeating: 0, count: 65)
        let noneGenerator = Secp256k1DefaultNonceGenerator()
        for _ in 0..<100 {
            let message = randp.genMessage()
            var privKey = randp.genPrivateKey()
            
            /* Construct and verify corresponding public key. */
            var pubKey = privKey.pubKey!
            
            /* Verify exporting and importing public key. */
            let exportPubKeyCompressed = Bool.random()
            pubKey.serialize(bytes: &bytes, compress: exportPubKeyCompressed)
            
            let pubKey2 = Secp256k1PublicKey(bytes: bytes[0..<(exportPubKeyCompressed ? 33 : 65)])
            XCTAssertEqual(pubKey, pubKey2)
            
            /* Verify private key import and export. */
            bytes[64] = 0
            try! privKey.serialize(bytes32: &bytes)
            XCTAssertEqual(bytes[64], 0)
            let privKey2 = Secp256k1PrivateKey(bytes32: bytes)
            XCTAssertEqual(privKey, privKey2)
            
            /* Optionally tweak the keys using addition. */
            if Int.random(in: 0..<3) <= 10 {
                let tweak = randp.genScalar()
                try! privKey.tweakAdd(tweak: tweak)
                try! pubKey.tweakAdd(tweak: tweak)
                
                XCTAssertEqual(pubKey, privKey.pubKey)
            }
            
            /* Optionally tweak the keys using multiplication. */
            if Int.random(in: 0..<3) <= 10 {
                let tweak = randp.genScalar()
                try! privKey.tweakMul(tweak: tweak)
                try! pubKey.tweakMul(tweak: tweak)
                
                XCTAssertEqual(pubKey, privKey.pubKey)
            }
            
            /* Sign & Verify */
            let signature: Secp256k1Ecdsa = message.sign(privateKey: privKey, nonceGenerator: noneGenerator)!
            let isValid = signature.validate(message: message, publicKey: pubKey)
            XCTAssertTrue(isValid)
            
            /* serialize and verify */
            bytes[64] = 0
            signature.serialize(bytes: &bytes)
            XCTAssertEqual(bytes[64], 0)
            let signature2 = Secp256k1Ecdsa(bytes64: bytes)
            let isValidAfterSerialized = signature2!.validate(message: message, publicKey: pubKey)
            XCTAssertTrue(isValidAfterSerialized)
        }
    }
    
    func testSZeroSig() {
        struct CodedNonceGenerator: Secp256k1NonceGenerator {
            let nonce: [UInt8]
            init(nonce: [UInt8]) {
                self.nonce = nonce
            }
            mutating func genNonce(bytes32: inout [UInt8]) {
                bytes32[0..<32] = nonce[0..<32]
            }
        }
        
        let nonce: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
        
        let nonce2: [UInt8] = [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
                               0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFE,
                               0xBA,0xAE,0xDC,0xE6,0xAF,0x48,0xA0,0x3B,
                               0xBF,0xD2,0x5E,0x8C,0xD0,0x36,0x41,0x40]
        
        let key: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
        
        var msg: [UInt8] = [0x86, 0x41, 0x99, 0x81, 0x06, 0x23, 0x44, 0x53,
                            0xaa, 0x5f, 0x9d, 0x6a, 0x31, 0x78, 0xf4, 0xf7,
                            0xb8, 0x12, 0xe0, 0x0b, 0x81, 0x7a, 0x77, 0x62,
                            0x65, 0xdf, 0xdd, 0x31, 0xb9, 0x3e, 0x29, 0xa9]
        
        var message = Secp256k1Message(bytes32: msg)!
        let privKey = Secp256k1PrivateKey(bytes32: key)!
        let pubKey = privKey.pubKey!
        
        let sig1 = message.sign(privateKey: privKey, nonceGenerator: CodedNonceGenerator(nonce: nonce), maxAttemts: 1)
        XCTAssertNil(sig1)
        let sig2 = message.sign(privateKey: privKey, nonceGenerator: CodedNonceGenerator(nonce: nonce2), maxAttemts: 1)
        XCTAssertNil(sig2)
        
        msg[31] = 0xAA
        message = Secp256k1Message(bytes32: msg)!
        
        let sig3 = message.sign(privateKey: privKey, nonceGenerator: CodedNonceGenerator(nonce: nonce), maxAttemts: 1)
        XCTAssertNotNil(sig3)
        XCTAssertTrue(sig3!.validate(message: message, publicKey: pubKey))
        
        let sig4 = message.sign(privateKey: privKey, nonceGenerator: CodedNonceGenerator(nonce: nonce2), maxAttemts: 1)
        XCTAssertNotNil(sig4)
        XCTAssertTrue(sig4!.validate(message: message, publicKey: pubKey))
    }
    
    func testInvalidSigDeserialize() {
        let sigBytes = [UInt8](repeating: 255, count: 64)
        let signature = Secp256k1Ecdsa(bytes64: sigBytes)
        XCTAssertNil(signature)
    }
}

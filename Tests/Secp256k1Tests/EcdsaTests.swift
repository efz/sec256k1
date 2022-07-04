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
    
    func testNegativeOneMessage() {
        let pubKeyBytes: [UInt8] = [0x03, 0xaf, 0x97, 0xff, 0x7d, 0x3a, 0xf6, 0xa0,
                                    0x02, 0x94, 0xbd, 0x9f, 0x4b, 0x2e, 0xd7, 0x52,
                                    0x28, 0xdb, 0x49, 0x2a, 0x65, 0xcb, 0x1e, 0x27,
                                    0x57, 0x9c, 0xba, 0x74, 0x20, 0xd5, 0x1d, 0x20,
                                    0xf1]
        
        let srBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                                0x45, 0x51, 0x23, 0x19, 0x50, 0xb7, 0x5f, 0xc4,
                                0x40, 0x2d, 0xa1, 0x72, 0x2f, 0xc9, 0xba, 0xee]
        var overflow = false
        let sr = Secp256k1Scalar(bytes: srBytes, overflowed: &overflow)
        XCTAssertFalse(overflow)
        let msgScalar = Secp256k1Scalar.neg(Secp256k1Scalar.one)
        let message = Secp256k1Message(s: msgScalar)
        
        let ss = Secp256k1Scalar.one
        
        let pubKey = Secp256k1PublicKey(bytes: pubKeyBytes)!
        let signature1 = Secp256k1Ecdsa(r: sr, s: ss)
        XCTAssertTrue(signature1!.isNormalized())
        let valid = signature1!.validate(message: message, publicKey: pubKey)
        XCTAssertTrue(valid)
        
        let ss2 = Secp256k1Scalar.neg(ss)
        let signature2 = Secp256k1Ecdsa(r: sr, s: ss2)
        XCTAssertFalse(signature2!.isNormalized())
        let valid2 = signature2!.validate(message: message, publicKey: pubKey)
        XCTAssertTrue(valid2)
        
        let ss3 = Secp256k1Scalar.neg(Secp256k1Scalar(int: 3))
        let signature3 = Secp256k1Ecdsa(r: sr, s: ss3)
        XCTAssertFalse(signature2!.isNormalized())
        let valid3 = signature3!.validate(message: message, publicKey: pubKey)
        XCTAssertFalse(valid3)
    }
    
    func testPositiveOneMessage() {
        let pubKeyBytes: [UInt8] = [0x02, 0x14, 0x4e, 0x5a, 0x58, 0xef, 0x5b, 0x22,
                                    0x6f, 0xd2, 0xe2, 0x07, 0x6a, 0x77, 0xcf, 0x05,
                                    0xb4, 0x1d, 0xe7, 0x4a, 0x30, 0x98, 0x27, 0x8c,
                                    0x93, 0xe6, 0xe6, 0x3c, 0x0b, 0xc4, 0x73, 0x76,
                                    0x25]
        
        let pubKey2Bytes: [UInt8] = [0x02, 0x8a, 0xd5, 0x37, 0xed, 0x73, 0xd9, 0x40,
                                     0x1d, 0xa0, 0x33, 0xd2, 0xdc, 0xf0, 0xaf, 0xae,
                                     0x34, 0xcf, 0x5f, 0x96, 0x4c, 0x73, 0x28, 0x0f,
                                     0x92, 0xc0, 0xf6, 0x9d, 0xd9, 0xb2, 0x09, 0x10,
                                     0x62]
        
        let srBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                                0x45, 0x51, 0x23, 0x19, 0x50, 0xb7, 0x5f, 0xc4,
                                0x40, 0x2d, 0xa1, 0x72, 0x2f, 0xc9, 0xba, 0xeb]
        var overflow = false
        let sr = Secp256k1Scalar(bytes: srBytes, overflowed: &overflow)
        XCTAssertFalse(overflow)
        let msgScalar = Secp256k1Scalar.one
        let message = Secp256k1Message(s: msgScalar)
        
        let ss = Secp256k1Scalar.one
        let pubKey = Secp256k1PublicKey(bytes: pubKeyBytes)!
        let pubKey2 = Secp256k1PublicKey(bytes: pubKey2Bytes)!
        
        let signature1 = Secp256k1Ecdsa(r: sr, s: ss)
        XCTAssertTrue(signature1!.isNormalized())
        let valid = signature1!.validate(message: message, publicKey: pubKey)
        XCTAssertTrue(valid)
        let valid2 = signature1!.validate(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid2)
        
        let ss2 = Secp256k1Scalar.neg(ss)
        let signature2 = Secp256k1Ecdsa(r: sr, s: ss2)
        XCTAssertFalse(signature2!.isNormalized())
        let valid3 = signature2!.validate(message: message, publicKey: pubKey)
        XCTAssertTrue(valid3)
        let valid4 = signature2!.validate(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid4)
        
        let ss3 = Secp256k1Scalar.neg(Secp256k1Scalar(int: 2))
        let signature3 = Secp256k1Ecdsa(r: sr, s: ss3)
        XCTAssertFalse(signature3!.isNormalized())
        let valid5 = signature3!.validate(message: message, publicKey: pubKey)
        XCTAssertFalse(valid5)
        let valid6 = signature3!.validate(message: message, publicKey: pubKey2)
        XCTAssertFalse(valid6)
    }
    
    func testZeroMessage() {
        let pubKeyBytes: [UInt8] = [0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                    0x02]
        
        let pubKey2Bytes: [UInt8] = [0x02, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                                     0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                                     0xfe, 0xba, 0xae, 0xdc, 0xe6, 0xaf, 0x48, 0xa0,
                                     0x3b, 0xbf, 0xd2, 0x5e, 0x8c, 0xd0, 0x36, 0x41,
                                     0x43]
        
        let sr = Secp256k1Scalar(int: 2)
        let ss = Secp256k1Scalar(int: 2)
        let msgScalar = Secp256k1Scalar.zero
        let message = Secp256k1Message(s: msgScalar)
        
        let pubKey = Secp256k1PublicKey(bytes: pubKeyBytes)!
        let pubKey2 = Secp256k1PublicKey(bytes: pubKey2Bytes)!
        
        let signature1 = Secp256k1Ecdsa(r: sr, s: ss)
        XCTAssertTrue(signature1!.isNormalized())
        let valid = signature1!.validate(message: message, publicKey: pubKey)
        XCTAssertTrue(valid)
        let valid2 = signature1!.validate(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid2)
        
        let ss2 = Secp256k1Scalar.neg(ss)
        let signature2 = Secp256k1Ecdsa(r: sr, s: ss2)
        XCTAssertFalse(signature2!.isNormalized())
        let valid3 = signature2!.validate(message: message, publicKey: pubKey)
        XCTAssertTrue(valid3)
        let valid4 = signature2!.validate(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid4)
        
        let ss3 = Secp256k1Scalar.one
        let signature3 = Secp256k1Ecdsa(r: sr, s: ss3)
        XCTAssertTrue(signature3!.isNormalized())
        let valid5 = signature3!.validate(message: message, publicKey: pubKey)
        XCTAssertFalse(valid5)
        let valid6 = signature3!.validate(message: message, publicKey: pubKey2)
        XCTAssertFalse(valid6)
    }
    
    func testInfinity() {
        let ss = Secp256k1Scalar.inv(Secp256k1Scalar.neg(Secp256k1Scalar.one))
        let sr = Secp256k1Scalar.one
        let ecmult = Secp256k1Ecmult()
        var pubKeyFe = ecmult.gen(gn: sr)
        pubKeyFe.normalizeJ()
        let pubKey = Secp256k1PublicKey(ge: pubKeyFe)!
        let message = Secp256k1Message(s: ss)
        
        let signature = Secp256k1Ecdsa(r: sr, s: ss)
        let valid = signature!.validate(message: message, publicKey: pubKey)
        XCTAssertFalse(valid)
    }
}

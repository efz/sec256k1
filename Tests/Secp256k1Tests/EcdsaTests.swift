import XCTest
@testable import Secp256k1

class EcdsaKeyTests: XCTestCase {
    var randp = KeyGenerator()
    
    func testSignVerify() {
        for _ in 0..<100 {
            let message = randp.genScalar()
            let privKey = randp.genPrivateKey()
            let pubKey = privKey.pubKey!
            var signature: Secp256k1Edsa? = nil
            
            while signature == nil {
                let nonce = randp.genScalar()
                signature = Secp256k1Edsa(message: message, nonce: nonce, privateKey: privKey)
            }
            
            let isValid = signature?.validate(message: message, publicKey: pubKey)
            XCTAssertTrue(isValid!)
            let wrongMessage = message + Secp256k1Scalar.one
            let isWrongMessageValid = signature?.validate(message: wrongMessage, publicKey: pubKey)
            XCTAssertFalse(isWrongMessageValid!)
        }
    }
    
    func testEcdsaEnd2End() {
        var bytes = [UInt8](repeating: 0, count: 65)
        let noneGenerator = DefaultNonceGenerator()
        for _ in 0..<100 {
            let message = randp.genScalar()
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
            privKey.serialize(bytes: &bytes)
            XCTAssertEqual(bytes[64], 0)
            let privKey2 = Secp256k1PrivateKey(bytes: bytes)
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
            let signature: Secp256k1Edsa = Secp256k1Edsa.sign(message: message, privateKey: privKey, nonceGenerator: noneGenerator)
            let isValid = signature.validate(message: message, publicKey: pubKey)
            XCTAssertTrue(isValid)
            
            /* serialize and verify */
            bytes[64] = 0
            signature.serialize(bytes: &bytes)
            XCTAssertEqual(bytes[64], 0)
            let signature2 = Secp256k1Edsa(bytes: bytes)
            let isValidAfterSerialized = signature2!.validate(message: message, publicKey: pubKey)
            XCTAssertTrue(isValidAfterSerialized)
        }
    }
}

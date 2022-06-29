import XCTest
@testable import secp256k1s

class EcdsaKeyTests: XCTestCase {
    let randp = EcKeyTests.RandProvider()
    
    func testSignVerify() {
        for _ in 0..<10 {
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
}

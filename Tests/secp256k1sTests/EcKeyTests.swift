import XCTest
@testable import secp256k1s

class EcKeyTests: XCTestCase {
    func testInvalidEcKeys() {
        let orderc: [UInt8] = [
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
            0xba, 0xae, 0xdc, 0xe6, 0xaf, 0x48, 0xa0, 0x3b,
            0xbf, 0xd2, 0x5e, 0x8c, 0xd0, 0x36, 0x41, 0x41
        ]
        /* Group order is too large, reject. */
        var privKey = Secp256k1PrivateKey(bytes: orderc)
        XCTAssertNil(privKey)
        
        /* Maximum value is too large, reject. */
        var ctmp = [UInt8](repeating: 255, count: 32)
        privKey = Secp256k1PrivateKey(bytes: ctmp)
        XCTAssertNil(privKey)
        
        /* Zero is too small, reject. */
        ctmp = [UInt8](repeating: 0, count: 32)
        privKey = Secp256k1PrivateKey(bytes: ctmp)
        XCTAssertNil(privKey)
        
        /* One must be accepted. */
        ctmp[31] = 0x01
        privKey = Secp256k1PrivateKey(bytes: ctmp)
        XCTAssertNotNil(privKey)
        XCTAssertNotNil(privKey!.pubKey)
        
        /* Group order + 1 is too large, reject. */
        ctmp = orderc
        ctmp[31] = 0x42
        privKey = Secp256k1PrivateKey(bytes: ctmp)
        XCTAssertNil(privKey)
        
        /* -1 must be accepted. */
        ctmp[31] = 0x40
        privKey = Secp256k1PrivateKey(bytes: ctmp)
        XCTAssertNotNil(privKey)
        XCTAssertNotNil(privKey!.pubKey)
        let prevKeyNeg1 = privKey!
        let pubKeyNeg1 = privKey!.pubKey!
        
        /* Tweak of zero leaves the value changed. */
        try! privKey!.tweakAdd(tweak: Secpt256k1Scalar.zero)
        XCTAssertEqual(privKey!, prevKeyNeg1)
        var pubKey = privKey!.pubKey!
        try! pubKey.tweakAdd(tweak: Secpt256k1Scalar.zero)
        XCTAssertEqual(pubKey,  pubKeyNeg1)
        
        /* Multiply tweak of zero zeroizes the output. */
        XCTAssertThrowsError(try privKey!.tweakMul(tweak: Secpt256k1Scalar.zero))
        XCTAssertThrowsError(try pubKey.tweakMul(tweak: Secpt256k1Scalar.zero))
        
        /* Private key tweaks results in a key of zero. */
        ctmp = orderc
        ctmp[31] = 0x40
        privKey = Secp256k1PrivateKey(bytes: ctmp)
        XCTAssertThrowsError(try privKey!.tweakAdd(tweak: Secpt256k1Scalar.one))
        pubKey = pubKeyNeg1
        XCTAssertThrowsError(try pubKey.tweakAdd(tweak: Secpt256k1Scalar.one))
        
        /* Tweak computation wraps and results in a key of 1. */
        let two = Secpt256k1Scalar(int: 2)
        try! privKey!.tweakAdd(tweak: two)
        XCTAssertEqual(privKey, Secp256k1PrivateKey(s: Secpt256k1Scalar.one))
        try! pubKey.tweakAdd(tweak: two)
        XCTAssertEqual(pubKey, Secp256k1PrivateKey(s: Secpt256k1Scalar.one)!.pubKey)
        
        /* Tweak mul * 2 = 1+1. */
        var pubKey2 = pubKey
        try! pubKey.tweakAdd(tweak: Secpt256k1Scalar.one)
        try! pubKey2.tweakMul(tweak: two)
        XCTAssertEqual(pubKey, pubKey2)
    }
}

import XCTest
@testable import Secp256k1

class EcKeyTests: XCTestCase {
    func testEcKeyTweak() {
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
        try! privKey!.tweakAdd(tweak: Secp256k1Scalar.zero)
        XCTAssertEqual(privKey!, prevKeyNeg1)
        var pubKey = privKey!.pubKey!
        try! pubKey.tweakAdd(tweak: Secp256k1Scalar.zero)
        XCTAssertEqual(pubKey,  pubKeyNeg1)
        
        /* Multiply tweak of zero zeroizes the output. */
        XCTAssertThrowsError(try privKey!.tweakMul(tweak: Secp256k1Scalar.zero))
        XCTAssertThrowsError(try pubKey.tweakMul(tweak: Secp256k1Scalar.zero))
        
        /* Private key tweaks results in a key of zero. */
        ctmp = orderc
        ctmp[31] = 0x40
        privKey = Secp256k1PrivateKey(bytes: ctmp)
        XCTAssertThrowsError(try privKey!.tweakAdd(tweak: Secp256k1Scalar.one))
        pubKey = pubKeyNeg1
        XCTAssertThrowsError(try pubKey.tweakAdd(tweak: Secp256k1Scalar.one))
        
        /* Tweak computation wraps and results in a key of 1. */
        let two = Secp256k1Scalar(int: 2)
        try! privKey!.tweakAdd(tweak: two)
        XCTAssertEqual(privKey, Secp256k1PrivateKey(s: Secp256k1Scalar.one))
        try! pubKey.tweakAdd(tweak: two)
        XCTAssertEqual(pubKey, Secp256k1PrivateKey(s: Secp256k1Scalar.one)!.pubKey)
        
        /* Tweak mul * 2 = 1+1. */
        var pubKey2 = pubKey
        try! pubKey.tweakAdd(tweak: Secp256k1Scalar.one)
        try! pubKey2.tweakMul(tweak: two)
        XCTAssertEqual(pubKey, pubKey2)
    }
    
    func testValidPublicKeySerialize() {
        let validPublicKeyBytes: [[UInt8]] = [
            [
                /* Point with leading and trailing zeros in x and y serialization. */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x42, 0x52,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x64, 0xef, 0xa1, 0x7b, 0x77, 0x61, 0xe1, 0xe4, 0x27, 0x06, 0x98, 0x9f, 0xb4, 0x83,
                0xb8, 0xd2, 0xd4, 0x9b, 0xf7, 0x8f, 0xae, 0x98, 0x03, 0xf0, 0x99, 0xb8, 0x34, 0xed, 0xeb, 0x00
            ],
            [
                /* Point with x equal to a 3rd root of unity.*/
                0x7a, 0xe9, 0x6a, 0x2b, 0x65, 0x7c, 0x07, 0x10, 0x6e, 0x64, 0x47, 0x9e, 0xac, 0x34, 0x34, 0xe9,
                0x9c, 0xf0, 0x49, 0x75, 0x12, 0xf5, 0x89, 0x95, 0xc1, 0x39, 0x6c, 0x28, 0x71, 0x95, 0x01, 0xee,
                0x42, 0x18, 0xf2, 0x0a, 0xe6, 0xc6, 0x46, 0xb3, 0x63, 0xdb, 0x68, 0x60, 0x58, 0x22, 0xfb, 0x14,
                0x26, 0x4c, 0xa8, 0xd2, 0x58, 0x7f, 0xdd, 0x6f, 0xbc, 0x75, 0x0d, 0x58, 0x7e, 0x76, 0xa7, 0xee,
            ],
            [
                /* Point with largest x. (1/2) */
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2c,
                0x0e, 0x99, 0x4b, 0x14, 0xea, 0x72, 0xf8, 0xc3, 0xeb, 0x95, 0xc7, 0x1e, 0xf6, 0x92, 0x57, 0x5e,
                0x77, 0x50, 0x58, 0x33, 0x2d, 0x7e, 0x52, 0xd0, 0x99, 0x5c, 0xf8, 0x03, 0x88, 0x71, 0xb6, 0x7d,
            ],
            [
                /* Point with largest x. (2/2) */
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2c,
                0xf1, 0x66, 0xb4, 0xeb, 0x15, 0x8d, 0x07, 0x3c, 0x14, 0x6a, 0x38, 0xe1, 0x09, 0x6d, 0xa8, 0xa1,
                0x88, 0xaf, 0xa7, 0xcc, 0xd2, 0x81, 0xad, 0x2f, 0x66, 0xa3, 0x07, 0xfb, 0x77, 0x8e, 0x45, 0xb2,
            ],
            [
                /* Point with smallest x. (1/2) */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                0x42, 0x18, 0xf2, 0x0a, 0xe6, 0xc6, 0x46, 0xb3, 0x63, 0xdb, 0x68, 0x60, 0x58, 0x22, 0xfb, 0x14,
                0x26, 0x4c, 0xa8, 0xd2, 0x58, 0x7f, 0xdd, 0x6f, 0xbc, 0x75, 0x0d, 0x58, 0x7e, 0x76, 0xa7, 0xee,
            ],
            [
                /* Point with smallest x. (2/2) */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                0xbd, 0xe7, 0x0d, 0xf5, 0x19, 0x39, 0xb9, 0x4c, 0x9c, 0x24, 0x97, 0x9f, 0xa7, 0xdd, 0x04, 0xeb,
                0xd9, 0xb3, 0x57, 0x2d, 0xa7, 0x80, 0x22, 0x90, 0x43, 0x8a, 0xf2, 0xa6, 0x81, 0x89, 0x54, 0x41,
            ],
            [
                /* Point with largest y. (1/3) */
                0x1f, 0xe1, 0xe5, 0xef, 0x3f, 0xce, 0xb5, 0xc1, 0x35, 0xab, 0x77, 0x41, 0x33, 0x3c, 0xe5, 0xa6,
                0xe8, 0x0d, 0x68, 0x16, 0x76, 0x53, 0xf6, 0xb2, 0xb2, 0x4b, 0xcb, 0xcf, 0xaa, 0xaf, 0xf5, 0x07,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2e,
            ],
            [
                /* Point with largest y. (2/3) */
                0xcb, 0xb0, 0xde, 0xab, 0x12, 0x57, 0x54, 0xf1, 0xfd, 0xb2, 0x03, 0x8b, 0x04, 0x34, 0xed, 0x9c,
                0xb3, 0xfb, 0x53, 0xab, 0x73, 0x53, 0x91, 0x12, 0x99, 0x94, 0xa5, 0x35, 0xd9, 0x25, 0xf6, 0x73,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2e,
            ],
            [
                /* Point with largest y. (3/3) */
                0x14, 0x6d, 0x3b, 0x65, 0xad, 0xd9, 0xf5, 0x4c, 0xcc, 0xa2, 0x85, 0x33, 0xc8, 0x8e, 0x2c, 0xbc,
                0x63, 0xf7, 0x44, 0x3e, 0x16, 0x58, 0x78, 0x3a, 0xb4, 0x1f, 0x8e, 0xf9, 0x7c, 0x2a, 0x10, 0xb5,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2e,
            ],
            [
                /* Point with smallest y. (1/3) */
                0x1f, 0xe1, 0xe5, 0xef, 0x3f, 0xce, 0xb5, 0xc1, 0x35, 0xab, 0x77, 0x41, 0x33, 0x3c, 0xe5, 0xa6,
                0xe8, 0x0d, 0x68, 0x16, 0x76, 0x53, 0xf6, 0xb2, 0xb2, 0x4b, 0xcb, 0xcf, 0xaa, 0xaf, 0xf5, 0x07,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
            ],
            [
                /* Point with smallest y. (2/3) */
                0xcb, 0xb0, 0xde, 0xab, 0x12, 0x57, 0x54, 0xf1, 0xfd, 0xb2, 0x03, 0x8b, 0x04, 0x34, 0xed, 0x9c,
                0xb3, 0xfb, 0x53, 0xab, 0x73, 0x53, 0x91, 0x12, 0x99, 0x94, 0xa5, 0x35, 0xd9, 0x25, 0xf6, 0x73,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
            ],
            [
                /* Point with smallest y. (3/3) */
                0x14, 0x6d, 0x3b, 0x65, 0xad, 0xd9, 0xf5, 0x4c, 0xcc, 0xa2, 0x85, 0x33, 0xc8, 0x8e, 0x2c, 0xbc,
                0x63, 0xf7, 0x44, 0x3e, 0x16, 0x58, 0x78, 0x3a, 0xb4, 0x1f, 0x8e, 0xf9, 0x7c, 0x2a, 0x10, 0xb5,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
            ]
        ]
        
        var bytes65 = [UInt8](repeating: 0, count: 65)
        let zeros65 = [UInt8](repeating: 0, count: 65)
        var bytes33 = [UInt8](repeating: 0, count: 33)
        
        for i in 0..<validPublicKeyBytes.count {
            // no odd/even
            bytes65[0] = 0x04
            bytes65[1..<65] = validPublicKeyBytes[i][0..<64]
            let pubKey = Secp256k1PublicKey(bytes: bytes65)
            XCTAssertNotNil(pubKey, "pubkey deserialize \(i)")
            
            bytes65[0..<65] = zeros65[0..<65]
            pubKey?.serialize(bytes: &bytes65, compress: false)
            XCTAssertEqual(validPublicKeyBytes[i][0..<64], bytes65[1..<65])
            XCTAssertEqual(bytes65[0], 0x04)
            
            // correct odd/even
            let isOdd = validPublicKeyBytes[i][63] & 1 == 1
            bytes65[0] = isOdd ? 0x07 : 0x06
            let pubKey3 = Secp256k1PublicKey(bytes: bytes65)
            XCTAssertNotNil(pubKey3)
            XCTAssertEqual(pubKey, pubKey3)
            
            // wrong odd/even
            bytes65[0] = isOdd ? 0x06 : 0x07
            let pubKey4 = Secp256k1PublicKey(bytes: bytes65)
            XCTAssertNil(pubKey4)
            
            bytes33[0] = 0x02 | (isOdd ? 0x01 : 0x00)
            bytes33[1..<33] = validPublicKeyBytes[i][0..<32]
            let pubKey2 = Secp256k1PublicKey(bytes: bytes33)
            XCTAssertNotNil(pubKey2)
            XCTAssertEqual(pubKey, pubKey2)
            
            bytes33[0..<33] = zeros65[0..<33]
            pubKey?.serialize(bytes: &bytes33, compress: true)
            XCTAssertEqual(validPublicKeyBytes[i][0..<32], bytes33[1..<33])
            XCTAssertEqual(bytes33[0], isOdd ? 0x03 : 0x02)
        }
    }
    
    func testInvalidXYPublicKeySerialize() {
        let invalidXYBytes: [[UInt8]] = [
            [
                /* x is third root of -8, y is -1 * (x^3+7); also on the curve for y^2 = x^3 + 9. */
                0x0a, 0x2d, 0x2b, 0xa9, 0x35, 0x07, 0xf1, 0xdf, 0x23, 0x37, 0x70, 0xc2, 0xa7, 0x97, 0x96, 0x2c,
                0xc6, 0x1f, 0x6d, 0x15, 0xda, 0x14, 0xec, 0xd4, 0x7d, 0x8d, 0x27, 0xae, 0x1c, 0xd5, 0xf8, 0x53,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
            ],
            [
                /* Valid if x overflow ignored (x = 1 mod p). */
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x30,
                0x42, 0x18, 0xf2, 0x0a, 0xe6, 0xc6, 0x46, 0xb3, 0x63, 0xdb, 0x68, 0x60, 0x58, 0x22, 0xfb, 0x14,
                0x26, 0x4c, 0xa8, 0xd2, 0x58, 0x7f, 0xdd, 0x6f, 0xbc, 0x75, 0x0d, 0x58, 0x7e, 0x76, 0xa7, 0xee,
            ],
            [
                /* Valid if x overflow ignored (x = 1 mod p). */
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x30,
                0xbd, 0xe7, 0x0d, 0xf5, 0x19, 0x39, 0xb9, 0x4c, 0x9c, 0x24, 0x97, 0x9f, 0xa7, 0xdd, 0x04, 0xeb,
                0xd9, 0xb3, 0x57, 0x2d, 0xa7, 0x80, 0x22, 0x90, 0x43, 0x8a, 0xf2, 0xa6, 0x81, 0x89, 0x54, 0x41,
            ],
            [
                /* x is -1, y is the result of the sqrt ladder; also on the curve for y^2 = x^3 - 5. */
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2e,
                0xf4, 0x84, 0x14, 0x5c, 0xb0, 0x14, 0x9b, 0x82, 0x5d, 0xff, 0x41, 0x2f, 0xa0, 0x52, 0xa8, 0x3f,
                0xcb, 0x72, 0xdb, 0x61, 0xd5, 0x6f, 0x37, 0x70, 0xce, 0x06, 0x6b, 0x73, 0x49, 0xa2, 0xaa, 0x28,
            ],
            [
                /* x is -1, y is the result of the sqrt ladder; also on the curve for y^2 = x^3 - 5. */
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2e,
                0x0b, 0x7b, 0xeb, 0xa3, 0x4f, 0xeb, 0x64, 0x7d, 0xa2, 0x00, 0xbe, 0xd0, 0x5f, 0xad, 0x57, 0xc0,
                0x34, 0x8d, 0x24, 0x9e, 0x2a, 0x90, 0xc8, 0x8f, 0x31, 0xf9, 0x94, 0x8b, 0xb6, 0x5d, 0x52, 0x07,
            ],
            [
                /* x is zero, y is the result of the sqrt ladder; also on the curve for y^2 = x^3 - 7. */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x8f, 0x53, 0x7e, 0xef, 0xdf, 0xc1, 0x60, 0x6a, 0x07, 0x27, 0xcd, 0x69, 0xb4, 0xa7, 0x33, 0x3d,
                0x38, 0xed, 0x44, 0xe3, 0x93, 0x2a, 0x71, 0x79, 0xee, 0xcb, 0x4b, 0x6f, 0xba, 0x93, 0x60, 0xdc,
            ],
            [
                /* x is zero, y is the result of the sqrt ladder; also on the curve for y^2 = x^3 - 7. */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x70, 0xac, 0x81, 0x10, 0x20, 0x3e, 0x9f, 0x95, 0xf8, 0xd8, 0x32, 0x96, 0x4b, 0x58, 0xcc, 0xc2,
                0xc7, 0x12, 0xbb, 0x1c, 0x6c, 0xd5, 0x8e, 0x86, 0x11, 0x34, 0xb4, 0x8f, 0x45, 0x6c, 0x9b, 0x53
            ]
        ]
        
        var bytes65 = [UInt8](repeating: 0, count: 65)
        var bytes33 = [UInt8](repeating: 0, count: 33)
        
        for i in 0..<invalidXYBytes.count {
            // no odd/even
            bytes65[0] = 0x04
            bytes65[1..<65] = invalidXYBytes[i][0..<64]
            let pubKey = Secp256k1PublicKey(bytes: bytes65)
            XCTAssertNil(pubKey)
            
            bytes33[0] = 0x02
            bytes33[1..<33] = invalidXYBytes[i][0..<32]
            let pubKey2 = Secp256k1PublicKey(bytes: bytes33)
            XCTAssertNil(pubKey2)
        }
    }
    
    func testInvalidYPublicKeySerializations() {
        let invalidYBytes: [[UInt8]] = [
            [
                /* Valid if y overflow ignored (y = 1 mod p). (1/3) */
                0x1f, 0xe1, 0xe5, 0xef, 0x3f, 0xce, 0xb5, 0xc1, 0x35, 0xab, 0x77, 0x41, 0x33, 0x3c, 0xe5, 0xa6,
                0xe8, 0x0d, 0x68, 0x16, 0x76, 0x53, 0xf6, 0xb2, 0xb2, 0x4b, 0xcb, 0xcf, 0xaa, 0xaf, 0xf5, 0x07,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x30,
            ],
            [
                /* Valid if y overflow ignored (y = 1 mod p). (2/3) */
                0xcb, 0xb0, 0xde, 0xab, 0x12, 0x57, 0x54, 0xf1, 0xfd, 0xb2, 0x03, 0x8b, 0x04, 0x34, 0xed, 0x9c,
                0xb3, 0xfb, 0x53, 0xab, 0x73, 0x53, 0x91, 0x12, 0x99, 0x94, 0xa5, 0x35, 0xd9, 0x25, 0xf6, 0x73,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x30,
            ],
            [
                /* Valid if y overflow ignored (y = 1 mod p). (3/3)*/
                0x14, 0x6d, 0x3b, 0x65, 0xad, 0xd9, 0xf5, 0x4c, 0xcc, 0xa2, 0x85, 0x33, 0xc8, 0x8e, 0x2c, 0xbc,
                0x63, 0xf7, 0x44, 0x3e, 0x16, 0x58, 0x78, 0x3a, 0xb4, 0x1f, 0x8e, 0xf9, 0x7c, 0x2a, 0x10, 0xb5,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x30,
            ],
            [
                /* x on curve, y is from y^2 = x^3 + 8. */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03
            ]
        ]
        
        var bytes65 = [UInt8](repeating: 0, count: 65)
        var bytes33 = [UInt8](repeating: 0, count: 33)
        
        for i in 0..<invalidYBytes.count {
            // no odd/even
            bytes65[0] = 0x04
            bytes65[1..<65] = invalidYBytes[i][0..<64]
            let pubKey = Secp256k1PublicKey(bytes: bytes65)
            XCTAssertNil(pubKey)
            
            bytes33[0] = 0x02
            bytes33[1..<33] = invalidYBytes[i][0..<32]
            let pubKey2 = Secp256k1PublicKey(bytes: bytes33)
            XCTAssertNotNil(pubKey2)
        }
    }
    
    func testPrivateKeySerialization() {
        var randp = KeyGenerator()
        
        for _ in 0..<5 {
            let (privKey, privKeyBytes) = randp.genPrivateKeyWithBytes()
            XCTAssertNotNil(privKey)
            let pubKey = privKey.pubKey
            XCTAssertNotNil(pubKey)
            XCTAssertEqual(pubKey, Secp256k1PublicKey.init(privKey: privKey))
            
            var serializedPrivKeyBytes = [UInt8](repeating: 0, count: 32)
            privKey.serialize(bytes: &serializedPrivKeyBytes)
            XCTAssertEqual(serializedPrivKeyBytes, privKeyBytes)
        }
    }
    
    func testPublicKeyCombine() {
        let count = 6
        var pubKeys: [Secp256k1PublicKey] = []
        var randp = KeyGenerator()
        var sum = Secp256k1Scalar.zero
        
        for _ in 0..<count {
            let privKey = randp.genPrivateKey()
            sum.add(privKey.privKey)
            pubKeys.append(privKey.pubKey!)
        }
        
        let combinedPubKey = try! Secp256k1PublicKey.combine(pubKeys: pubKeys)
        let summedPubKey = Secp256k1PrivateKey(s: sum)!.pubKey
        XCTAssertEqual(summedPubKey, combinedPubKey)
    }
    
    func testPubKeyAtInfinity() {
        let privKeyBytes: [UInt8] = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                                     0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
                                     0xba, 0xae, 0xdc, 0xe6, 0xaf, 0x48, 0xa0, 0x3b,
                                     0xbf, 0xd2, 0x5e, 0x8c, 0xd0, 0x36, 0x41, 0x41]
        let privKey = Secp256k1PrivateKey(bytes: privKeyBytes)
        XCTAssertNil(privKey)
    }
}
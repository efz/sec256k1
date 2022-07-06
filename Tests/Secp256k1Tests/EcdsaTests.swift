import XCTest
@testable import Secp256k1

class EcdsaKeyTests: XCTestCase {
    var randp = Secp256k1KeyGenerator()
    
    func testSignVerify() {
        for _ in 0..<TestUtils.randTestCount*2 {
            let message = randp.genMessage()
            let privKey = randp.genPrivateKey()
            let pubKey = privKey.pubKey!
            var signature: Secp256k1Ecdsa? = nil
            
            while signature == nil {
                let nonce = randp.genScalar()
                signature = Secp256k1Ecdsa(message: message, nonce: nonce, privateKey: privKey)
            }
            
            let isValid = signature?.verify(message: message, publicKey: pubKey)
            XCTAssertTrue(isValid!)
            let wrongMessage = Secp256k1Message(s:message.s + Secp256k1Scalar.one)
            let isWrongMessageValid = signature?.verify(message: wrongMessage, publicKey: pubKey)
            XCTAssertFalse(isWrongMessageValid!)
        }
    }
    
    func testEcdsaEnd2End() {
        var bytes = [UInt8](repeating: 0, count: 65)
        let noneGenerator = Secp256k1DefaultNonceGenerator()
        for _ in 0..<TestUtils.randTestCount*2 {
            let message = randp.genMessage()
            var privKey = randp.genPrivateKey()
            
            /* Construct and verify corresponding public key. */
            var pubKey = privKey.pubKey!
            
            /* Verify exporting and importing public key. */
            let exportPubKeyCompressed = Bool.random()
            try! pubKey.serialize(bytes33or65: &bytes, compress: exportPubKeyCompressed)
            
            let pubKey2 = Secp256k1PublicKey(bytes33or65: bytes[0..<(exportPubKeyCompressed ? 33 : 65)])
            XCTAssertEqual(pubKey, pubKey2)
            
            /* Verify private key import and export. */
            bytes[64] = 0
            try! privKey.serialize(bytes32: &bytes)
            XCTAssertEqual(bytes[64], 0)
            let privKey2 = Secp256k1PrivateKey(bytes32: bytes)
            XCTAssertEqual(privKey, privKey2)
            
            /* Optionally tweak the keys using addition. */
            if Int.random(in: 0..<3) <= 10 {
                let tweakScalar = randp.genScalar()
                var tweakBytes = [UInt8](repeating: 0, count: 32)
                tweakScalar.serialize(bytes: &tweakBytes[0..<32])
                let tweak = Secp256k1Tweak(bytes32: tweakBytes)!
                
                try! privKey.tweakAdd(tweak: tweak)
                try! pubKey.tweakAdd(tweak: tweak)
                
                XCTAssertEqual(pubKey, privKey.pubKey)
            }
            
            /* Optionally tweak the keys using multiplication. */
            if Int.random(in: 0..<3) <= 10 {
                let tweakScalar = randp.genScalar()
                var tweakBytes = [UInt8](repeating: 0, count: 32)
                tweakScalar.serialize(bytes: &tweakBytes[0..<32])
                let tweak = Secp256k1Tweak(bytes32: tweakBytes)!
                
                try! privKey.tweakMul(tweak: tweak)
                try! pubKey.tweakMul(tweak: tweak)
                
                XCTAssertEqual(pubKey, privKey.pubKey)
            }
            
            /* Sign & Verify */
            let signature: Secp256k1Ecdsa = message.sign(privateKey: privKey, nonceGenerator: noneGenerator)!
            let isValid = signature.verify(message: message, publicKey: pubKey)
            XCTAssertTrue(isValid)
            
            /* serialize and verify */
            bytes[64] = 0
            try! signature.serialize(bytes64: &bytes)
            XCTAssertEqual(bytes[64], 0)
            let signature2 = Secp256k1Ecdsa(bytes64: bytes)
            let isValidAfterSerialized = signature2!.verify(message: message, publicKey: pubKey)
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
        XCTAssertTrue(sig3!.verify(message: message, publicKey: pubKey))
        
        let sig4 = message.sign(privateKey: privKey, nonceGenerator: CodedNonceGenerator(nonce: nonce2), maxAttemts: 1)
        XCTAssertNotNil(sig4)
        XCTAssertTrue(sig4!.verify(message: message, publicKey: pubKey))
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
        
        let pubKey = Secp256k1PublicKey(bytes33or65: pubKeyBytes)!
        let signature1 = Secp256k1Ecdsa(r: sr, s: ss)
        XCTAssertTrue(signature1!.isNormalized())
        let valid = signature1!.verify(message: message, publicKey: pubKey)
        XCTAssertTrue(valid)
        
        let ss2 = Secp256k1Scalar.neg(ss)
        let signature2 = Secp256k1Ecdsa(r: sr, s: ss2)
        XCTAssertFalse(signature2!.isNormalized())
        let valid2 = signature2!.verify(message: message, publicKey: pubKey)
        XCTAssertTrue(valid2)
        
        let ss3 = Secp256k1Scalar.neg(Secp256k1Scalar(int: 3))
        let signature3 = Secp256k1Ecdsa(r: sr, s: ss3)
        XCTAssertFalse(signature2!.isNormalized())
        let valid3 = signature3!.verify(message: message, publicKey: pubKey)
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
        let pubKey = Secp256k1PublicKey(bytes33or65: pubKeyBytes)!
        let pubKey2 = Secp256k1PublicKey(bytes33or65: pubKey2Bytes)!
        
        let signature1 = Secp256k1Ecdsa(r: sr, s: ss)
        XCTAssertTrue(signature1!.isNormalized())
        let valid = signature1!.verify(message: message, publicKey: pubKey)
        XCTAssertTrue(valid)
        let valid2 = signature1!.verify(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid2)
        
        let ss2 = Secp256k1Scalar.neg(ss)
        let signature2 = Secp256k1Ecdsa(r: sr, s: ss2)
        XCTAssertFalse(signature2!.isNormalized())
        let valid3 = signature2!.verify(message: message, publicKey: pubKey)
        XCTAssertTrue(valid3)
        let valid4 = signature2!.verify(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid4)
        
        let ss3 = Secp256k1Scalar.neg(Secp256k1Scalar(int: 2))
        let signature3 = Secp256k1Ecdsa(r: sr, s: ss3)
        XCTAssertFalse(signature3!.isNormalized())
        let valid5 = signature3!.verify(message: message, publicKey: pubKey)
        XCTAssertFalse(valid5)
        let valid6 = signature3!.verify(message: message, publicKey: pubKey2)
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
        
        let pubKey = Secp256k1PublicKey(bytes33or65: pubKeyBytes)!
        let pubKey2 = Secp256k1PublicKey(bytes33or65: pubKey2Bytes)!
        
        let signature1 = Secp256k1Ecdsa(r: sr, s: ss)
        XCTAssertTrue(signature1!.isNormalized())
        let valid = signature1!.verify(message: message, publicKey: pubKey)
        XCTAssertTrue(valid)
        let valid2 = signature1!.verify(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid2)
        
        let ss2 = Secp256k1Scalar.neg(ss)
        let signature2 = Secp256k1Ecdsa(r: sr, s: ss2)
        XCTAssertFalse(signature2!.isNormalized())
        let valid3 = signature2!.verify(message: message, publicKey: pubKey)
        XCTAssertTrue(valid3)
        let valid4 = signature2!.verify(message: message, publicKey: pubKey2)
        XCTAssertTrue(valid4)
        
        let ss3 = Secp256k1Scalar.one
        let signature3 = Secp256k1Ecdsa(r: sr, s: ss3)
        XCTAssertTrue(signature3!.isNormalized())
        let valid5 = signature3!.verify(message: message, publicKey: pubKey)
        XCTAssertFalse(valid5)
        let valid6 = signature3!.verify(message: message, publicKey: pubKey2)
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
        let valid = signature!.verify(message: message, publicKey: pubKey)
        XCTAssertFalse(valid)
    }
    
    func testCompatibility() {
        let msg_priv_nonce_sigr_sigs_pubx_puby: [[Bits64x4]] = [[(0x0, 0xff0100000080ff0f, 0x780ff03000000f0, 0xc0ffff07ff), (0xffffffe7ffffffff, 0x8003e000000000f0, 0x18000000, 0x0),  (0xe0ffffffffffe3, 0x700000000000000, 0xf8ffffff0f00feff, 0x30000f8ff1f0000), (0x8d048a14f4f5c003, 0x1b02768376666a51, 0x6895b1e8e27b8f2a, 0x69a1e6408f4a69be), (0xaf8ecd45d5f970f, 0x1b525271fae1b09f, 0xc11b6a7a709379c3, 0x18cc4bde38bde10b), (0x4c88de9a1c72e2bd, 0x57ff9086ed734b8b, 0xd71f9be632351f54, 0xd3151f43698ed0cc), (0xe4ce27b49a112d67, 0xd0df907e0a19c044, 0x9e005e6c763ece1a, 0x9612db0db81114dd)],
                                                                [(0xffffff87ffffff7f, 0xf0, 0x3000000f0ff1f00, 0x300000000ffffff), (0xffffffffffffffff, 0xffffffffff0700f8, 0x80ffff, 0xfeffffff3ff0ff1f),  (0xffffffffffffffff, 0x7f000000000000fc, 0xfcff, 0xffffffffffffff07), (0x90697593015c7e8a, 0x756bed5fc0f0d572, 0x4334e3df50b4a504, 0xef4c1510d5de4f8e), (0xc12da6ef0cb1c0cc, 0xe975cea997dd212f, 0x1c02157ad30171f6, 0x7beeaa3d8cb32c46), (0xec6c8a10f8aee1a5, 0x2f435eaa4f9edee5, 0x89d528c49fa0161f, 0x54f4c3a7f9a2593e), (0xb6610d7b35d8944b, 0x20f957146bfb618d, 0x62bc9ff214c23225, 0x4b5ff3d6b66dcf9a)],
                                                                [(0xf0000f800e0ffff, 0x80ff0300fc, 0xf00000000000000, 0xffffff1f000000fc), (0xf00fc0fffeff7f00, 0xfeffff7f000000, 0xc07f000000, 0xffffffffffff0000),  (0xf0ffff3f0000fe, 0x200000, 0x0, 0xf00000000000000), (0xe08a54a37fe60470, 0xbec0ced5ff3f9be8, 0x2c0dfe5bbe149951, 0x72ed9541b23bbf84), (0x49b0fecd24729ce2, 0x45b6b7fc8761a622, 0xc5d2da8964ff46d8, 0x369216f3efc53a5d), (0xec8d58d37dee0bb1, 0xb449a610a54b5a32, 0xc7af53223ec4dbb0, 0x8ca6995a369436ec), (0xb1617156779debf6, 0xe1f8ef8e590f5ff4, 0x2b268ea064da1e02, 0x239b5688bfb2573)],
                                                                [(0xffffffffffffffff, 0xffff9fffffffffff, 0xf0ffffffff, 0xff7fe0ffffff0100), (0xffffffffffffff7f, 0xffffffff1f00c0ff, 0xe00000fcffff, 0x3000),  (0x2000000000000, 0xf8ffff01, 0xc0ffffffffffff01, 0xffffffffff1f0000), (0xc764b141a41e5d38, 0xc86c51f356e62025, 0x35cda5003f432e46, 0x7647f866b87b7eb5), (0x4869ac70323892dc, 0x4aff6157b353a364, 0x376ae9f5c77a652d, 0x3af17d399d51a0a4), (0x19372d56b1719949, 0x976f288f3b57ab0c, 0xe88173c4eddcc7da, 0xf936d23be794193a), (0xddf3fd37a9771023, 0x6c59259b7aff5e93, 0xda10b6a9beb88aa, 0x5776b5e5f5f2ba31)],
                                                                [(0xffffffffff3f0000, 0xf8ffffffffffff, 0xffffffff03000000, 0xffffffffffffffff), (0xf0ffff1f000000, 0x0, 0x0, 0x100000000000000),  (0x0, 0xff00000000000000, 0xc0ffffff, 0xffffffff0f000000), (0x427abc15028892b6, 0x81e69c4d12977f3e, 0x398bdf4c586e217e, 0x9b17805818592823), (0x8682b82add31f865, 0xf73b84b64af8cfc0, 0x9cda6d32cfc973f3, 0x2bb126d1860bc206), (0x2110259fa4583445, 0xfc933884ec01c460, 0x8b63fe9609354258, 0xea4be48a28ce299a), (0xfea049e7a3628ed0, 0x999ac67bc9508f37, 0xc5b99c6c7ade72b7, 0x3d945619d3ce2037)],
                                                                [(0xe0ff0700c0ffffff, 0xffffffffffffff07, 0xff8fffffffff0ffe, 0xf8ffff), (0xffffffffff1f0000, 0xffffffffffffffff, 0xffffffffff, 0xff1f0000),  (0x0, 0xffffff1fc0ffff0f, 0xffffc0ffffffffff, 0xf8ffffff), (0x2b99113343db2fcd, 0xf3c6af9e046eb4f8, 0x6147c9fd30dade3b, 0x42baaaf072c55ad0), (0xe7aedd5ec6329ac5, 0xb5eb54542c25fb2e, 0xb13306e227eed8af, 0x7a0db5d8b8c4405e), (0xf8449161edf9de9c, 0xb8d85849ae152421, 0xe2073923b4b8fe86, 0x86a3db1c18909d82), (0x89e9598fed9e5875, 0xd23b9aa9fd5c6846, 0x31ce5b4953a097ec, 0x16f9defe96150e6a)],
                                                                [(0xffffffff00ffffff, 0xf03f40f807bfff, 0xffffffffffffff7f, 0xc00100ffffffff), (0xffffff0f80ffffff, 0xfcffffffff, 0xfcff00, 0xffffffffff030000),  (0xffffffffffffffff, 0x803f0000000000e0, 0xff7f00e01f00807f, 0xff0300f8ffffffff), (0x68631b257db902d8, 0xc74b612e2526ebd5, 0xe5198760a9eac957, 0xb9a33f7f42912590), (0xab2354ee2b9755e, 0x6ed287db5d033e17, 0xeea29a5b8ed9b77f, 0x68c02601fa32e05b), (0x543c6c6d227e6e2d, 0xcde04e022717631e, 0xa3cb6298c85c5f4f, 0xd78da43555e2643b), (0xdb6d23fa0778290d, 0xbbd84a7fc31baf05, 0x3ef840cec095b987, 0x2ab470592b867481)],
                                                                [(0xfcffff7f, 0x0, 0xfeffffffff070000, 0xff1f0000f07f00), (0xfcffff1f000000f8, 0xf00f000c0000, 0xf00000000000000, 0xffffff00f0ffffc0),  (0xffff3f00feffffff, 0xffff3f000000ffff, 0xffffffffffffffff, 0xfec0ffffff), (0x24ddd12fa5d84443, 0xe195f738da4028ac, 0x5102292bdb849971, 0x8f2f708409f21af3), (0x85efad92551a7e1, 0xeb0ced1900ddde06, 0x55cafbea336146a, 0x68e141b05ee7b615), (0x154f7c8427090073, 0x42cf2db0626d07d2, 0xcdf0fa4b12a3a32c, 0xdc99c5532b5524b6), (0xd1b228694131666f, 0x18f9295b1c1cb52, 0x4ce13cbf72369c31, 0xff899af33385ed69)],
                                                                [(0xff0f0080ffffffff, 0x80ffff, 0xf8ffff0f000000, 0xffffffffffffff01), (0xe0ffffff, 0x20000, 0xffcffe0ffffff7f, 0xf8010000000000f8),  (0x80ffffffff010000, 0xff3f0000000000, 0xff1f00000020803f, 0x0), (0x8645512baaa1f8d1, 0x73666f387ee0e0d6, 0x14c0163a5932198e, 0xde2bd4fabd45b4c2), (0x59422370e5f3ef01, 0x967bf786d94fd43e, 0x5d23f5ba5d1f0b85, 0x6a5b2a92f99e6c8a), (0x131d3dac1c68b0b8, 0x9c8829f07dec883c, 0xbfa529d96416794b, 0x889d5c560e7ca39b), (0x7b889da660904756, 0x913aba835ff302db, 0x95f920de83fbe043, 0x5a3ca0f58ec19c94)],
                                                                [(0xffffffff7f000000, 0xffffffffff0180ff, 0xffffffffffff07c0, 0xf8ffffff), (0xffffffe1ffffffff, 0xf0ffffff, 0xf0ffffffffff03, 0xff07e0ff7f000000),  (0xffffffffffffffff, 0xffff01000000c0ff, 0x80ffffff, 0xffff000000000000), (0xc679be503b9ba494, 0xbaac70d0c60767c6, 0xa1a3ae46b6be0fdb, 0x2efd041c623f5f2c), (0xd4859aa99ab6d0a9, 0x3e178abaadc230c8, 0xbb5cce4b400d5d7f, 0x1160c64b4b04f88), (0xd303e32910fef419, 0x9d82cd61b9b37405, 0xe2b2d8732ff9d486, 0x38a08040575a9604), (0x924d19cac33bed0b, 0xd1fe0a096339de50, 0x3de174b4b5d0aac2, 0xf9edf6d3968c57a)],
                                                                [(0xfefffffff83f00, 0xff7f000000000000, 0xf8ffff, 0xffffffff03000000), (0xfcffffffff, 0xffffffffffffff07, 0xffff3f00000080, 0xffff1f00fe000000),  (0x1ff8ffffffffffe7, 0xffffffffffffffff, 0xffff0f00000000f0, 0x3e000000fcff), (0x99f7154464ba442d, 0xa9188ff3d57ad361, 0x3a1509ecdfd3d5d9, 0x45452c970a03eb43), (0x1d3709f33ff3784e, 0xb0e3a495d595be19, 0xb229c745fc3b0cdd, 0x615c3ea3859b1ef3), (0xb4021b10fda24444, 0x796d1f4c9d84f4e3, 0xaf2dbc6001758156, 0xb512a5d65a81818d), (0xdc5b87e3ca5196e8, 0x4e17eb57ec104ac1, 0xe9a5611aed013c5, 0x6b6931ae8ddd10a9)],
                                                                [(0x1ffcffffffffffff, 0x1f0000fcffffffff, 0xfe87ffffffffffff, 0xf0ffff070000), (0xf0000ffff, 0x0, 0xff1f80ffffff7f00, 0xf00300000000f0),  (0xf8ffff1f000000, 0xfeffff1f0000, 0xfffffff13f000000, 0xfffffb00fe01ffff), (0xfd8ab11fdb189345, 0x8b31ebd9c5ccec92, 0x39f854475b7fd4a3, 0xc2a72e27befe9f79), (0x4a83da0b6efd1ae7, 0x117d7a4b07d7f4d0, 0xa50395d739cfddb4, 0x6d90bf18328c2eb6), (0xcd3f691e68789d16, 0xa6855839a7ab650d, 0x88c53171a18150bc, 0x534c380c86787a32), (0xf3179151aa15d4a8, 0x34cae5444e87df0d, 0x40ed42f0c3946e67, 0xffd2083e3782dac3)],
                                                                [(0xffffffffffffffff, 0xffffff0300e0ffff, 0x100fcff, 0x700e00100000000), (0xfeffff, 0x80ffffffffff1f00, 0xffffffffffffff3f, 0xf0),  (0xff3ff8ff07000000, 0x80ffffffff, 0xe0ffff7f000000, 0x80ff1f0000), (0xaecf5b7b77f94dce, 0x4d6b73c639b479bc, 0xb770a2620920292c, 0xdf56120eccccf2b), (0x3b0cf712e6eba2b7, 0xf03101fa352f2185, 0x20f0f995f3989c1e, 0x2a2dcc4143fbdb5c), (0xa7267a2c451b19fe, 0x5f4d46baf21e4105, 0x434ae85cd690f8e2, 0x732ce0f400d310c5), (0xc3bc667941fa0da8, 0x69d192026dbe87f8, 0xa318ba349d1acfc5, 0x33f077caf17e2274)],
                                                                [(0x1f000000e07f0000, 0xfcffff3f0000c0, 0xff0700f007000000, 0xe0ffff), (0x0, 0x80ffff0f000000, 0xf8ff7f00, 0xfeffff0300000000),  (0xffffff1f00fc0700, 0x80ffffff07ff, 0xff0700f8ff1f, 0xf8ff0000000000), (0xff1bbcfff10557f3, 0x8e05fa0c74b3516, 0x52a027feb7dc33a4, 0x5f871ac3e9f0ba3e), (0x2609874378accc97, 0x855bf01248ca1f6f, 0x167bc23b3c0a5543, 0x1c2268eb48e00c3), (0x37f4827182912463, 0xd7e918902f5e92d0, 0x4e2c4e153f8c5608, 0x769a3d81f157b91a), (0x7c8123c903415de2, 0x36694a3d9a9005b9, 0x51b0d3d9dec42bc3, 0x4d5ff8ee28f92c33)],
                                                                [(0xf0ffffffffffff7f, 0xf0ffffffff1f0000, 0xffffff0f00000000, 0xe0ffff), (0xffffffffff0700c0, 0xff0100000000e0ff, 0x10000ffffffffff, 0x7000000f8ffffff),  (0xfcffffff1f, 0x0, 0x0, 0xf8ffff7f000000), (0xcdc90483dc0d79bf, 0xa4b1eb1365640641, 0x499014a91788ea7c, 0x3c75fc5c5b4e3950), (0x273ba0c3acb3f9e2, 0xffe42f45f3d946ca, 0xdc1dbd051631967f, 0x76b95ffbdd910432), (0x862ca2371eac5172, 0x9add3849860d7b8c, 0x7be85c42f59ec5d8, 0xc943f131cbdf4342), (0xeac37a83d2a502fe, 0x102cfe4e4ecf161d, 0xa2f803da8b96fefa, 0x3327867989ce6835)],
                                                                [(0x300000000200000, 0xc0ffff7f00ffff, 0xff0100, 0xffffffffffff0300), (0x0, 0xfeffffffff030000, 0x807f000000000000, 0xfeffffff3f00),  (0xf8ffffffff, 0x0, 0x0, 0xff3f000000000000), (0x786efb1efbdc72eb, 0xcf0e65272782c4d1, 0x6b30b97556160359, 0x89d07121bfe3b44c), (0x9eb1a91677830c56, 0x73b945d41990ab85, 0x857720aedbdca2, 0x22764e880eae8abc), (0x72a1270bc93cceeb, 0x8b877095c85c3aab, 0x73ef466712abb48e, 0x5daa3934a2e39d18), (0xc2eaf57aedb80bfe, 0xf4bcf1f5f9b50b8d, 0x4f5538aa4044da49, 0xb5501b7fa3f592f2)],
                                                                [(0xffffffffff7f0000, 0x8f0, 0x0, 0xfeffffff7f0000), (0x7f00000000000000, 0xfeffff, 0xfeffffffff7f, 0x1fe0ff1f00000000),  (0xf8ffe70f00, 0xfcffff000000, 0xffc37f0000000000, 0x80ffffff7f80ffff), (0x684a4abcc73765c7, 0x2081ba331e2931b6, 0xb254b2167fbcd694, 0x8adaef9386e726b5), (0x18f84a09c6f821a7, 0xa8157df24e4455a0, 0x5444014d2e234b62, 0x5811bb28054b2f51), (0xf16c30a90f5bb46a, 0xff2638b936e7b17, 0x36a18b169812a557, 0xffcac7b451a76f0b), (0x582c28f6c7896ee4, 0xe16c34b9b6d85b01, 0x45517dbf0ca68642, 0x98cc83af68ad1832)],
                                                                [(0xe0ffff7f00000000, 0xffffffff03000000, 0x1f000000000000fc, 0xfcffffffffffffff), (0xfeff1ffeff3f0000, 0x7000000780080ff, 0xff0000f8ffffffff, 0xfeffffffffffff),  (0xffffffffff130000, 0xfeff03ff, 0xffffffffffffff1f, 0x1fc0ffff07f0ffff), (0x81d41cc31a357e3b, 0xc96dd614e69285e9, 0x1f690913521ff140, 0x15f0be8f0f9f44c0), (0x3d7134386f325c79, 0xf5a4dd615fdb9528, 0x8d12d008bd404e10, 0x10c78aa1a209464a), (0x95c5d1257539681b, 0x8c92ea3318c54c34, 0xade879a9694d2461, 0x15b7a97648f14d2), (0xb20586f1080183e6, 0x647b5d1713a5aa35, 0x7ad628665615bb31, 0xb6bbbcb50be5f97)],
                                                                [(0x0, 0xffff010000000000, 0xf8ffffffffffffff, 0xfeffffff07), (0xff3f000000000000, 0xf00000feffff, 0x0, 0xffffff1f000000),  (0xffffff3f00000000, 0xff0000feffffffff, 0xfeffffffffffffff, 0x803f000000000000), (0xd21d28005f93732, 0xeb760d2a1ea2f91a, 0x6aaa54b7f8e718a2, 0xdfe26bce8e11fbe2), (0xb1bfb69c21499d0, 0x416f51ba3484f77b, 0xff97dac4953d601b, 0xa3401de1f115f35), (0x9215e226c0792b9c, 0xc0a555d406839fbe, 0x1f7842fc95cda041, 0x903e5f4f1bd43daf), (0xb16a7199236d1c4, 0x77b60a17093fd26a, 0x56065a7b97791c0e, 0x2a25f7ccee42a02e)],
                                                                [(0xffffffffff1f00c0, 0xff1f000000f0ffff, 0xf800000000ffffff, 0xffffffffffffff7f), (0xffffffffffff00, 0xffffffff3f000000, 0xffff7f0000f0ffff, 0xff3f00f0ffffffff),  (0x30000c0ffff01fe, 0xf80100000080, 0xff00ff0000000000, 0xc0ffffff), (0xd69e220a256825f7, 0x9db37b4f67590c2d, 0x21aae3e3285cb96, 0xf82d055942f95ef4), (0x3e7a99a9a25e2e04, 0x7fd6a83aeda93c93, 0x3f78f2798f5ec517, 0x20d642a1fe67fc73), (0x77acd67b270bb02, 0xe542eb8b04e6f72b, 0xa3e043217e40e9cc, 0x2b779b74ca68c6fe), (0x32cf914b5611ca57, 0x58f50fb74a956e5e, 0xec8e64c6de456a08, 0x13f06c6893ebdf2b)],
                                                                [(0xffffffffff3f0000, 0xe0ffffffffffff, 0xe0ffffff1f0000, 0xffffff0000c00000), (0xff1f00000000801f, 0x80ffff3f80fcffff, 0x800700c00f0000, 0x0),  (0xffffffffffff0100, 0x20000000c0ffff, 0x0, 0xff0000000000fc3f), (0xe9441d46cc193677, 0x28fd2d01e814d7c4, 0x8c2a7fdfe6f945d5, 0xdeeb46c11010eca2), (0x13eb5032105653d9, 0xcc2c37566bf03c1d, 0x535b5f5082e374e, 0x39fb9ff61e562de2), (0x7ada9a0568d8816e, 0x3199fa2944d88f1a, 0x33cccd3f8907712d, 0x6ed4f376e84f06d7), (0xd7480a0eb3c7e712, 0xa795a5087577c109, 0xeaca58076f1fa84b, 0x248a978e2ec3b9b2)],
                                                                [(0xffff010000000000, 0xffffffffffffffff, 0xf8ffffffff, 0xf8ffffff7f000000), (0x10080ffffffff7f, 0xfcffffff0300feff, 0xff7f803f00feff03, 0x3f0ff07fe),  (0xffffffffffffff01, 0xf8ffffffffffffff, 0x0, 0xffff010000000000), (0xf22c06634feb5d93, 0xee42b9a23e1d955f, 0x5e0081903bcc3a8c, 0x69e27d89cd3b9abd), (0xf9583fd2ad17542d, 0x906ff94bd369fbbb, 0x359fa59747196c1e, 0x1d553db2b21804c4), (0x67d771d346e2f31c, 0x1e70252e10bb02d8, 0x2be7075a0a15578, 0x39b2cfa4e58ecb48), (0x5522a9bd20bae392, 0x2ae8a56873763a4, 0x244030ea32e32a0a, 0xf07c991fbbed855d)],
                                                                [(0xff00feff070000fe, 0xffffffffffffffff, 0xffffffff1ffeffff, 0xc0ffffffbfff), (0x10000f8ffffffff, 0xffffff3f0000ffff, 0xf80ff00300, 0x0),  (0x80ffffffffffff, 0xf8ff010000, 0x7f0ffffff7f0000, 0xffff01feff0ff8ff), (0x29242dac82dd03e0, 0xda187185f2f518cf, 0x5bf6e2ad9fc07d3, 0x42243a97aac29f4e), (0x361a1bfef31fa0ae, 0x478e7862ab3bb19, 0xbcc09cb15b0afd60, 0x2e83fec6e0a067d), (0xc393ef5eb334d9b6, 0xf2e6c33fb72bdb04, 0x6e847e147c857dc4, 0xf2084a948ccf09d7), (0x5a7b17f09052e551, 0xf6d7c4d3411f4613, 0x50f2dad7ad09e3a0, 0x453d271eee486d82)],
                                                                [(0x801f000000, 0x0, 0x0, 0xff01000000feff03), (0x1ef007000000c0ff, 0x7f00f8ffffffff, 0x0, 0xf0000),  (0xc0ffffffff, 0x30000000000, 0xf0ff0700, 0xffffff0000000000), (0x75d35751e7ae3f6c, 0x23530aef5148c67, 0x16361de8c6f13c3d, 0xfb6a690b69be87a9), (0x3995a06673edf6d, 0xb7133a4819a702d0, 0xb02cfd546d78c272, 0x3e433d339718d5d3), (0xf31be10dccc3fd0e, 0x178fe08d168b9720, 0xbb749272a96357a7, 0x855787e44668f5d), (0x24d93dfb422dfdf7, 0xb93d5bf5d5419545, 0x2b247da584b59dfe, 0x38d37b0e3900ba5b)],
                                                                [(0x3e000000001e0080, 0xfc, 0xf8ff070000, 0xff1f0080ff010000), (0x3f00fe1f00000000, 0xf0ffffff, 0xffffff1f00000000, 0xffff0f0000ffffff),  (0xffefffffff000000, 0xffffffffff, 0xffffffffffffff3f, 0x3800000000f8), (0x3d217dd1eb92aecb, 0xd75bd01dce740b33, 0x694714873c8cf2eb, 0x29db2870eac6542e), (0xc28743961518d8ab, 0x474e8f4864dad0c0, 0xf03b917a72e6fd92, 0x3220d89129ee868c), (0x535115e4e79bec89, 0xf17e3b172d692ea2, 0x154afd0dc6eeee38, 0x52bbc24e40044224), (0x2b4f8cfa9e1b8ed0, 0x18d732796c527563, 0xd8b62e062d209885, 0xc3b80acf3b9ce97e)],
                                                                [(0x80ff, 0xfeffffffffff1f, 0xfdffffffff3f0000, 0xff030000000000fc), (0xfc0180ff3f0000, 0xf9f8ffffff03801f, 0xe0ffffffffffffff, 0xffffffffffff0f00),  (0xf000000040000f8, 0xf8ffff, 0xe01f000000, 0xff0fc0ff03000000), (0xea90a6c6010cc0d5, 0xb74362e1dafeb7aa, 0x35d6e8f8bc6270a, 0x271220bf3ec1adc3), (0x2a0aba02e9f291c1, 0xf9b81f8768fca185, 0xd6025382877ac49b, 0x3b13e5962a008a47), (0x5dcc93658f5a1c88, 0x35bca2161d312761, 0xe2e8ba55bfd5ed6e, 0x1d4f2a37a56f0de6), (0x8a77251c0de58869, 0xd0df286c1079c993, 0x3badf85d353819bd, 0xbfb7c0f6c2eddbc4)],
                                                                [(0xfcffffffc0ffff, 0x0, 0x0, 0x80ffffff0700), (0xffffffffffffffff, 0xf8ff, 0xff07000000000000, 0xf0ffffff),  (0x0, 0xffffffffffff1f00, 0xffffff03f00000fe, 0xffffffffffffffff), (0x568963ffbd2866d9, 0xbd5266865d45d0c7, 0xe0d4f6a0679bd75b, 0x1edf0a4ed9f1f888), (0x2fe3654773739734, 0xe0da0c3360d5b20f, 0xe65ad66ee0b26a0d, 0x4a1122070f7941f1), (0x5e5d7666c4887607, 0x3601bba10b480f1e, 0xe6a256828b8e9aa4, 0x9644c2286904ebaf), (0xd646924a19c602da, 0x766cbe9efaea189f, 0x30ff32638eb880ca, 0x3c69e472f8626d41)],
                                                                [(0x80ffffffffffffff, 0x0, 0xe0ff1ffe030000, 0xffff030000000000), (0xffffffffffffffff, 0xffffffffff01fcff, 0x3800feffffff, 0xe0ffff1f0000),  (0xffc0ff1f00c0ff80, 0xe0ffff070000c0ff, 0x0, 0xffffffffffffff00), (0x39612f4f137225ef, 0x88a6c748e26bb9d3, 0xadbb3c0019f29d29, 0xadf89dd6d9991fe7), (0x3a058f2da78a483c, 0xf197f4f008fa605a, 0xfb13f61729117556, 0x271f6473b8793cb3), (0xbfd1a6eb33fba424, 0xb208ced38f6335cd, 0x9c7c581679e7fee9, 0xd299bebd6d797c3e), (0x76ff843a2c661ca8, 0x9698ed5f1ec99dd, 0x3c295121f2c041da, 0x3089394fe8a1b3e7)],
                                                                [(0xf8ffff, 0xf87f0300, 0x0, 0xfeff1f), (0xffffffffffff1f00, 0xffffffff3ff8ffff, 0xe0ffffffffffff, 0xff01000000000000),  (0xffffffffffffffff, 0xffffffffffffffff, 0xfeffffffffffff, 0x100f8ffffffffff), (0xbed8900a2842a9d0, 0xb3e47ecc05c872ed, 0x5a396cc22629a715, 0x89c6baf6ea52169a), (0xf2de44c3e125c85f, 0x73e5ef3b864c311a, 0x44faa9b76206a806, 0x56f7f7cc231e077e), (0x6358aa47c62807c2, 0x551275f231920fc3, 0x1b50ed0c8c197b9d, 0x8d97978589ae4b6), (0xef1429c1714ec5e0, 0xceee05f874ad9e17, 0x47d3ee6eae636fdd, 0x7e18ebb8f1ebcd45)],
                                                                [(0x80ffffffffffffff, 0xffffff0000000000, 0xfe0700fc, 0x100000000000000), (0xff1ff807f8ff3f7e, 0xfcffffffffffffff, 0xc000000000000000, 0xffffff0000000000),  (0xe00100, 0xf8ffff0f00, 0xff0f0000fe1f0000, 0x80ffffff7f00fc), (0x2f17d1760e69510d, 0xd585ead8f942b937, 0x110f5f1915bbf85d, 0x1dbc987b4ece5705), (0x52a0a1a8950e49b3, 0xde040fc9050437cc, 0x574756b453950e77, 0x2856b8eb7dc700b1), (0x86952e7585ce0e8, 0xcffa0349071c7abb, 0xdf682dc5d557fe0d, 0xf504715ad718b64e), (0xf392a7a349151206, 0x5e34f3a451ee7a3d, 0xae47a0b86fd7a0ec, 0xdf9caa7caef7f2c)],
                                                                [(0x7fe0ff7fe0ffffff, 0xc0c0, 0xffffffffffff0300, 0xf8ffffffffff), (0xffffe10fff070000, 0x3fe0ffffffffffff, 0xffffffffffffffff, 0xffffffffff07f8ff),  (0x0, 0x8fff030000000000, 0x800100000000f8, 0xffffffffff0f0000), (0xa56268e66de2b5c3, 0x96fa19c2fcf3d00f, 0xba7bf86a9d86baf8, 0x35d53bd0c75043d0), (0xfd704333514b6501, 0xd22bcecab7ed0ed0, 0x2e9b3e0407f5065e, 0x2436857ca2828ffd), (0x42b0c014f5cddd53, 0x8402db326b527e01, 0x882d822a587ada2f, 0x350eacaba646ed44), (0xe8abeb39309cbe9c, 0x7c362b6778aa056b, 0x2a0f3608aeafea7b, 0xf0dbdd038cfff588)],
                                                                [(0xffff7f000000f8ff, 0xfeffffffff, 0xffff7ff8ffff7f00, 0xfffff9ffffffffff), (0xf8000000fe, 0xc0ffff1f0000, 0xffffffff03fe0f00, 0x70000c0ff3f00e0),  (0xfffff3ffffffffff, 0x80ff0100000000e0, 0x30030000000c01f, 0xf0f9ffffffff), (0xb9ece6a9790cb3d5, 0x1dc09cd6bf0e51e, 0x5c18ec356df8ff1b, 0x1a971684de849b9d), (0xc34924e03b576e7d, 0x48a0d242bd8bf186, 0xa4259e5f797e55e1, 0x1c1cae804846797a), (0x32c345735f27f305, 0x22f8c4562b010e0b, 0xaa7d522eb29ca1c8, 0x5bc0109142bfc5f6), (0xbc33bb737c1c8901, 0xfb2559c277708b48, 0x864d3f5eb0965b46, 0xc6cc28ce20d6f07b)],
                                                                [(0xffffff, 0xffffff1f0000ff0f, 0x80ff1f000000c0ff, 0x0), (0xfc0ffffffffffff, 0xffffffffffffffff, 0xffffffffff7f00fc, 0xffffffff7ff8ffff),  (0x300000000f8ffff, 0xe0ffffffffffff7f, 0xffff3f0000000000, 0xffffffff01f0ffff), (0x298a206b5f99cdf9, 0x5da61a49e70408d3, 0xde901fba90f16a69, 0xed526a5d52d75d53), (0xa8646596c79f6003, 0xcdbd593df6b28cac, 0xc6ed81766a8c8399, 0x4260252b4ea05f2d), (0xc2022a0ba229ae5b, 0xaa9722a7e6e4d3e4, 0x948d23c7426cb51c, 0x3fff3f1fcaca1bd3), (0x363943d0ff8258fa, 0x3a37b9ed0ed90036, 0xe4e755c9939ec6f1, 0xd1210e8c7f1518c9)],
                                                                [(0xffffffff00000000, 0xffffffff0700ffff, 0xf0ffffffffffffff, 0xff0700e0ff010000), (0xe0ffffffffffff, 0xe0ffffffffffff7f, 0x0, 0x0),  (0xffffffffffffffff, 0xff01f0ffffffffff, 0xf8ff3f0000feffff, 0x0), (0x4fab0fd2ffb266ac, 0x6a6b888538207ac1, 0x5c76d801783d40c8, 0x137c0955b98f4770), (0x122c46404f70c713, 0xbe0f387a9b6633de, 0x9cfe80dbf3a540de, 0x21725abdea17ed28), (0x305923b1db8197da, 0xa1171cc5dd7a43d3, 0x869cbb734a426514, 0x7eb0cb222186458), (0xad3f684f4cbe2533, 0x35a8bb288bfa3a0c, 0x3dece140d1943b23, 0xac0ad1f3fa381d8a)],
                                                                [(0x0, 0xc0ffffffff01, 0xffffffbfffff7f00, 0xfffffffff1ffffff), (0xf801000000, 0xc00100, 0xf8ff0f000000, 0xf0ffffffff3f0000),  (0xffff7f000000fc0f, 0xf0000000000feff, 0x80ff0ffc, 0x7ff8030000e0ff07), (0x44dc837bff55790e, 0x8c89a1ff23a7953f, 0xeb9c76985ea1586b, 0xeeeb7c5798ca25e8), (0xfd6a7f8155b9ad59, 0x6cbe379df7211ab1, 0xa8dd23947d5ff368, 0xa670ad7c8ba25ea), (0x9edc8b1368a69e60, 0xe28633ad69f04bc, 0x80c1a5cfc9063fc6, 0x59699a20b19b80ce), (0x110c6bbdb9d67285, 0xb251473c062af831, 0x2451d514585c750, 0xb584604322eb7d78)],
                                                                [(0xc0ffffff07, 0xfe0700, 0xffffffffffffff1f, 0xf0ffffffff), (0xf8ffffffff, 0x0, 0x70000000000ff07, 0xfcffffffff),  (0xffffffffffffffff, 0x800f0ce0ffffff8f, 0xc0ffffffffff0700, 0xf00000000000000), (0xf741fb9f59d344d9, 0xeefe4efee8a8e40c, 0xea4ad8babef44d71, 0x1e62a0f56a716c48), (0x1c563266ac4b6228, 0x2d3f671c57220ff5, 0x65ce8d19227fdd52, 0x48a9150b935c11c0), (0x7144325ac18983b6, 0xfd61e520666105ab, 0x8546be76550e3a6a, 0x47402b3c10b98be3), (0x2604dcf4bdcdf3d6, 0x1543eb5a0c831a75, 0xa68212abc5e8c08a, 0x753d180264aee2aa)],
                                                                [(0xffff01000000ffff, 0x80ff, 0xdfffffffff030000, 0xfeffff1ff8ffff), (0x83ffffffffffff00, 0xf0ffffff03f0ff, 0x80000000, 0x10300f8ff010000),  (0xf0ffffffffffff, 0x80ff0000f801, 0x0, 0x700000000000000), (0xaa9578a7cb3b1af1, 0x1492e84fa2b3d541, 0x3c804273b60fc6da, 0x287e6656002a25), (0xb17373e0859eaac3, 0x564c3ebbc063d9e4, 0xb6fe505bae28ee4e, 0x4ecf8a4fdea9ffaa), (0x7f492931097d6551, 0xbe721e8a2832f2ef, 0xe9aafd23eb41b897, 0xb36801f39d6c1667), (0xa91698c430b1609e, 0xb276215ccd13063, 0x93042bdea527a3c4, 0x6b7e1cfad47ec053)],
                                                                [(0xfeffffffff3f0000, 0x80ff00000000001c, 0xe0ffffffff0100, 0xffffffffff7f0000), (0xffffffffffffff7f, 0xf8ff00ff, 0xffff000000000000, 0x6000000000ffffff),  (0xffffff01000000f8, 0x7c0000000000f8, 0xffffffff01000000, 0xffffffffffffffff), (0xe73994d03c9bf48a, 0x571abca6e678f7a4, 0x7ad1f81b7bdabad9, 0x600ac18f0020e48), (0x3ef09d8fb50ecbd5, 0x9ecef21f565bf228, 0x26b89a55cb7c376f, 0x6665875c85033ef4), (0x3a75453ae63c6674, 0x9346ee642a8db30a, 0x4ff882223d6d7835, 0x681b0b81cc3547a9), (0xa4f755e1ab40e7f5, 0x78841930c5024e2, 0x1ca96dc99cd89f40, 0x94cd2f7a8c64b1c6)],
                                                                [(0x0, 0xffffffffff030000, 0xff9fffffffffffff, 0xf0ffffffffffff), (0xffffffffff010000, 0xffffff07f8ffffff, 0xf8ffffffff, 0xff07000000000000),  (0xffff7f0000feffff, 0xffffffffffffffff, 0xffffffffffff0180, 0xff7f00feffff00ff), (0x76ccd333ecc47a48, 0x30416a88604021d2, 0xcfc6d8027ef67542, 0x3ab0c8e7db54f4d3), (0x5d919f41e7901948, 0x77fec7a891639ec, 0xbe99d564fb05a49f, 0xabea44602e30670), (0x86bce6cef1b0f871, 0x80a3dc0f626ad70e, 0x3915a7ca95794c1c, 0x5c17cae556c12254), (0x1bcec9e94ff2e7bd, 0xa7357d700a698609, 0x445e3f4c7373b082, 0x1d525610b8299fa6)],
                                                                [(0xe0ffffffffff, 0xc00100, 0xf0ffff1f0000, 0xffffffffffff0700), (0xffffffffffffffff, 0x7c00f0ffffffffff, 0xffff0f0040000000, 0x1f000000000000c0),  (0xffff, 0x0, 0xffff010000000000, 0x10000e0ffffffff), (0x39e5b82ad074db24, 0x2e2a6dd35efc62aa, 0xa7e5f66328f27bc3, 0xb4863b2b7d4aba44), (0x5249614ccf5c69af, 0xb2a1b2ca6c66c8cc, 0xb1fc03cb5bb8cd49, 0x359d5cd66958b481), (0x801e90d68b5a1afc, 0xcc4c80e29fa4d3db, 0xce5b786bf7e6f191, 0x406c01817a5b4538), (0xb35c5a451575013a, 0x7add5b0935dd9234, 0x7ed4bcf9d5011b83, 0x8200f588f616b79b)],
                                                                [(0xf8ff1f000000c01f, 0xffffffffff010000, 0xff0380ffbf, 0xf00000000000000), (0x100c0ffffffffff, 0xfffe0000000000ff, 0x800f00feffff, 0xff0f80ffffff0300),  (0xff01000000000000, 0x7c000000c0ff, 0xffffffffff010000, 0xff1f1000000000ff), (0xc15fa00ee1f6ef7d, 0x59326d543c472563, 0xe3b6b9f1d87e7ba5, 0x26345988263bdfc1), (0x8378dbd4d5d3481e, 0x571d18e3e95e8295, 0xe8f0fcbee9699853, 0xdfb1c4d10416009), (0xb130225144897131, 0xe4f35c83ea8535fe, 0x378955d47d3e1be3, 0x1e628e3e0567a1f4), (0x45af65f1dced7d2c, 0xc4f41b62534ad4c8, 0xa8e7e7ef3d4f385b, 0x55120da2c6a0138f)],
                                                                [(0xffffffffffffff1f, 0xc0fffffff8ff, 0xfeffffffff0100, 0x3c0ffffffff0f00), (0xff7f000000000000, 0xf000000000000ff, 0x600000b0ffff, 0xffffffffffffff3f),  (0xffffffffff7f0040, 0xfe, 0xfcffff03e0ffff07, 0xf0ffffffff1f00), (0xf594bd8d7e6bdd6e, 0x46cb8cd85d170845, 0xe916b0628ff475b, 0x11a0b57ba0a24ba2), (0x43b635cd9af60d17, 0x796a38b8a09ecb74, 0x2578de7f9c1bb960, 0x385ffc641216929d), (0x70f55beb23a222ac, 0xf4b70a2074f44761, 0x18ebabd0395eb634, 0xde47f6cae0255402), (0xc1bb760fcdd2fe1d, 0x1dd94fc2e3725773, 0xff05359e3603b92, 0x418b68a7b52eb948)],
                                                                [(0xfeffffffff, 0x0, 0xe0ffffff0f00, 0x7fc0ffffffffff0f), (0xff01000000000000, 0xff0f000000f0ffff, 0xff3f000000ffffff, 0xc000f8ffffffff),  (0xff0100000000fcff, 0xfcff07c0, 0xffff030000000000, 0xffff7f0000f87fe0), (0xab1909aa415e585f, 0x75896a7bbbb36e20, 0xdad1afe6d42e6185, 0xdaa8760a2b0fab47), (0x7e52470f15c6dab, 0x612ec16e1f967834, 0x7655f22121801832, 0x207c887a1389a0e4), (0xa4c6b065d9fceb08, 0xe70714a89345fc56, 0xfa3ae562fe622915, 0xda365980ee563238), (0xf0fac9d81e3bfeda, 0x55c93047884ad39f, 0x9c978fd9f45a9639, 0xeb090ccaa01112d2)],
                                                                [(0xf00000000f8ff03, 0xe0ff, 0xc0ffffff01, 0x8000), (0xf002000000000ff, 0xffffffffff1f00ff, 0x0, 0xfffff37ff0ff1f00),  (0xfcffff0ff0, 0xffffffff07000000, 0xffffff3f0000fcff, 0x80ffffff), (0x4fa910f7db9f6ec, 0x98fb6baf39a03ce1, 0xe0a94ace87d3e49f, 0xcc216fb7ec96c645), (0x69784623ac5eb1b9, 0xa794d65a4bd61b04, 0xb46bd890ab41597b, 0x70086ac8e8e75a1b), (0x3742c3ff97ebc6a7, 0x3b6276a954eebca5, 0x8fb00524cdb17bc7, 0xe18a84e08505e2c5), (0x54f36b3a51806129, 0x494ea39b18d803a0, 0x1d50f35b0f88d455, 0x787e1db8d174d175)],
                                                                [(0xfcffff03, 0x0, 0x100000000000000, 0xf0ffffff), (0xf800e0010000e0ff, 0xc0ffffffffffffff, 0x700000000f00000, 0xffffff0100000000),  (0x80ffff7fff7f00f0, 0xffffffff07000000, 0xfcffffff0f00fe, 0xffffff0000000000), (0xac41c068521355a6, 0x3de5cfca9a98567f, 0xe1beeccb329bd5bc, 0x64cab56e0f73ab01), (0xd07d4f1d6466561c, 0xe426c8da1ba0644a, 0xe1f81f2b7fbc97ed, 0x981dc7f17f8f425), (0x860a989ff0a126e3, 0xf5afef3507177d27, 0x2d71a9e8f7a9ab63, 0x9beef8fc3b3fe278), (0xe225b590d3f2e9f7, 0xa96dedffe9dfc7a2, 0xcb07331c5407e7fb, 0xb5df4cc3888deef9)],
                                                                [(0xffffffff00000000, 0xffffffffffffffff, 0xc0ffff, 0xffffffff3f000000), (0xffff0340007c0000, 0xf8ffffffffff, 0xffffff1f00000000, 0xc4ffffff1fffffff),  (0xffffff0f000000fe, 0xe0ffff000000c0ff, 0xc0ffffffffff0f, 0xffffffffffff7f00), (0x6679a54d3dd491e4, 0x6a7aa177235e5dce, 0x40df02a25b863781, 0xe252e0f35ce6ae9b), (0xb405cbf125702a43, 0xb7f6d99d4c9f304, 0x2e10f6f6b33f21f2, 0x77a4c57f5366a12f), (0x19b33a592486ec38, 0xa301d6c38a24892c, 0x4b03fb485a035e20, 0xd57a5ddb1211c466), (0x8b4796eec745a15, 0xc478b2812f13729d, 0xb8e2af1973ace8bf, 0xa0d687f2e0c8813c)],
                                                                [(0xf800, 0xffffffffff0f, 0xffffffff03000000, 0xffffe0ffffffffff), (0x0, 0x100000000000000, 0xffffffffffff7ff8, 0xffff7f000000c0ff),  (0x1c00000000, 0x80ff0f0000, 0xffffff0700000000, 0xfffcffffffffffe1), (0x24fc0caaf8a054dc, 0x94c1be22f60eae41, 0xd818ffb12a18d6ba, 0xd49bbc0c909d519), (0xd8ebd84a5e1f3419, 0x9f7e24c58b165571, 0xe18c6b43814d0fbd, 0x61591ef437426f9b), (0xb4b273f9c2194579, 0x9c8effce07cd8598, 0x537daf6a96309876, 0x78e1d29566dd3da9), (0xfb97c598e07b010f, 0xafc86dfe43c67109, 0xf9d991216489be44, 0x6d69b885d1e47411)],
                                                                [(0xc0ff, 0xf8ffffff3f, 0xfcffffffff7f00, 0xe0000000403c0000), (0xffffffffffff1f03, 0xffffff0300e0ffff, 0xe0ffffffff03fc, 0xff0f000000000000),  (0x8fffffffffffffff, 0xfeffffffff, 0x3fc0f000000007f, 0xff07000000ffffff), (0xe2d6b12334e922ed, 0xbe9a9af507db99e7, 0x806614c7a7541ddb, 0x287b47bb4a005cdf), (0xd73b67ac0304856f, 0x6228a2a5c92970d2, 0x517edcc1d0137a9f, 0x4bf35aff894b9177), (0x32b67453df46b3ac, 0x6484386bcb4e5bfc, 0xfb95736f3553016a, 0x80e8cbb8150bc246), (0xd96f3baab6e2236e, 0x605f20bdc9328ee, 0xa7d398a8f7ca42f8, 0xd5aef063474ebe15)],
                                                                [(0xffff070000000000, 0xfeffffffffffffff, 0xff00000000c0ff03, 0xffffffffffdfffff), (0xff7f00ffffffffff, 0xff070000fcffffff, 0x40000c0ffff, 0xffffffffff0f0000),  (0xffffffff7f000000, 0xc0ffff3f0080ffff, 0x1ffeffffffffff01, 0xe0ffffff), (0x6de58d6ed78a8ebb, 0x600d7b97414dd05, 0xc06432b91dc6b4c8, 0x1777cbd57fae102f), (0x9f16ccfe12add97a, 0x6e61f50df9e0fe4d, 0x7ef6a306a8be179, 0x5dff2d83b9dcf699), (0xa83fc3419cacb084, 0xd8d59d566650704f, 0x3f55704bce0e9f95, 0x7870b41d9820e403), (0xe40103119bd81347, 0x8e81f9be8401d183, 0x6f79752c296aab99, 0x5ee8359db55cea59)],
                                                                [(0xf0, 0x0, 0xff03000000000000, 0xffffffffffffffff), (0xffff00f0ffffffff, 0xf0000ffffffffff, 0xfc010000e0ff, 0x3e00000000),  (0x0, 0xff0f0000000000, 0xff010000, 0x370000000000000), (0x5d49908602a51ea2, 0x70cd8891a82e241e, 0xdda3deed9431854d, 0xb436a15b56eed310), (0xaae360516c43cf5e, 0xf1a0e5778acf84a5, 0xd9180aaad3928882, 0x39430d4dd9f15656), (0xc4c1affecb2acddc, 0xae3a99c858b5c69c, 0xd1e087209f9c6dad, 0x7cd92b15ab18ad59), (0x5b434137d7964a50, 0xe43ef8bf9735cc9e, 0xe8a564903896553f, 0x21fb256bd98dc0c9)],
                                                                [(0xfcffffffffffffff, 0xffffffff0f000000, 0xffffffffffffffff, 0xfcff1f000000fc), (0xffffffff3f000000, 0xe0ffffffffffffff, 0x0, 0xfe0f0000000000),  (0x1f00000000000000, 0xf8ff, 0xffffffffffff0100, 0xc0ffffffff3f00fe), (0x33c5e7d6b8ca078d, 0x62e9ab8309eefc74, 0x8ee09035eb3c287b, 0xf0b16a872d2a71da), (0xfb9b42b2e574fee8, 0x61d92eeb54ec82aa, 0x81ddb260d05662c4, 0x76b7850328701c82), (0xb5d246b198dd4379, 0xf5086b6e5f5bac51, 0x205b3cc385d517a2, 0xa52bb49954d32135), (0x36cc40b9f7fe7f2f, 0xb415a9f3b83c1497, 0xbd70ed0fd726977f, 0xa053093d530f553d)],
                                                                [(0xffffffffff1f0000, 0x3ffef1ffffffffff, 0xfeffffffffffff, 0x0), (0xffffffffffffff07, 0x3f000000ffffffff, 0xffffffffffffffff, 0xf0f8ffffffff),  (0xf8ff0100f00f80, 0xf8ff03f00300, 0xfeffff000000, 0xf8ff0700), (0xdc44e0a91e03ac08, 0xfa4599610efd369b, 0xbf89ca43b12cbc84, 0x23963ce9c5823a60), (0x91502cd668816aec, 0x7b4edaf168544994, 0xcd4ac14e9fca8ed8, 0x47c86b4f059bebf6), (0xd2177fca480ee993, 0x22b022f8fbd46f69, 0x577b74c841e0c139, 0xeaed344f4f301a49), (0xea0f2c6955223389, 0xad1f368be94e1d46, 0x3ad60e024f733763, 0x79b3b98fa7f0da32)],
                                                                [(0xffffffffff1f0000, 0xf8ff, 0xffffff0300000000, 0xffff01e0ffff), (0xffffffffffffffff, 0xffffffffffffffff, 0xffffffffffffffff, 0x3f0000feffffffff),  (0xffffff0f00000000, 0xff010e00000000ff, 0xffffffffffffffff, 0x80ff), (0x79a2687125738a1c, 0x41bcf8a9b037f7a4, 0x7979341b27f8cb98, 0x7d0e14caaac32a5b), (0xccff61ae1f22287e, 0xa0f39469422bea52, 0x58483c067663dcdd, 0x6646509f0cb32fe6), (0x66167dc9af03f14, 0x23bd5c17f37431a3, 0xccb591bbb271fa64, 0xcc345b5c920459b4), (0x8d159a770d3bdcaa, 0x8744b0b4483528bf, 0xf8de191822db6654, 0x2d7cc09d1d4e58d2)],
                                                                [(0xf8ffffffff7f00, 0xffffffffffff3f00, 0x7f000000f8ff, 0xfcff0100003c0000), (0xffffff1f00000000, 0xc0ff, 0xff000000, 0x38000000),  (0x801f000000001f, 0xffffff0100100000, 0xfeffffff, 0xfeffffffff7f0000), (0x68d4988430a53e3, 0x421e9639dade9108, 0xed9e68d937db6e10, 0x11de0638bd0298e4), (0xb1184582677fb9b0, 0xde6c98d9679c3497, 0xbd82336edebd700c, 0x4cfdef1866a46389), (0x2bd1e6519dbaac8a, 0xe464986b49be1ae5, 0xcb129452008f4779, 0x179508748236e8b7), (0x728d302eee76b21c, 0x8046b9d5d351ddbb, 0x351b2ffd9166de52, 0x908d48df62caf3be)],
                                                                [(0xffff0100000000e0, 0xfff8ffff, 0xc00300000000, 0xffffffffff7f0000), (0xc0ffffff7f0000, 0xfe07000000, 0xffffffffff070000, 0xffffff3f00e0ff),  (0x7000000e0010000, 0xffffffffffffffff, 0xc0ffffff, 0xfcffffffff1f0000), (0x8ad3ab61fd2e87fc, 0xfcd9710a5c629b01, 0x59ddceb42779126b, 0xd940b17f05a74d31), (0xe8ad8b30be618ff0, 0xe9da696d6b4fc40d, 0x2003b1d4a6c64126, 0x7e570ff8746dd07e), (0x96fdf452d405489, 0x78878db05c8fad49, 0xa531492ea3a66a63, 0xda9bf08e004e9253), (0x398acc6120ae5ac1, 0x79faf0c748725db5, 0x988df9751a4ec32a, 0x6c28df81aa5403ed)],
                                                                [(0x300f0ffff030000, 0x700c0ffffffffff, 0xffff030000000000, 0xe01f0000e0ffffff), (0xc0ffff, 0xffffff3f00000000, 0x3000000f0ffffff, 0xffff1ff0ffffff),  (0x700, 0xfcff01, 0xff3fffffff7f0000, 0xffffffffffffffff), (0xfae93368410edb83, 0x9c8d1e2907571fe3, 0x581aa7362ecef55e, 0x85b8d4e21808ae37), (0xecf7e734832aa78f, 0xa6e80ada92e81d6a, 0xd67a4f84d55a9fe9, 0x33dc6d8da0c20180), (0x938b8385db2e3df8, 0x7e2a720d178faf0a, 0xcb57d037022f484, 0x7a2d4495d6e08712), (0x67270e4b584d46ec, 0x18f7978682c26c68, 0x4604e4ff6f665d43, 0x11628e1a881c46fc)],
                                                                [(0x0, 0xfefffff8ff011c, 0xff3f00fcffffff7f, 0xffffffffffcfffff), (0x7fffff0300f0ffff, 0xffffffffffffffff, 0xff7ff8ffffffffff, 0xffffffffffffffff),  (0xff3f00c0fffffffd, 0xffff0f000000f0ff, 0xf80000c0ffff, 0x0), (0xd62340d6ded236e2, 0x3dfc9d953f04c51f, 0xf939a24439c365aa, 0x43f3eadc2d5b8ec4), (0xd2a1f78af1f131d7, 0xb0fb698ec8f193a6, 0xf59c6f7ddecf8887, 0x20badb9056ed7d84), (0x30ddf739f96f5b85, 0xc821967787e8d603, 0x9a86416e3444ff48, 0xc83cabbfc670008f), (0xa178ea03a3fd472f, 0xbe4710d483df8ecb, 0x624167a745a35584, 0x1b64710be1e57de5)],
                                                                [(0xffffffffffffffff, 0xff0fe0ffffffffff, 0xf8ffffffff, 0xffffff3fffffff0f), (0xff03000020000000, 0xe0ffff, 0x3f00000000f8ffff, 0xfeffff),  (0xc001, 0xf00300dc0f, 0x0, 0xff0100c0ffff3f00), (0x374d2b977ad9666f, 0x892dd1adf1106046, 0xe4963b5d882b41bc, 0x60909ac7878a6dea), (0x89bcfc0f1b3872fb, 0x73772a063fca8c1d, 0xa8e4784b408e6b50, 0x4ff7f3c348951f88), (0x2665e59a0df14d7c, 0xdb9ce231c80d332e, 0x37bc00d582812061, 0x12efe38f3efbe461), (0x56b1b16ff085be2b, 0x5baf1d2dcf3ebbb8, 0x97675db62a0a71e, 0x20a3efcd8d67db1c)],
                                                                [(0x10000c0ffffff0f, 0xffff0000ffffffff, 0xf0ff7ffcff, 0x100000000000000), (0x0, 0xff7f00f8ffffff00, 0xf8ff, 0xf07f),  (0x80ffffffffff, 0xfeffff3f, 0xc00f0000000000, 0xfeffff0300000000), (0x1bfdfc1855865409, 0x43298c227993237e, 0x60cffdc40b07c70, 0x7c943bdc70c5e26a), (0x680943e85976af5c, 0x97f620c3e33d082d, 0x404b037a65180fce, 0x741e914db6fe726a), (0xe934f13dd3093e91, 0xd050846c1473516b, 0x6b38ac3e4612e618, 0xcbb5c6a36033647a), (0x237020463bc2b6b7, 0xd2ae47e306d5fe75, 0xcc3f319f16fc9375, 0xbb2183b01e238670)],
                                                                [(0x1e0ffffffffffff, 0xf8ffffffff, 0xf8ffffffffffff00, 0x3c0ff7f00000000), (0xff1f0000c0ff0f00, 0xfc0f000100feff, 0x7f0000e0f7fffc3f, 0xffffffffffffffff),  (0xffff01f8ffffffff, 0xffff7f0000feffff, 0xffffffffffffffff, 0xf8ff0300000000c4), (0x42b7265f5d43f9a9, 0xe73fc34e2c91b29, 0x35a00c2b113e2d16, 0xffb8e107b740736), (0x3c2897ae612e5966, 0xd87249a927ef211, 0x557e4dd4fdfcb3e2, 0x72f2ae236f8bd60f), (0x2baa05eb7c59618b, 0x8916bd27af0b19f5, 0x62b39c0bb3bef560, 0xc93841668cf90459), (0xfc85e34cb8592db3, 0x5d47f03479f42c15, 0x2e25b549c5cacff8, 0xf701620edbc39c60)],
                                                                [(0xffffffffffff0100, 0x7f00f0ffffffffff, 0xff0f0000000000e0, 0xffff1f00fe0f00ff), (0xffffffffff3ffcff, 0xffffffffffffffff, 0xfcffffffffffff, 0xff0f00000000c0ff),  (0xff01000000f0ffff, 0xffffff00ffffffff, 0xffffffff3f00f8ff, 0xffffffffff0300), (0xbb9fa034f0f2c321, 0x52b7a32e488cc17, 0x3ab70964c9826b39, 0x7ecc0f0f070e0620), (0x271e51bd009ba37c, 0xf572ff271dcb73ca, 0x82352ba4d2130b3c, 0xde7bef8ae42d78b), (0x93ceae82ed0ded7b, 0xeb24b65065f2f2d6, 0xfd64f6a8a1c0e50a, 0xad0fdde4f0dfbb4e), (0x40052d8f9d46bb05, 0x9605dec3beb27e03, 0xa1c5f8807be27700, 0x759672a552f65f16)],
                                                                [(0xe0ffff03e0ffff, 0xe0ff1ff8ffffff3f, 0xe0000000000, 0xe0ffffffff1f), (0xffffffffc0ff0700, 0x60000f8ffffffff, 0xffffffff0f000000, 0xfeffff0000000000),  (0xfe1f000000000000, 0x800000000000000, 0xffff1fffff7f0000, 0xffffffffff7f80ff), (0x5d2bc01835f88fdc, 0x3d9b2add62e31389, 0xb66493b41a73c670, 0xb10f1a3bd5ccb73b), (0x4808bc7b07c8a021, 0x7a5a2095ea0d589d, 0x8ba66252fdb2d422, 0x54782f5ab9542809), (0x630599dbf3c77d78, 0x7cbf212c2a81116, 0x58df68bed1402b02, 0x34c961bcebd8b559), (0x7689ffeaf2d100e, 0x6caad28fc5ce80e0, 0x6a34e77903bba528, 0x64d5e5e31ea67efe)],
                                                                [(0xffffff1f0f0000, 0xfffffeffffffff3f, 0xff00c0ffffffffff, 0x7000000000000e0), (0xf0ffffffffffff7f, 0xe0fffff1ffff7f00, 0x700c01f000000, 0xc0ff0700e00f00),  (0xff7f0000000080ff, 0xfcffff070000e0ff, 0xffff070000000000, 0xfc3ff8ffff), (0x30e03a4d33b3e7a9, 0x48584307424b6913, 0xff12305e4576eaf6, 0x529892dfd3ac264), (0xdd5dee2f47da9e68, 0x3d0b991acb05357b, 0xea6bb7d9beb761c6, 0x124e59338d2c7f3), (0x665a2fd29b6dabbe, 0x6c67daec6ac1dd2e, 0x98d6e0f86d997a92, 0x81d301a073edfa29), (0x1f700c4c95ece716, 0x2f839e32bef0e629, 0xd1592661ba0c148d, 0xe86cea3c4e0d7812)],
                                                                [(0xffffff7f00feffff, 0xffffffffff9fffff, 0xffffffffffffffff, 0xf0ffffffffffffff), (0x3c00000000780000, 0xffffffff0ff83f, 0xff3f000000000000, 0xfcff),  (0xe0ffff1f0000, 0xffffff3f00000000, 0xffff1f00fcffffff, 0xffffff030000fcff), (0xdd45a5a7d776a011, 0x49df5c731650f5c7, 0xc350fc3f866f81cf, 0xf65373006debe132), (0xdb55aec5ed52db01, 0x6d5e1fadc9bc0bed, 0xedcda987b56c058d, 0x2b7e2cce10d50c16), (0xf099f81ac99b81ed, 0xf473de51b9754efb, 0xe1a1f6894a5e4b6d, 0xa7f5def7ba86d2f3), (0xaf6c8d9550cadc6c, 0x9d41a0cdd6ee6d68, 0xc3a6e79e6e25a5c, 0xda29207e5563d8ce)]]
        
        for item in msg_priv_nonce_sigr_sigs_pubx_puby {
            var overflow = false
            
            let msgScalar = Secp256k1Scalar(bits64x4: item[0], overflowed: &overflow)
            XCTAssertFalse(overflow)
            let msg = Secp256k1Message(s: msgScalar)
            
            let privKeyScalar = Secp256k1Scalar(bits64x4: item[1], overflowed: &overflow)
            XCTAssertFalse(overflow)
            let privKey = Secp256k1PrivateKey(s: privKeyScalar)!
            
            let nonce = Secp256k1Scalar(bits64x4: item[2], overflowed: &overflow)
            XCTAssertFalse(overflow)
            
            let sigR = Secp256k1Scalar(bits64x4: item[3], overflowed: &overflow)
            XCTAssertFalse(overflow)
            let sigS = Secp256k1Scalar(bits64x4: item[4], overflowed: &overflow)
            XCTAssertFalse(overflow)
            
            let pubKeyX = Secp256k1Field(bits64x4: item[5], overflowed: &overflow)
            XCTAssertFalse(overflow)
            let pubKeyY = Secp256k1Field(bits64x4: item[6], overflowed: &overflow)
            XCTAssertFalse(overflow)
            let pubKeyG = Secp256k1Group(x: pubKeyX, y: pubKeyY)!
            let pubKey = Secp256k1PublicKey(ge: pubKeyG)!
            XCTAssertEqual(privKey.pubKey, pubKey)
            
            let signature = Secp256k1Ecdsa(message: msg, nonce: nonce, privateKey: privKey)
            XCTAssertTrue(signature!.isNormalized())
            XCTAssertNotNil(signature)
            XCTAssertEqual(signature!.sigR, sigR)
            XCTAssertEqual(signature!.sigS, sigS)
            
            let verified = signature!.verify(message: msg, publicKey: pubKey)
            XCTAssertTrue(verified)
            
            let signatureNotNormalized = Secp256k1Ecdsa(r: sigR, s: Secp256k1Scalar.neg(sigS))
            XCTAssertFalse(signatureNotNormalized!.isNormalized())
            let verifiedNotNormalized = signatureNotNormalized!.verify(message: msg, publicKey: pubKey)
            XCTAssertTrue(verifiedNotNormalized)
        }
    }
}

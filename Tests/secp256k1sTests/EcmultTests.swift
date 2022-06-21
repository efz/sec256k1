import XCTest
@testable import secp256k1s

class EcmultTests: XCTestCase {
    
    func testPositiveConstsRandomPoint() {
        let ecmult = Secp256k1Ecmult()
        var p = GroupTests.randGroup()
        p.normalizeJ()
        var nP = p
        nP.reflect()
        
        for i in 0..<36 {
            let x = Secpt256k1Scalar(int: i)
            var pi = ecmult.gen(point: p, pn: x)
            
            for j in 0..<i {
                if j == i - 1 {
                    pi.normalizeJ()
                    XCTAssertEqual(pi, p)
                }
                pi.addJ(nP)
            }
            XCTAssertTrue(pi.isInfinity)
        }
    }
    
    func testNegativeConstsWithRandomPoint() {
        let ecmult = Secp256k1Ecmult()
        var p = GroupTests.randGroup()
        p.normalizeJ()
        var nP = p
        nP.reflect()
        
        for i in 1..<37 {
            let x = Secpt256k1Scalar.neg(Secpt256k1Scalar(int: i))
            var pi = ecmult.gen(point: p, pn: x)
            
            for j in 0..<i {
                if j == i - 1 {
                    pi.normalizeJ()
                    XCTAssertEqual(pi, nP)
                }
                pi.addJ(p)
            }
            XCTAssertTrue(pi.isInfinity)
        }
    }
    
    func testPositiveConstsWithG() {
        let ecmult = Secp256k1Ecmult()
        var ng = Secp256k1Ecmult.g
        ng.reflect()
        
        for i in 0..<36 {
            let x = Secpt256k1Scalar(int: i)
            var gi = ecmult.gen(gn: x)
            
            for j in 0..<i {
                if j == i - 1 {
                    gi.normalizeJ()
                    XCTAssertEqual(gi, Secp256k1Ecmult.g)
                }
                gi.addJ(ng)
            }
            XCTAssertTrue(gi.isInfinity)
        }
    }
    
    func testNegativeConstsWithG() {
        let ecmult = Secp256k1Ecmult()
        var ng = Secp256k1Ecmult.g
        ng.reflect()
        
        for i in 1..<37 {
            let x = Secpt256k1Scalar.neg(Secpt256k1Scalar(int: i))
            var gi = ecmult.gen(gn: x)
            
            for j in 0..<i {
                if j == i - 1 {
                    gi.normalizeJ()
                    XCTAssertEqual(gi, ng)
                }
                gi.addJ(Secp256k1Ecmult.g)
            }
            XCTAssertTrue(gi.isInfinity)
        }
    }
    
    func testRandomPoint() {
        /* random starting point A (on the curve)0 */
        let a = Secp256k1Group(
            x: Secpt256k1Field(words64:[0x6d986544_57ff52b8, 0xcf1b8126_5b802a5b, 0xa97f9263_b1e88044, 0x93351325_91bc450a].reversed()),
            y: Secpt256k1Field(words64:[0x535c59f7_325e5d2b, 0xc391fbe8_3c12787c,0x337e4a98_e82a9011, 0x0123ba37_dd769c7d].reversed()))!
        
        let xn = Secpt256k1Scalar(words64: [0x649d4f77_c4242df7, 0x7f2079c9_14530327,
                                            0xa31b876a_d2d8ce2a, 0x2236d5c6_d7b2029b].reversed())
        
        let exp_b = Secp256k1Group(
            x: Secpt256k1Field(words64:[0x23773684_4d209dc7, 0x098a786f_20d06fcd,
                                        0x070a38bf_c11ac651, 0x03004319_1e2a8786].reversed()),
            y: Secpt256k1Field(words64:[0xed8c3b8e_c06dd57b, 0xd06ea66e_45492b0f,
                                        0xb84e4e1b_fb77e21f, 0x96baae2a_63dec956].reversed()))
        
        let ecmult = Secp256k1Ecmult()
        var b = ecmult.gen(point: a, pn: xn)
        b.normalizeJ()
        XCTAssertEqual(b, exp_b)
    }
    
    func testEmultChain() {
        let ecmult = Secp256k1Ecmult()
        /* random starting point A (on the curve) */
        let a = Secp256k1Group(
            x: Secpt256k1Field(words64:[0x8b30bbe9_ae2a9906, 0x96b22f67_0709dff3,
                                        0x727fd8bc_04d3362c, 0x6c7bf458_e2846004,].reversed()),
            y: Secpt256k1Field(words64:[0xa357ae91_5c4a6528, 0x1309edf2_0504740f,
                                        0x0eb33439_90216b4f, 0x81063cb6_5f2f7e0f].reversed()))!
        
        /* two random initial factors xn and gn */
        var xn = Secpt256k1Scalar(words64: [0x84cc5452_f7fde1ed, 0xb4d38a8c_e9b1b84c,
                                            0xcef31f14_6e569be9, 0x705d357a_42985407].reversed())
        
        var gn = Secpt256k1Scalar(words64: [0xa1e58d22_553dcd42, 0xb2398062_5d4c57a9,
                                            0x6e9323d4_2b3152e5, 0xca2c3990_edc7c9de].reversed())
        
        let xf = Secpt256k1Scalar(int: 0x1337)
        let gf = Secpt256k1Scalar(int: 0x7113)
        
        /* accumulators with the resulting coefficients to A and G */
        var ae = Secpt256k1Scalar.one
        var ge = Secpt256k1Scalar.zero
        
        /* the point being computed */
        var x = a
        for _ in 0..<200 {
            /* in each iteration, compute X = xn*X + gn*G; */
            x = ecmult.gen(point: x, pn: xn, gn: gn)
            /* also compute ae and ge: the actual accumulated factors for A and G */
            /* if X was (ae*A+ge*G), xn*X + gn*G results in (xn*ae*A + (xn*ge+gn)*G) */
            ae = ae * xn
            ge = ge * xn
            ge = ge + gn
            /* modify xn and gn */
            xn = xn * xf
            gn = gn * gf
        }
        
        /* redo the computation, but directly with the resulting ae and ge coefficients: */
        var x2 = ecmult.gen(point: a, pn: ae, gn: ge)
        x2.normalizeJ()
        x.normalizeJ()
        XCTAssertEqual(x2, x)
    }
    
    func testCommutativity() {
        let ecmult = Secp256k1Ecmult()
        let a = ScalarTests.randScalar()
        let b = ScalarTests.randScalar()
        
        var res1 = ecmult.gen(point: Secp256k1Ecmult.g, pn: a)
        var res2 = ecmult.gen(point: Secp256k1Ecmult.g, pn: b)
        
        res1 = ecmult.gen(point: res1, pn: b)
        res2 = ecmult.gen(point: res2, pn: a)
        res1.normalizeJ()
        res2.normalizeJ()
        XCTAssertEqual(res1, res2)
        
        var res3 = ecmult.gen(gn: a)
        var res4 = ecmult.gen(gn: b)
        res3 = ecmult.gen(point: res3, pn: b)
        res4 = ecmult.gen(point: res4, pn: a)
        res3.normalizeJ()
        res4.normalizeJ()
        XCTAssertEqual(res3, res4)
        
        XCTAssertEqual(res1, res3)
    }
    
    func testChainMult() {
        let ecmult = Secp256k1Ecmult()
        let scalar = Secpt256k1Scalar(words64: [0x4968d524_2abf9b7a, 0x466abbcf_34b11b6d,
                                                0xcd83d307_827bed62, 0x05fad0ce_18fae63b].reversed())
        let expectedPoint = Secp256k1Group(
            x: Secpt256k1Field(words64:[0x5494c15d_32099706, 0xc2395f94_348745fd,
                                        0x757ce30e_4e8c90fb, 0xa2bad184_f883c69f].reversed()),
            y: Secpt256k1Field(words64:[0x5d195d20_e191bf7f, 0x1be3e55f_56a80196,
                                        0x6071ad01_f1462f66, 0xc997fa94_db858435].reversed()))!
        
        var point = Secp256k1Ecmult.g
        for _ in 0..<100 {
            point = ecmult.gen(point: point, pn: scalar)
        }
        point.normalizeJ()
        XCTAssertEqual(point, expectedPoint)
    }
    
    func testPointTimesOrder() {
        let ecmult = Secp256k1Ecmult()
        var x = Secpt256k1Field(int: 2)
        let xr = Secpt256k1Field(words64:[0x7603CB59_B0EF6C63, 0xFE608479_2A0C378C,
                                          0xDB3233A8_0F8A9A09, 0xA877DEAD_31B38C45].reversed())
        var count = 0
        for _ in 0..<500 {
            if let point = Secp256k1Group(x: x, odd: true) {
                count += 1
                let y = ScalarTests.randScalar()
                let ny = Secpt256k1Scalar.neg(y)
                /* calc res1 = y * point + y * G; */
                var res1 = ecmult.gen(point: point, pn: y, gn: y)
                /* calc res2 = (order - y) * point + (order - y) * G; */
                let res2 = ecmult.gen(point: point, pn: ny, gn: ny)
                
                res1.addJ(res2)
                XCTAssertTrue(res1.isInfinity)
                
                let res3 = ecmult.gen(point: point, pn: Secpt256k1Scalar.zero, gn: Secpt256k1Scalar.zero)
                XCTAssertTrue(res3.isInfinity)
                var res4 = ecmult.gen(point: point, pn: Secpt256k1Scalar.one, gn: Secpt256k1Scalar.zero)
                res4.normalizeJ()
                XCTAssertEqual(res4, point)
                var res5 = ecmult.gen(point: point, pn: Secpt256k1Scalar.zero, gn: Secpt256k1Scalar.one)
                res5.normalizeJ()
                XCTAssertEqual(res5, Secp256k1Ecmult.g)
            }
            x = Secpt256k1Field.sqr(x)
        }
        XCTAssertEqual(x, xr)
        XCTAssertTrue(count > 100)
    }
}

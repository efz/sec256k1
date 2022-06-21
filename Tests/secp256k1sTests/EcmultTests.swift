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
    
    func testPointTimesOrder() {
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
}

import XCTest
@testable import secp256k1s

class FieldTests: XCTestCase {
    let count = 64;
    
    func randField() -> Secpt256k1Field {
        var f: Secpt256k1Field
        var overflowed = false
        repeat {
            let words: [UInt32] = (0..<8).map { _ in
                UInt32(UInt64.random(in: UInt64(UInt32.min)..<UInt64(UInt32.max)+1))
            }
            f = Secpt256k1Field(words32: words, overflowed: &overflowed)
        } while overflowed || f.isZero()
        return f
    }
    
    func verifyInverse(_ x: Secpt256k1Field, _ y: Secpt256k1Field) {
        let r = x * y
        XCTAssertTrue(r.isOne())
    }
    
    func testInverse() throws {
        for _ in 0..<count {
            let x = randField()
            var x_inv = x
            x_inv.inverse()
            verifyInverse(x, x_inv)
            var x_inv_inv = x_inv
            x_inv_inv.inverse()
            XCTAssertEqual(x, x_inv_inv)
        }
    }
    
    func testOverflow() throws {
        var overflow = false
        let x1 = Secpt256k1Field(words64: [Secpt256k1Field.p.0 - 1, Secpt256k1Field.p.1, Secpt256k1Field.p.2, Secpt256k1Field.p.3], overflowed: &overflow)
        XCTAssertFalse(overflow)
        let x2 = Secpt256k1Field(words64: [0xFFFF_FFFF_FFFF_FFFF, Secpt256k1Field.p.1, Secpt256k1Field.p.2, Secpt256k1Field.p.3 - 1], overflowed: &overflow)
        XCTAssertFalse(overflow)
        let x3 = Secpt256k1Field(words64: [0xFFFF_FFFF_FFFF_FFFF, Secpt256k1Field.p.1, Secpt256k1Field.p.2 - 1, Secpt256k1Field.p.3], overflowed: &overflow)
        XCTAssertFalse(overflow)
        let r1 = x1 * x1
        let r2 = x2 * x2
        let r3 = x3 * x3
        XCTAssertTrue(!r1.isZero())
        XCTAssertTrue(!r2.isZero())
        XCTAssertTrue(!r3.isZero())
        let r4 = x1 * x2
        let r5 = x3 * x1
        let r6 = x2 * x3
        XCTAssertTrue(!r4.isZero())
        XCTAssertTrue(!r5.isZero())
        XCTAssertTrue(!r6.isZero())
    }
    
    func testMisc() throws {
        let x = randField()
        let x2 = x + x
        let x3 = x2 + x
        let x3z = x * Secpt256k1Field(int32: 3)
        XCTAssertEqual(x3, x3z)
        
        let x5 = x * Secpt256k1Field(int32: 5)
        let x3zz = x5 - x - x
        XCTAssertEqual(x3, x3zz)
        XCTAssertEqual(x3, x5 - x2)
    }
    
    func verifySqrt(_ xx: Secpt256k1Field, _ optAwn: Secpt256k1Field?) {
        var x = xx
        let hasSqrt = x.sqrt()
        XCTAssertTrue(!hasSqrt || optAwn != nil)
        
        if let awn = optAwn {
            var neg_awn = awn
            neg_awn.negate()
            XCTAssertTrue(x == awn || x == neg_awn)
            let x_neg = Secpt256k1Field.zero - x
            XCTAssertEqual(xx, x_neg * x_neg)
        }
    }
    
    func testSqrt() throws {
        /* Check sqrt(0) is 0 */
        var z = Secpt256k1Field.zero
        let hasSqrt = z.sqrt()
        XCTAssertTrue(hasSqrt)
        XCTAssertTrue(z.isZero())
        
        /* Check sqrt of small squares (and their negatives) */
        for i in 1..<101 {
            let x = Secpt256k1Field(int32: UInt32(i))
            let xx = x * x
            verifySqrt(xx, x)
            
            var neg_xx = xx
            neg_xx.negate()
            verifySqrt(neg_xx, nil)
        }
        
        /* Consistency checks for large random values */
        for _ in 0..<10 {
            var ns = randField()
            while ns.sqrt() {
                ns = randField()
            }
            for _ in 0..<count {
                let x = randField()
                let xx = x * x
                verifySqrt(xx, x)
                
                var neg_xx = xx
                neg_xx.negate()
                verifySqrt(neg_xx, nil)
                
                let xx_ns = xx * ns
                verifySqrt(xx_ns, nil)
            }
        }
    }
}

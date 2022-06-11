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
    
    func verifySqrt(_ x: Secpt256k1Field, _ awn: Secpt256k1Field) {
        var neg_awn = awn
        neg_awn.negate()
        
        XCTAssertTrue(x == awn || x == neg_awn)
    }
    
    func testSqrt() throws {
        /* Check sqrt(0) is 0 */
        var z = Secpt256k1Field.zero
        z.sqrt()
        XCTAssertTrue(z.isZero())
        
        /* Check sqrt of small squares (and their negatives) */
        for i in 0..<100 {
            let x = Secpt256k1Field(int32: UInt32(i))
            let xx = x * x
            var xx_sqrt = xx
            xx_sqrt.sqrt()
            verifySqrt(xx_sqrt, x)
            
            var neg_x = x
            neg_x.negate()
            let neg_xx = neg_x * neg_x
            var neg_xx_sqrt = neg_xx
            neg_xx_sqrt.sqrt()
            verifySqrt(neg_xx_sqrt, neg_x)
        }
        
        /* Consistency checks for large random values */
        for _ in 0..<100 {
            let x = randField()
            let xx = x * x
            var xx_sqrt = xx
            xx_sqrt.sqrt()
            verifySqrt(xx_sqrt, x)
            
            var neg_x = x
            neg_x.negate()
            let neg_xx = neg_x * neg_x
            var neg_xx_sqrt = neg_xx
            neg_xx_sqrt.sqrt()
            verifySqrt(neg_xx_sqrt, neg_x)
        }
    }
}

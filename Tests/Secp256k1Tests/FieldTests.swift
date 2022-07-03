import XCTest
@testable import Secp256k1

class FieldTests: XCTestCase {
    let count = 64;
    
    static func randField() -> Secp256k1Field {
        var f: Secp256k1Field
        var overflowed = false
        repeat {
            let words: [UInt32] = (0..<8).map { _ in
                UInt32(UInt64.random(in: UInt64(UInt32.min)..<UInt64(UInt32.max)+1))
            }
            f = Secp256k1Field(words32: words, overflowed: &overflowed)
        } while overflowed || f.isZero()
        return f
    }
    
    func verifyInverse(_ x: Secp256k1Field, _ y: Secp256k1Field) {
        let r = x * y
        XCTAssertTrue(r.isOne())
    }
    
    func testInverse() throws {
        for _ in 0..<count {
            let x = Self.randField()
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
        let x1 = Secp256k1Field(words64: [Secp256k1Field.p.0 - 1, Secp256k1Field.p.1, Secp256k1Field.p.2, Secp256k1Field.p.3], overflowed: &overflow)
        XCTAssertFalse(overflow)
        let x2 = Secp256k1Field(words64: [0xFFFF_FFFF_FFFF_FFFF, Secp256k1Field.p.1, Secp256k1Field.p.2, Secp256k1Field.p.3 - 1], overflowed: &overflow)
        XCTAssertFalse(overflow)
        let x3 = Secp256k1Field(words64: [0xFFFF_FFFF_FFFF_FFFF, Secp256k1Field.p.1, Secp256k1Field.p.2 - 1, Secp256k1Field.p.3], overflowed: &overflow)
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
        let x = Self.randField()
        let x2 = x + x
        let x3 = x2 + x
        let x3z = x * Secp256k1Field(int32: 3)
        XCTAssertEqual(x3, x3z)
        
        let x5 = x * Secp256k1Field(int32: 5)
        let x3zz = x5 - x - x
        XCTAssertEqual(x3, x3zz)
        XCTAssertEqual(x3, x5 - x2)
    }
    
    func verifySqrt(_ xx: Secp256k1Field, _ optAwn: Secp256k1Field?) {
        var x = xx
        let hasSqrt = x.sqrt()
        XCTAssertTrue(!hasSqrt || optAwn != nil)
        
        if let awn = optAwn {
            var neg_awn = awn
            neg_awn.negate()
            XCTAssertTrue(x == awn || x == neg_awn)
            let x_neg = Secp256k1Field.zero - x
            XCTAssertEqual(xx, x_neg * x_neg)
        }
    }
    
    func testSqrt() throws {
        /* Check sqrt(0) is 0 */
        var z = Secp256k1Field.zero
        let hasSqrt = z.sqrt()
        XCTAssertTrue(hasSqrt)
        XCTAssertTrue(z.isZero())
        
        /* Check sqrt of small squares (and their negatives) */
        for i in 1..<101 {
            let x = Secp256k1Field(int32: UInt32(i))
            let xx = x * x
            verifySqrt(xx, x)
            
            var neg_xx = xx
            neg_xx.negate()
            verifySqrt(neg_xx, nil)
        }
        
        /* Consistency checks for large random values */
        for _ in 0..<10 {
            var ns = Self.randField()
            while ns.sqrt() {
                ns = Self.randField()
            }
            for _ in 0..<count {
                let x = Self.randField()
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
    
    func testMulInt() {
        var pHalfBits: Bits64x4 = (0, 0, 0, 0)
        pHalfBits.0 = Secp256k1Field.p.1  & 1 << 63 | Secp256k1Field.p.0 >> 1
        pHalfBits.1 = Secp256k1Field.p.2  & 1 << 63 | Secp256k1Field.p.1 >> 1
        pHalfBits.2 = Secp256k1Field.p.3 & 1 << 63 | Secp256k1Field.p.2 >> 1
        pHalfBits.3 = Secp256k1Field.p.3 >> 1
        
        var overflowed = false
        let pHalf = Secp256k1Field(bits64x4: pHalfBits, overflowed: &overflowed)
        XCTAssertFalse(overflowed)
        let pHalfPlus5 = pHalf + Secp256k1Field(int32: 5)
        
        let mulby2 = Secp256k1Field.mulInt(pHalfPlus5, 2)
        XCTAssertFalse(mulby2.checkOverflow());
    }
}

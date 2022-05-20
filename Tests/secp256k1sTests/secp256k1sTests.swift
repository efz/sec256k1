import XCTest
@testable import secp256k1s

final class secp256k1sTests: XCTestCase {
    let init_x : [UInt8] = [
        0x02, 0x03, 0x05, 0x07, 0x0b, 0x0d, 0x11, 0x13,
        0x17, 0x1d, 0x1f, 0x25, 0x29, 0x2b, 0x2f, 0x35,
        0x3b, 0x3d, 0x43, 0x47, 0x49, 0x4f, 0x53, 0x59,
        0x61, 0x65, 0x67, 0x6b, 0x6d, 0x71, 0x7f, 0x83
    ];
    
    let init_y : [UInt8] = [
        0x82, 0x83, 0x85, 0x87, 0x8b, 0x8d, 0x81, 0x83,
        0x97, 0xad, 0xaf, 0xb5, 0xb9, 0xbb, 0xbf, 0xc5,
        0xdb, 0xdd, 0xe3, 0xe7, 0xe9, 0xef, 0xf3, 0xf9,
        0x11, 0x15, 0x17, 0x1b, 0x1d, 0xb1, 0xbf, 0xd3
    ];
    
    func randScalar() -> Secpt256k1Scalar {
        var s: Secpt256k1Scalar
        repeat {
            let words: [UInt32] = (0..<8).map { _ in
                UInt32.random(in: UInt32.min..<UInt32.max)
            }
            s = Secpt256k1Scalar(words: words)
        } while s.overflow > 0 || s.isZero()
        return s
    }
    
    func randTestScalar() {
        let s = randScalar()
        let s1 = randScalar()
        let s2 = randScalar()
        let c = s2.getBytes();
        
        /* Test that fetching groups of 4 bits from a scalar and recursing n(i)=16*n(i-1)+p(i) reconstructs it. */
        {
            var n = Secpt256k1Scalar()
            var i = 0
            while i < 256 {
                let t = Secpt256k1Scalar(int: s.getBits(offset: 256 - 4 - i, count: 4))
                for _ in 0..<4 {
                    n.add(n)
                }
                n.add(t)
                i += 4
            }
            XCTAssertEqual(n, s)
        }();
        
        /* Test that fetching groups of randomly-sized bits from a scalar and recursing n(i)=b*n(i-1)+p(i) reconstructs it. */
        {
            var n = Secpt256k1Scalar(int: 0);
            var i = 0;
            while i < 256 {
                var now = Int.random(in: 0..<15) + 1;
                if now + i > 256 {
                    now = 256 - i;
                }
                let t = Secpt256k1Scalar(int: s.getBits(offset: 256 - now - i, count: now));
                for _ in 0..<now {
                    n.add(n)
                }
                n.add(t)
                i += now;
            }
            XCTAssertEqual(n, s)
        }();
        
        {
            let b = Secpt256k1Scalar(int: 1)
            XCTAssertTrue(b.isOne())
        }();
        
        /* Test commutativity of add. */
        {
            let r1 = s1 + s2
            let r2 = s2 + s1
            XCTAssertEqual(r1, r2);
        }();
        
        /* Test commutativity of add. */
        {
            var r3 = s1
            var r4 = s2
            r3.add(s2)
            r4.add(s1)
            XCTAssertEqual(r3, r4)
        }();
        
        /* Test additive identity. */
        {
            let v0 = Secpt256k1Scalar()
            let r3 = s + v0
            XCTAssertEqual(r3, s)
        }();
        
        /* Test p. */
        {
            let p = Secpt256k1Scalar.prime
            let v0 = Secpt256k1Scalar(int: 0)
            XCTAssertEqual(p, v0)
            
            let pPlus1 : [UInt32] = [0xD0364142, 0xBFD25E8C, 0xAF48A03B, 0xBAAEDCE6, 0xFFFFFFFE, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF]
            let p1 = Secpt256k1Scalar(words: pPlus1)
            XCTAssertTrue(p1.isOne())
        }();
    }
    
    func testRandScalar() {
        for _ in 0..<128 {
            randTestScalar()
        }
    }
}

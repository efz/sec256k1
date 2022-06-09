//
//  FieldTests.swift
//  
//
//  Created by irantha on 6/9/22.
//

import XCTest
@testable import secp256k1s

class FieldTests: XCTestCase {
    let count = 64;
    
    func randField() -> Secpt256k1Field {
        var f: Secpt256k1Field
        repeat {
            let words: [UInt32] = (0..<8).map { _ in
                UInt32(UInt64.random(in: UInt64(UInt32.min)..<UInt64(UInt32.max)+1))
            }
            f = Secpt256k1Field(words: words)
        } while f.checkOverflow() || f.isZero()
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
        let x1 = Secpt256k1Field(words64: [Secpt256k1Field.p.0 - 1, Secpt256k1Field.p.1, Secpt256k1Field.p.2, Secpt256k1Field.p.3])
        let x2 = Secpt256k1Field(words64: [0xFFFF_FFFF_FFFF_FFFF, Secpt256k1Field.p.1, Secpt256k1Field.p.2, Secpt256k1Field.p.3 - 1])
        let x3 = Secpt256k1Field(words64: [0xFFFF_FFFF_FFFF_FFFF, Secpt256k1Field.p.1, Secpt256k1Field.p.2 - 1, Secpt256k1Field.p.3])
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
}

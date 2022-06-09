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


}

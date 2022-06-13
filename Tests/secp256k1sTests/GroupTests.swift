import XCTest
@testable import secp256k1s

class GroupTests: XCTestCase {
    
    let testVectors: [[[UInt64]]]  = [[[0xffffff0100000000, 0xffffff3f0000fef9, 0xff07f0fffffffff7, 0x3f000080ffffffff], [0xe505bc4e6f563efc, 0xcad83ad6178bf08, 0xe867570e9ba37abc, 0xe8c0a985350e8586]], [[0xffffff0100000000, 0xffffff3f0000fef9, 0xff07f0fffffffff7, 0x3f000080ffffffff], [0xe505bc4e6f563efc, 0xcad83ad6178bf08, 0xe867570e9ba37abc, 0xe8c0a985350e8586]], [[0x2f049037b357f5b8, 0x7d5d4c4f5d03a950, 0xc2b978bce7ea3b32, 0xe2326bb23f5815be], [0xbdb952e6e87d32af, 0x8d8af37884fa8ed2, 0x18a47d9952700492, 0x7a95b8b33c03fe32]]]
    
    
    func testGroupAdd() {
        var isOverflow = false
        let a_x = Secpt256k1Field(words64: testVectors[0][0], overflowed: &isOverflow)
        XCTAssertFalse(isOverflow)
        let a_y = Secpt256k1Field(words64: testVectors[0][1], overflowed: &isOverflow)
        XCTAssertFalse(isOverflow)
        let b_x = Secpt256k1Field(words64: testVectors[1][0], overflowed: &isOverflow)
        XCTAssertFalse(isOverflow)
        let b_y = Secpt256k1Field(words64: testVectors[1][1], overflowed: &isOverflow)
        XCTAssertFalse(isOverflow)
        let c_x = Secpt256k1Field(words64: testVectors[2][0], overflowed: &isOverflow)
        XCTAssertFalse(isOverflow)
        let c_y = Secpt256k1Field(words64: testVectors[2][1], overflowed: &isOverflow)
        XCTAssertFalse(isOverflow)
        
        let a = Secp256k1Group(x: a_x, y: a_y)!
        XCTAssertTrue(a.isValid())
        let b = Secp256k1Group(x: b_x, y: b_y)!
        XCTAssertTrue(b.isValid())
        let c = Secp256k1Group(x: c_x, y: c_y)!
        XCTAssertTrue(c.isValid())
        
        var d = a
        if a == b {
            d.double()
        } else {
            d.add(b)
        }
        
        XCTAssertEqual(d, c)
    }
}



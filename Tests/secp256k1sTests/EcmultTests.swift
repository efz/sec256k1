import XCTest
@testable import secp256k1s

class EcmultTests: XCTestCase {
    
    func testPositiveConsts() {
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
    
    func testNegativeConsts() {
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
}

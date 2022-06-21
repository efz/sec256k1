//
//  File.swift
//  
//
//  Created by irantha on 5/19/22.
//

import Foundation
import secp256k1s

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

let count = 200000
let inverse_count = 2000

// Scalar

func randScalar() -> Secpt256k1Scalar {
    var s: Secpt256k1Scalar
    var overflowed = false
    repeat {
        let words: [UInt32] = (0..<8).map { _ in
            UInt32.random(in: UInt32.min..<UInt32.max)
        }
        s = Secpt256k1Scalar(words32: words, overflowed: &overflowed)
    } while overflowed || s.isZero()
    return s
}

func bench_random_scalar_add() {
    var scalar_x = randScalar()
    let scalar_y = randScalar()
    
    for _ in 0..<count {
        scalar_x.add(scalar_y)
    }
}


func bench_scalar_add() {
    var overflow = false
    var scalar_x = Secpt256k1Scalar(bytes: init_x, overflowed: &overflow)
    let scalar_y = Secpt256k1Scalar(bytes: init_y, overflowed: &overflow)
    
    for _ in 0..<count {
        scalar_x.add(scalar_y)
    }
}

func bench_scalar_negate() {
    var overflow = false
    var scalar_x = Secpt256k1Scalar(bytes: init_x, overflowed: &overflow)
    for _ in 0..<count {
        scalar_x.negate()
    }
}

func bench_scalar_mul() {
    var overflow = false
    var scalar_x = Secpt256k1Scalar(bytes: init_x, overflowed: &overflow)
    let scalar_y = Secpt256k1Scalar(bytes: init_y, overflowed: &overflow)
    
    for _ in 0..<count {
        scalar_x.mul(scalar_y)
    }
}

func bench_random_scalar_mul() {
    var scalar_x = randScalar()
    let scalar_y = randScalar()
    
    for _ in 0..<count {
        scalar_x.mul(scalar_y)
    }
}

func bench_scalar_sqr() {
    var overflow = false
    var scalar_x = Secpt256k1Scalar(bytes: init_x, overflowed: &overflow)
    
    for _ in 0..<count {
        scalar_x.sqr()
    }
}

func bench_random_scalar_sqr() {
    var scalar_x = randScalar()
    
    for _ in 0..<count {
        scalar_x.sqr()
    }
}

func bench_scalar_inverse() {
    var overflow = false
    var scalar_x = Secpt256k1Scalar(bytes: init_x, overflowed: &overflow)
    let scalar_y = Secpt256k1Scalar(bytes: init_y, overflowed: &overflow)
    
    for _ in 0..<inverse_count {
        scalar_x.inverse()
        scalar_x.add(scalar_y)
    }
}

func bench_random_scalar_inverse() {
    var scalar_x = randScalar()
    let scalar_y = randScalar()
    
    for _ in 0..<inverse_count {
        scalar_x.inverse()
        scalar_x.add(scalar_y)
    }
}

// Field

func randField() -> Secpt256k1Field {
    var f: Secpt256k1Field
    var overflowed = false
    repeat {
        let words: [UInt32] = (0..<8).map { _ in
            UInt32.random(in: UInt32.min..<UInt32.max)
        }
        f = Secpt256k1Field(words32: words, overflowed: &overflowed)
    } while overflowed || f.isZero()
    return f
}

func bench_field_mul() {
    var overflow = false
    var field_x = Secpt256k1Field(bytes: init_x, overflowed: &overflow)
    let field_y = Secpt256k1Field(bytes: init_y, overflowed: &overflow)
    
    for _ in 0..<count {
        field_x.mul(field_y)
    }
}

func bench_random_field_mul() {
    var field_x = randField()
    let field_y = randField()
    
    for _ in 0..<count {
        field_x.mul(field_y)
    }
}

func bench_field_inverse() {
    var overflow = false
    var field_x = Secpt256k1Field(bytes: init_x, overflowed: &overflow)
    let field_y = Secpt256k1Field(bytes: init_y, overflowed: &overflow)
    
    for _ in 0..<inverse_count {
        field_x.inverse()
        field_x.add(field_y)
    }
}

func bench_random_field_inverse() {
    var field_x = randField()
    let field_y = randField()
    
    for _ in 0..<inverse_count {
        field_x.inverse()
        field_x.add(field_y)
    }
}

func bench_field_sqr() {
    var overflow = false
    var field_x = Secpt256k1Field(bytes: init_x, overflowed: &overflow)
    
    for _ in 0..<count {
        field_x.sqr()
    }
}

func bench_random_field_sqr() {
    var field_x = randField()
    
    for _ in 0..<count {
        field_x.sqr()
    }
}

func bench_field_sqrt() {
    var overflow = false
    var field_x = Secpt256k1Field(bytes: init_x, overflowed: &overflow)
    let field_y = Secpt256k1Field(bytes: init_y, overflowed: &overflow)
    
    for _ in 0..<inverse_count {
        let _ = field_x.sqrt()
        field_x.add(field_y)
    }
}

func bench_random_field_sqrt() {
    var field_x = randField()
    let field_y = randField()
    
    for _ in 0..<inverse_count {
        let _ = field_x.sqrt()
        field_x.add(field_y)
    }
}

func runBenchmark(name: String, benchFunc: () -> Void, count: Int) {
    print("** \(name) benchmark starting...")
    var minElapsed: Double = Double(Int.max)
    var maxElapsed: Double = 0
    var totalElapsed: Double = 0
    
    let iters = 10
    for _ in 0..<iters {
        let begin = Date().timeIntervalSince1970
        benchFunc()
        let end = Date().timeIntervalSince1970
        let elapsed : Double = (end - begin)
        minElapsed = Swift.min(elapsed * Double(1000000) / Double(count), minElapsed)
        maxElapsed = Swift.max(elapsed * Double(1000000) / Double(count), maxElapsed)
        totalElapsed += elapsed
    }
    let averageElaped = totalElapsed * Double(1000000) / Double(count * iters)
    print("Elapsed time min: \(minElapsed)us, ave: \(averageElaped)us, max: \(maxElapsed)us ")
}

//Group
func randGroup() -> Secp256k1Group {
    var g: Secp256k1Group? = nil
    while g == nil || !g!.isValidJ() || g!.isInfinity {
        let x = randField()
        let z = randField()
        let z2 = Secpt256k1Field.sqr(z)
        var x3 = Secpt256k1Field.sqr(x)
        x3.mul(x)
        var z6 = Secpt256k1Field.sqr(z2)
        z6.mul(z2)
        var y2 = Secp256k1Group.curvB
        y2.mul(z6)
        y2.add(x3)
        let y = Secpt256k1Field.sqrt(y2)
        g = y == nil ? nil : Secp256k1Group(x: x, y: y!, z: z)!
    }
    return g!
}

func bench_group_double() {
    var overflow = false
    let field_x = Secpt256k1Field(bytes: init_x, overflowed: &overflow)
    var group_x = Secp256k1Group(x: field_x, odd: false)!
    
    for _ in 0..<count {
        group_x.doubleJ()
    }
}

func bench_random_group_double() {
    var group_x = randGroup()
    
    for _ in 0..<count {
        group_x.doubleJ()
    }
}

func bench_group_add() {
    var overflow = false
    let field_x = Secpt256k1Field(bytes: init_x, overflowed: &overflow)
    var group_x = Secp256k1Group(x: field_x, odd: false)!
    
    let field_y = Secpt256k1Field(bytes: init_y, overflowed: &overflow)
    let group_y = Secp256k1Group(x: field_y, odd: true)!
    
    for _ in 0..<count {
        group_x.addJ(group_y)
    }
}

func bench_random_group_add() {
    var group_x = randGroup()
    let group_y = randGroup()
    
    for _ in 0..<count {
        group_x.addJ(group_y)
    }
}

func bench_group_add_affine2j() {
    var overflow = false
    let field_x = Secpt256k1Field(bytes: init_x, overflowed: &overflow)
    var group_x = Secp256k1Group(x: field_x, odd: false)!
    
    let field_y = Secpt256k1Field(bytes: init_y, overflowed: &overflow)
    let group_y = Secp256k1Group(x: field_y, odd: true)!
    
    for _ in 0..<count {
        group_x.addAffine2J(group_y)
    }
}

// Hash

func bench_sha256_hash() {
    var hash = init_x
    for _ in 0..<20000 {
        var hasher = Secp256k1sSha256()
        hasher.write(bytes: hash)
        hash = hasher.finalize()
    }
}

// warmup
for _ in 0..<5 {
    bench_scalar_add()
}

runBenchmark(name: "Scalar Add", benchFunc: bench_scalar_add, count: count)
runBenchmark(name: "Random Scalar Add", benchFunc: bench_random_scalar_add, count: count)
runBenchmark(name: "Scalar Negate", benchFunc: bench_scalar_negate, count: count)
runBenchmark(name: "Scalar Mul", benchFunc: bench_scalar_mul, count: count)
runBenchmark(name: "Random Scalar Mul", benchFunc: bench_random_scalar_mul, count: count)
runBenchmark(name: "Scalar Sqr", benchFunc: bench_scalar_sqr, count: count)
runBenchmark(name: "Random Scalar Sqr", benchFunc: bench_random_scalar_sqr, count: count)
runBenchmark(name: "Scalar Inverse", benchFunc: bench_scalar_inverse, count: inverse_count)
runBenchmark(name: "Random Scalar Inverse", benchFunc: bench_random_scalar_inverse, count: inverse_count)

runBenchmark(name: "Feild Mul", benchFunc: bench_field_mul, count: count)
runBenchmark(name: "Random Feild Mul", benchFunc: bench_random_field_mul, count: count)
runBenchmark(name: "Feild Sqr", benchFunc: bench_field_sqr, count: count)
runBenchmark(name: "Random Feild Sqr", benchFunc: bench_random_field_sqr, count: count)
runBenchmark(name: "Feild Inverse", benchFunc: bench_field_inverse, count: inverse_count)
runBenchmark(name: "Random Feild Inverse", benchFunc: bench_random_field_inverse, count: inverse_count)
runBenchmark(name: "Feild Sqrt", benchFunc: bench_field_sqrt, count: inverse_count)
runBenchmark(name: "Random Feild Sqrt", benchFunc: bench_field_sqrt, count: inverse_count)

runBenchmark(name: "Group Double", benchFunc: bench_group_double, count: count)
runBenchmark(name: "Random Group Double", benchFunc: bench_random_group_double, count: count)
runBenchmark(name: "Group Add", benchFunc: bench_group_add, count: count)
runBenchmark(name: "Random Group Add", benchFunc: bench_random_group_add, count: count)
runBenchmark(name: "Group Add Affine 2 J", benchFunc: bench_group_add_affine2j, count: count)

runBenchmark(name: "Bench Sha256 Hash", benchFunc: bench_sha256_hash, count: 20000)

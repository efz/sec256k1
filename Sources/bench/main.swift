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

func bench_scalar_add() {
    var scalar_x = Secpt256k1Scalar(bytes: init_x)
    let scalar_y = Secpt256k1Scalar(bytes: init_y)
    
    for _ in 0..<count {
        scalar_x.add(scalar_y)
    }
}

func runBenchmark(benchFunc: () -> Void, coun: Int) {
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

runBenchmark(benchFunc: bench_scalar_add, coun: count)

import Foundation
import Secp256k1

/*
 let count = 200000
 let inverse_count = 2000
 
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
 
 // Scalar
 
 func randScalar() -> Secp256k1Scalar {
 var s: Secp256k1Scalar
 var overflowed = false
 repeat {
 let words: [UInt32] = (0..<8).map { _ in
 UInt32.random(in: UInt32.min..<UInt32.max)
 }
 s = Secp256k1Scalar(words32: words, overflowed: &overflowed)
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
 var scalar_x = Secp256k1Scalar(bytes: init_x, overflowed: &overflow)
 let scalar_y = Secp256k1Scalar(bytes: init_y, overflowed: &overflow)
 
 for _ in 0..<count {
 scalar_x.add(scalar_y)
 }
 }
 
 func bench_scalar_negate() {
 var overflow = false
 var scalar_x = Secp256k1Scalar(bytes: init_x, overflowed: &overflow)
 for _ in 0..<count {
 scalar_x.negate()
 }
 }
 
 func bench_scalar_mul() {
 var overflow = false
 var scalar_x = Secp256k1Scalar(bytes: init_x, overflowed: &overflow)
 let scalar_y = Secp256k1Scalar(bytes: init_y, overflowed: &overflow)
 
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
 var scalar_x = Secp256k1Scalar(bytes: init_x, overflowed: &overflow)
 
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
 var scalar_x = Secp256k1Scalar(bytes: init_x, overflowed: &overflow)
 let scalar_y = Secp256k1Scalar(bytes: init_y, overflowed: &overflow)
 
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
 
 func randField() -> Secp256k1Field {
 var f: Secp256k1Field
 var overflowed = false
 repeat {
 let words: [UInt32] = (0..<8).map { _ in
 UInt32.random(in: UInt32.min..<UInt32.max)
 }
 f = Secp256k1Field(words32: words, overflowed: &overflowed)
 } while overflowed || f.isZero()
 return f
 }
 
 func bench_field_mul() {
 var overflow = false
 var field_x = Secp256k1Field(bytes: init_x, overflowed: &overflow)
 let field_y = Secp256k1Field(bytes: init_y, overflowed: &overflow)
 
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
 var field_x = Secp256k1Field(bytes: init_x, overflowed: &overflow)
 let field_y = Secp256k1Field(bytes: init_y, overflowed: &overflow)
 
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
 var field_x = Secp256k1Field(bytes: init_x, overflowed: &overflow)
 
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
 var field_x = Secp256k1Field(bytes: init_x, overflowed: &overflow)
 let field_y = Secp256k1Field(bytes: init_y, overflowed: &overflow)
 
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
 
 //Group
 func randGroup() -> Secp256k1Group {
 var g: Secp256k1Group? = nil
 while g == nil || !g!.isValidJ() || g!.isInfinity {
 let x = randField()
 let z = randField()
 let z2 = Secp256k1Field.sqr(z)
 var x3 = Secp256k1Field.sqr(x)
 x3.mul(x)
 var z6 = Secp256k1Field.sqr(z2)
 z6.mul(z2)
 var y2 = Secp256k1Group.curvB
 y2.mul(z6)
 y2.add(x3)
 let y = Secp256k1Field.sqrt(y2)
 g = y == nil ? nil : Secp256k1Group(x: x, y: y!, z: z)!
 }
 return g!
 }
 
 func bench_group_double() {
 var overflow = false
 let field_x = Secp256k1Field(bytes: init_x, overflowed: &overflow)
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
 let field_x = Secp256k1Field(bytes: init_x, overflowed: &overflow)
 var group_x = Secp256k1Group(x: field_x, odd: false)!
 
 let field_y = Secp256k1Field(bytes: init_y, overflowed: &overflow)
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
 let field_x = Secp256k1Field(bytes: init_x, overflowed: &overflow)
 var group_x = Secp256k1Group(x: field_x, odd: false)!
 
 let field_y = Secp256k1Field(bytes: init_y, overflowed: &overflow)
 let group_y = Secp256k1Group(x: field_y, odd: true)!
 
 for _ in 0..<count {
 group_x.addAffine2J(group_y)
 }
 }
 
 // Hash
 
 func bench_sha256_hash() {
 var hash = [UInt8](repeating: 0, count: 32)
 hash[0..<32] = init_x[0..<32]
 var hasher = Secp256k1Sha256()
 for _ in 0..<20000 {
 hasher.write(bytes: hash)
 hasher.finalize(hash: &hash)
 }
 }
 
 func bench_hmacSha256_hash() {
 var hash = [UInt8](repeating: 0, count: 32)
 hash[0..<32] = init_x[0..<32]
 var hasher = Secp256k1HmacSha256()
 for _ in 0..<20000 {
 hasher.resetKey(key: hash)
 hasher.write(bytes: hash)
 hasher.finalize(hash: &hash)
 }
 }
 
 func bench_rfc6979HmacSha256_hash() {
 var hash = [UInt8](repeating: 0, count: 64)
 hash[0..<32] = init_x[0..<32]
 hash[32..<64] = init_y[0..<32]
 var rng = Secp256k1Rfc6979HmacSha256(key: hash)
 
 for _ in 0..<20000 {
 rng.generate(rand: &hash[0..<32])
 rng.resetKey(key: hash)
 }
 }
 */

let signVerifyCount = 20000

func bench_sign() {
    var sigBytes = [UInt8](repeating: 0, count: 64)
    var keyBytes = [UInt8](repeating: 0, count: 32)
    var messageBytes = [UInt8](repeating: 0, count: 32)
    for i in 0..<32 {
        messageBytes[i] = UInt8(i + 1)
        keyBytes[i] = UInt8(i + 65)
    }
    
    let nonceGenerator = Secp256k1DefaultNonceGenerator()
    for _ in 0..<signVerifyCount {
        let privKey = Secp256k1PrivateKey(bytes32: keyBytes)!
        let message = Secp256k1Message(bytes32: messageBytes)!
        
        let signature = message.sign(privateKey: privKey, nonceGenerator: nonceGenerator)!
        try! signature.serialize(bytes64: &sigBytes)
        for i in 0..<32 {
            messageBytes[i] = sigBytes[i]
            keyBytes[i] = sigBytes[i + 32]
        }
    }
}

func bench_verify() {
    var pubKeyBytes = [UInt8](repeating: 0, count: 33)
    var sigBytes = [UInt8](repeating: 0, count: 64)
    var keyBytes = [UInt8](repeating: 0, count: 32)
    var messageBytes = [UInt8](repeating: 0, count: 32)
    for i in 0..<32 {
        messageBytes[i] = UInt8(i + 1)
        keyBytes[i] = UInt8(i + 33)
    }
    
    let privKey = Secp256k1PrivateKey(bytes32: keyBytes)!
    let message = Secp256k1Message(bytes32: messageBytes)!
    let nonceGenerator = Secp256k1DefaultNonceGenerator()
    let signature = message.sign(privateKey: privKey, nonceGenerator: nonceGenerator)!
    try! signature.serialize(bytes64: &sigBytes)
    let pubKey = privKey.pubKey!
    try! pubKey.serialize(bytes33or65: &pubKeyBytes, compress: true)
    
    for i in 0..<signVerifyCount {
        sigBytes[sigBytes.count - 1] = sigBytes[sigBytes.count - 1] ^ UInt8(i & 0xFF)
        sigBytes[sigBytes.count - 2] = sigBytes[sigBytes.count - 2] ^ UInt8(i >> 8 & 0xFF)
        sigBytes[sigBytes.count - 3] = sigBytes[sigBytes.count - 3] ^ UInt8(i >> 16 & 0xFF)
        
        let pubKey2 = Secp256k1PublicKey(bytes33or65: pubKeyBytes)!
        let signature2 = Secp256k1Ecdsa(bytes64: sigBytes)
        let isValid = signature2!.verify(message: message, publicKey: pubKey2)
        assert(isValid == (i == 0))
        
        sigBytes[sigBytes.count - 1] = sigBytes[sigBytes.count - 1] ^ UInt8(i & 0xFF)
        sigBytes[sigBytes.count - 2] = sigBytes[sigBytes.count - 2] ^ UInt8(i >> 8 & 0xFF)
        sigBytes[sigBytes.count - 3] = sigBytes[sigBytes.count - 3] ^ UInt8(i >> 16 & 0xFF)
    }
}

// warmup
for _ in 0..<5 {
    bench_sign()
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


/*genSha256TransformBlock()
 func genSha256TransformBlock() {
 let k0: [UInt32] = [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2]
 
 if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
 // create the destination url for the text file to be saved
 let fileURL = documentDirectory.appendingPathComponent("file.txt")
 
 var text = ""
 
 for i in 0..<16 {
 text += "transformStep(\(k0[i]), w.\(i)) \n"
 }
 
 text += "\n\n"
 
 for i in 16..<64 {
 text += "w.\(i & 0xF) = sigma1(w.\((i + 14) & 0xF)) &+ w.\((i + 9) & 0xF) &+ sigma0(w.\((i + 1) & 0xF)) &+ w.\(i & 0xF) \n"
 text += "transformStep(\(k0[i]), w.\(i & 0xF)) \n"
 }
 
 try! text.write(to: fileURL, atomically: false, encoding: .utf8)
 
 print("saving was successful")
 }
 }*/


/*
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
 
 runBenchmark(name: "Sha256 Hash", benchFunc: bench_sha256_hash, count: 20000)
 runBenchmark(name: "HmacSha256 Hash", benchFunc: bench_hmacSha256_hash, count: 20000)
 runBenchmark(name: "Rfc6979 HmacSha256 Hash", benchFunc: bench_rfc6979HmacSha256_hash, count: 20000)
 */
runBenchmark(name: "Sign", benchFunc: bench_sign, count: signVerifyCount)
runBenchmark(name: "Verify", benchFunc: bench_verify, count: signVerifyCount)

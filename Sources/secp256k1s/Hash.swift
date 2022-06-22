public struct Secp256k1sSha256 {
    static let blockSizeBytes = 64
    static let blackSizeWords = 16
    static let sSize = 8
    
    var s: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
    var ws = [UInt32](repeating: 0, count: Secp256k1sSha256.blackSizeWords)
    var bytesCount = 0
    var totalBytesCount = 0
    
    static let k0: [UInt32] = [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
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
    
    public init() {}
    
    @inline(__always)
    func rotr(_ x: UInt32, _ r: Int) -> UInt32 {
        return (x >> r) | (x << (32 - r))
    }
    
    @inline(__always)
    func maj(x: UInt32, y: UInt32, z: UInt32) -> UInt32 {
        return (x & y) ^ (x & z) ^ (y & z)
    }
    
    @inline(__always)
    func ch(x: UInt32, y: UInt32, z: UInt32) -> UInt32 {
        return (x & y) ^ (~x & z)
    }
    
    @inline(__always)
    func sigma0(_ x: UInt32) -> UInt32 {
        return rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3)
    }
    
    @inline(__always)
    func sigma1(_ x: UInt32) -> UInt32 {
        return rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10)
    }
    
    @inline(__always)
    func bigSigma0(_ x: UInt32) -> UInt32 {
        return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22)
    }
    
    @inline(__always)
    func bigSigma1(_ x: UInt32) -> UInt32 {
        return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25)
    }
    
    private mutating func transform() {
        assert(bytesCount == Secp256k1sSha256.blockSizeBytes)
        var abcdefgh:(a: UInt32, b: UInt32, c: UInt32, d: UInt32, e: UInt32, f: UInt32, g: UInt32, h: UInt32) = (0, 0, 0, 0, 0, 0, 0, 0)
        abcdefgh.a = s[0]
        abcdefgh.b = s[1]
        abcdefgh.c = s[2]
        abcdefgh.d = s[3]
        abcdefgh.e = s[4]
        abcdefgh.f = s[5]
        abcdefgh.g = s[6]
        abcdefgh.h = s[7]
        
        for i in 0..<64 {
            let round = i >> 4
            let wi = i & 0xF
            if round > 0 {
                ws[wi] = sigma1(ws[(wi + 14) & 0xF]) &+ ws[(wi + 9) & 0xF] &+ sigma0(ws[(wi + 1) & 0xF]) &+ ws[wi]
            }
            
            let t1 = abcdefgh.h &+ bigSigma1(abcdefgh.e) &+ ch(x: abcdefgh.e, y: abcdefgh.f, z: abcdefgh.g) &+ Secp256k1sSha256.k0[i] &+ ws[wi]
            let t2 = bigSigma0(abcdefgh.a) &+ maj(x: abcdefgh.a, y: abcdefgh.b, z: abcdefgh.c)
            
            abcdefgh.h = abcdefgh.g
            abcdefgh.g = abcdefgh.f
            abcdefgh.f = abcdefgh.e
            abcdefgh.e = abcdefgh.d &+ t1
            abcdefgh.d = abcdefgh.c
            abcdefgh.c = abcdefgh.b
            abcdefgh.b = abcdefgh.a
            abcdefgh.a = t1 &+ t2
        }
        
        s[0] = s[0] &+ abcdefgh.a
        s[1] = s[1] &+ abcdefgh.b
        s[2] = s[2] &+ abcdefgh.c
        s[3] = s[3] &+ abcdefgh.d
        s[4] = s[4] &+ abcdefgh.e
        s[5] = s[5] &+ abcdefgh.f
        s[6] = s[6] &+ abcdefgh.g
        s[7] = s[7] &+ abcdefgh.h
        
        for i in 0..<ws.count {
            ws[i] = 0
        }
        totalBytesCount += Secp256k1sSha256.blockSizeBytes
        bytesCount = 0
    }
    
    public mutating func write(bytes: [UInt8]) {
        for i in 0..<bytes.count {
            write(byte: bytes[i])
        }
    }
    
    mutating func write(byte: UInt8) {
        let widx = bytesCount >> 2
        let bidx = 3 - bytesCount & 0x3 // big endian
        ws[widx] = ws[widx] | UInt32(byte) << (bidx * 8)
        bytesCount += 1
        if (bytesCount == Secp256k1sSha256.blockSizeBytes) {
            transform()
        }
    }
    
    mutating func write(word: UInt32) {
        guard bytesCount & 0x3 == 0 else {
            fatalError("Unaligned word write")
        }
        let widx = bytesCount >> 2
        ws[widx] = word
        bytesCount += 4
        if (bytesCount == Secp256k1sSha256.blockSizeBytes) {
            transform()
        }
    }
    
    public mutating func finalize() -> [UInt8] {
        let writtenSizeBits = (totalBytesCount + bytesCount) * 8
        write(byte: 0x80)
        let fillSize: Int
        if (Secp256k1sSha256.blockSizeBytes - bytesCount < 8) {
            fillSize = Secp256k1sSha256.blockSizeBytes - bytesCount +  Secp256k1sSha256.blockSizeBytes - 8
        } else {
            fillSize = Secp256k1sSha256.blockSizeBytes - bytesCount - 8
        }
        for _ in 0..<fillSize {
            write(byte: 0)
        }
        write(word: 0)
        write(word: UInt32(writtenSizeBits))
        var hash = [UInt8](repeating: 0, count: 32)
        var i = 0
        for word in s {
            hash[i] = UInt8(word >> 24 & 0xFF)
            hash[i + 1] = UInt8(word >> 16 & 0xFF)
            hash[i + 2] = UInt8(word >> 8 & 0xFF)
            hash[i + 3] = UInt8(word & 0xFF)
            i += 4
        }
        return hash
    }
    
}

public struct Secp256k1sSha256 {
    typealias ABCDEFGH = (a: UInt32, b: UInt32, c: UInt32, d: UInt32, e: UInt32, f: UInt32, g: UInt32, h: UInt32)
    
    static let blockSizeBytes = 64
    static let blockSizeWords = 16
    static let sSize = 8
    static let hs: ABCDEFGH = (0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19)
    
    var s = Secp256k1sSha256.hs
    var bytesCount = 0
    var totalBytesCount = 0
    var abcdefgh = Secp256k1sSha256.hs
    
    var w0: UInt32 = 0
    var w1: UInt32 = 0
    var w2: UInt32 = 0
    var w3: UInt32 = 0
    var w4: UInt32 = 0
    var w5: UInt32 = 0
    var w6: UInt32 = 0
    var w7: UInt32 = 0
    var w8: UInt32 = 0
    var w9: UInt32 = 0
    var w10: UInt32 = 0
    var w11: UInt32 = 0
    var w12: UInt32 = 0
    var w13: UInt32 = 0
    var w14: UInt32 = 0
    var w15: UInt32 = 0
    
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
    
    public init() {
    }
    
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
    
    @inline(__always)
    mutating func transformStep(_ k: UInt32, _ wi: UInt32) {
        let t1 = abcdefgh.h &+ bigSigma1(abcdefgh.e) &+ ch(x: abcdefgh.e, y: abcdefgh.f, z: abcdefgh.g) &+ k &+ wi
        let t2 = bigSigma0(abcdefgh.a) &+ maj(x: abcdefgh.a, y: abcdefgh.b, z: abcdefgh.c)
        abcdefgh = (t1 &+ t2, abcdefgh.a, abcdefgh.b, abcdefgh.c, abcdefgh.d &+ t1, abcdefgh.e, abcdefgh.f, abcdefgh.g)
    }
    
    private mutating func transform() {
        assert(bytesCount == Secp256k1sSha256.blockSizeBytes)
        
        transformStep(1116352408, w0)
        transformStep(1899447441, w1)
        transformStep(3049323471, w2)
        transformStep(3921009573, w3)
        transformStep(961987163, w4)
        transformStep(1508970993, w5)
        transformStep(2453635748, w6)
        transformStep(2870763221, w7)
        transformStep(3624381080, w8)
        transformStep(310598401, w9)
        transformStep(607225278, w10)
        transformStep(1426881987, w11)
        transformStep(1925078388, w12)
        transformStep(2162078206, w13)
        transformStep(2614888103, w14)
        transformStep(3248222580, w15)
        
        w0 = sigma1(w14) &+ w9 &+ sigma0(w1) &+ w0
        transformStep(3835390401, w0)
        w1 = sigma1(w15) &+ w10 &+ sigma0(w2) &+ w1
        transformStep(4022224774, w1)
        w2 = sigma1(w0) &+ w11 &+ sigma0(w3) &+ w2
        transformStep(264347078, w2)
        w3 = sigma1(w1) &+ w12 &+ sigma0(w4) &+ w3
        transformStep(604807628, w3)
        w4 = sigma1(w2) &+ w13 &+ sigma0(w5) &+ w4
        transformStep(770255983, w4)
        w5 = sigma1(w3) &+ w14 &+ sigma0(w6) &+ w5
        transformStep(1249150122, w5)
        w6 = sigma1(w4) &+ w15 &+ sigma0(w7) &+ w6
        transformStep(1555081692, w6)
        w7 = sigma1(w5) &+ w0 &+ sigma0(w8) &+ w7
        transformStep(1996064986, w7)
        w8 = sigma1(w6) &+ w1 &+ sigma0(w9) &+ w8
        transformStep(2554220882, w8)
        w9 = sigma1(w7) &+ w2 &+ sigma0(w10) &+ w9
        transformStep(2821834349, w9)
        w10 = sigma1(w8) &+ w3 &+ sigma0(w11) &+ w10
        transformStep(2952996808, w10)
        w11 = sigma1(w9) &+ w4 &+ sigma0(w12) &+ w11
        transformStep(3210313671, w11)
        w12 = sigma1(w10) &+ w5 &+ sigma0(w13) &+ w12
        transformStep(3336571891, w12)
        w13 = sigma1(w11) &+ w6 &+ sigma0(w14) &+ w13
        transformStep(3584528711, w13)
        w14 = sigma1(w12) &+ w7 &+ sigma0(w15) &+ w14
        transformStep(113926993, w14)
        w15 = sigma1(w13) &+ w8 &+ sigma0(w0) &+ w15
        transformStep(338241895, w15)
        w0 = sigma1(w14) &+ w9 &+ sigma0(w1) &+ w0
        transformStep(666307205, w0)
        w1 = sigma1(w15) &+ w10 &+ sigma0(w2) &+ w1
        transformStep(773529912, w1)
        w2 = sigma1(w0) &+ w11 &+ sigma0(w3) &+ w2
        transformStep(1294757372, w2)
        w3 = sigma1(w1) &+ w12 &+ sigma0(w4) &+ w3
        transformStep(1396182291, w3)
        w4 = sigma1(w2) &+ w13 &+ sigma0(w5) &+ w4
        transformStep(1695183700, w4)
        w5 = sigma1(w3) &+ w14 &+ sigma0(w6) &+ w5
        transformStep(1986661051, w5)
        w6 = sigma1(w4) &+ w15 &+ sigma0(w7) &+ w6
        transformStep(2177026350, w6)
        w7 = sigma1(w5) &+ w0 &+ sigma0(w8) &+ w7
        transformStep(2456956037, w7)
        w8 = sigma1(w6) &+ w1 &+ sigma0(w9) &+ w8
        transformStep(2730485921, w8)
        w9 = sigma1(w7) &+ w2 &+ sigma0(w10) &+ w9
        transformStep(2820302411, w9)
        w10 = sigma1(w8) &+ w3 &+ sigma0(w11) &+ w10
        transformStep(3259730800, w10)
        w11 = sigma1(w9) &+ w4 &+ sigma0(w12) &+ w11
        transformStep(3345764771, w11)
        w12 = sigma1(w10) &+ w5 &+ sigma0(w13) &+ w12
        transformStep(3516065817, w12)
        w13 = sigma1(w11) &+ w6 &+ sigma0(w14) &+ w13
        transformStep(3600352804, w13)
        w14 = sigma1(w12) &+ w7 &+ sigma0(w15) &+ w14
        transformStep(4094571909, w14)
        w15 = sigma1(w13) &+ w8 &+ sigma0(w0) &+ w15
        transformStep(275423344, w15)
        w0 = sigma1(w14) &+ w9 &+ sigma0(w1) &+ w0
        transformStep(430227734, w0)
        w1 = sigma1(w15) &+ w10 &+ sigma0(w2) &+ w1
        transformStep(506948616, w1)
        w2 = sigma1(w0) &+ w11 &+ sigma0(w3) &+ w2
        transformStep(659060556, w2)
        w3 = sigma1(w1) &+ w12 &+ sigma0(w4) &+ w3
        transformStep(883997877, w3)
        w4 = sigma1(w2) &+ w13 &+ sigma0(w5) &+ w4
        transformStep(958139571, w4)
        w5 = sigma1(w3) &+ w14 &+ sigma0(w6) &+ w5
        transformStep(1322822218, w5)
        w6 = sigma1(w4) &+ w15 &+ sigma0(w7) &+ w6
        transformStep(1537002063, w6)
        w7 = sigma1(w5) &+ w0 &+ sigma0(w8) &+ w7
        transformStep(1747873779, w7)
        w8 = sigma1(w6) &+ w1 &+ sigma0(w9) &+ w8
        transformStep(1955562222, w8)
        w9 = sigma1(w7) &+ w2 &+ sigma0(w10) &+ w9
        transformStep(2024104815, w9)
        w10 = sigma1(w8) &+ w3 &+ sigma0(w11) &+ w10
        transformStep(2227730452, w10)
        w11 = sigma1(w9) &+ w4 &+ sigma0(w12) &+ w11
        transformStep(2361852424, w11)
        w12 = sigma1(w10) &+ w5 &+ sigma0(w13) &+ w12
        transformStep(2428436474, w12)
        w13 = sigma1(w11) &+ w6 &+ sigma0(w14) &+ w13
        transformStep(2756734187, w13)
        w14 = sigma1(w12) &+ w7 &+ sigma0(w15) &+ w14
        transformStep(3204031479, w14)
        w15 = sigma1(w13) &+ w8 &+ sigma0(w0) &+ w15
        transformStep(3329325298, w15)
        
        s = (s.a &+ abcdefgh.a, s.b &+ abcdefgh.b, s.c &+ abcdefgh.c, s.d &+ abcdefgh.d, s.e &+ abcdefgh.e, s.f &+ abcdefgh.f, s.g &+ abcdefgh.g, s.h &+ abcdefgh.h)
        
        (w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        
        totalBytesCount += Secp256k1sSha256.blockSizeBytes
        bytesCount = 0
        abcdefgh = s
    }
    
    public mutating func write(bytes: ArraySlice<UInt8>) {
        let wordFillBytesCount = Swift.min((4 - bytesCount & 0x3) & 0x3, bytes.count)
        var byteIdx = bytes.startIndex
        for _ in 0..<wordFillBytesCount {
            write(byte: bytes[byteIdx])
            byteIdx += 1
        }
        let fullWordsCount = (bytes.count - wordFillBytesCount) >> 2
        for _ in 0..<fullWordsCount {
            let word = UInt32(bytes[byteIdx]) << 24 | UInt32(bytes[byteIdx + 1]) << 16 | UInt32(bytes[byteIdx + 2]) << 8 | UInt32(bytes[byteIdx + 3])
            write(word: word)
            byteIdx += 4
        }
        let leftoverBytesCount = bytes.count - wordFillBytesCount - fullWordsCount * 4
        for _ in 0..<leftoverBytesCount {
            write(byte: bytes[byteIdx])
            byteIdx += 1
        }
    }
    
    public mutating func write(bytes: [UInt8]) {
        write(bytes: bytes[0..<bytes.count])
    }
    
    @inline(__always)
    mutating func write(byte: UInt8) {
        let widx = bytesCount >> 2
        let bidx = 3 - bytesCount & 0x3 // big endian
        bytesCount += 1
        
        switch widx {
        case 0:
            w0 = w0 | UInt32(byte) << (bidx * 8)
        case 1:
            w1 = w1 | UInt32(byte) << (bidx * 8)
        case 2:
            w2 = w2 | UInt32(byte) << (bidx * 8)
        case 3:
            w3 = w3 | UInt32(byte) << (bidx * 8)
        case 4:
            w4 = w4 | UInt32(byte) << (bidx * 8)
        case 5:
            w5 = w5 | UInt32(byte) << (bidx * 8)
        case 6:
            w6 = w6 | UInt32(byte) << (bidx * 8)
        case 7:
            w7 = w7 | UInt32(byte) << (bidx * 8)
        case 8:
            w8 = w8 | UInt32(byte) << (bidx * 8)
        case 9:
            w9 = w9 | UInt32(byte) << (bidx * 8)
        case 10:
            w10 = w10 | UInt32(byte) << (bidx * 8)
        case 11:
            w11 = w11 | UInt32(byte) << (bidx * 8)
        case 12:
            w12 = w12 | UInt32(byte) << (bidx * 8)
        case 13:
            w13 = w13 | UInt32(byte) << (bidx * 8)
        case 14:
            w14 = w14 | UInt32(byte) << (bidx * 8)
        case 15:
            w15 = w15 | UInt32(byte) << (bidx * 8)
        default:
            fatalError()
        }
        
        if (bytesCount == Secp256k1sSha256.blockSizeBytes) {
            transform()
        }
    }
    
    @inline(__always)
    mutating func write(word: UInt32) {
        assert(bytesCount & 0x3 == 0)
        
        let widx = bytesCount >> 2
        bytesCount += 4
        
        switch widx {
        case 0:
            w0 = word
        case 1:
            w1 = word
        case 2:
            w2 = word
        case 3:
            w3 = word
        case 4:
            w4 = word
        case 5:
            w5 = word
        case 6:
            w6 = word
        case 7:
            w7 = word
        case 8:
            w8 = word
        case 9:
            w9 = word
        case 10:
            w10 = word
        case 11:
            w11 = word
        case 12:
            w12 = word
        case 13:
            w13 = word
        case 14:
            w14 = word
        case 15:
            w15 = word
        default:
            fatalError()
        }
        
        if (bytesCount == Secp256k1sSha256.blockSizeBytes) {
            transform()
        }
    }
    
    @inline(__always)
    func extractBytes(from word: UInt32, to bytes: inout [UInt8], at start: Int) {
        bytes[start] = UInt8(word >> 24 & 0xFF)
        bytes[start + 1] = UInt8(word >> 16 & 0xFF)
        bytes[start + 2] = UInt8(word >> 8 & 0xFF)
        bytes[start + 3] = UInt8(word & 0xFF)
    }
    
    public mutating func finalize() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: 32)
        finalize(hash: &hash)
        return hash
    }
    
    public mutating func finalize(hash: inout [UInt8]) {
        assert(hash.count >= 32)
        
        let writtenSizeBits = (totalBytesCount + bytesCount) * 8
        write(byte: 0x80)
        
        if (Secp256k1sSha256.blockSizeBytes - bytesCount < 8) {
            bytesCount = Secp256k1sSha256.blockSizeBytes
            transform()
        }
        bytesCount = Secp256k1sSha256.blockSizeBytes - 4
        write(word: UInt32(writtenSizeBits))
        
        extractBytes(from: s.a, to: &hash, at: 0 * 4)
        extractBytes(from: s.b, to: &hash, at: 1 * 4)
        extractBytes(from: s.c, to: &hash, at: 2 * 4)
        extractBytes(from: s.d, to: &hash, at: 3 * 4)
        extractBytes(from: s.e, to: &hash, at: 4 * 4)
        extractBytes(from: s.f, to: &hash, at: 5 * 4)
        extractBytes(from: s.g, to: &hash, at: 6 * 4)
        extractBytes(from: s.h, to: &hash, at: 7 * 4)
        
        // reset
        s = Secp256k1sSha256.hs
        abcdefgh = Secp256k1sSha256.hs
        bytesCount = 0
        totalBytesCount = 0
    }
}

public struct Secp256k1sHmacSha256 {
    var innerHasher = Secp256k1sSha256()
    var outterHasher = Secp256k1sSha256()
    var rkey = [UInt8](repeating: 0, count: 64)
    
    static let innerCode: UInt8 = 0x36
    static let outterCode: UInt8 = 0x5c
    
    public init() {
    }
    
    public init(key: [UInt8]) {
        resetKey(key: key)
    }
    
    public mutating func resetKey(key: [UInt8]) {
        if key.count <= 64 {
            rkey[0..<key.count] = key[0..<key.count]
        } else {
            var keyHasher = Secp256k1sSha256()
            keyHasher.write(bytes: key)
            keyHasher.finalize(hash: &rkey)
        }
        
        for i in 0..<rkey.count {
            rkey[i] = rkey[i] ^ Secp256k1sHmacSha256.outterCode
        }
        outterHasher.write(bytes: rkey)
        
        for i in 0..<rkey.count {
            rkey[i] = rkey[i] ^ Secp256k1sHmacSha256.outterCode ^ Secp256k1sHmacSha256.innerCode
        }
        innerHasher.write(bytes: rkey)
    }
    
    public mutating func write(byte: UInt8) {
        innerHasher.write(byte: byte)
    }
    
    public mutating func write(bytes: [UInt8]) {
        innerHasher.write(bytes: bytes)
    }
    
    public mutating func write(bytes: ArraySlice<UInt8>) {
        innerHasher.write(bytes: bytes)
    }
    
    public mutating func finalize(hash: inout [UInt8]) {
        assert(hash.count >= 32)
        
        innerHasher.finalize(hash: &hash)
        outterHasher.write(bytes: hash)
        outterHasher.finalize(hash: &hash)
        
        for i in 0..<rkey.count {
            rkey[i] = 0
        }
    }
    
    public mutating func finalize() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: 32)
        finalize(hash: &hash)
        return hash
    }
}

public struct Secp256k1sRfc6979HmacSha256 {
    let tempV = [UInt8](repeating: 1, count: 32)
    let tempK = [UInt8](repeating: 0, count: 32)
    
    var v = [UInt8]()
    var k = [UInt8]()
    var retry = false
    var hmac = Secp256k1sHmacSha256()
    
    public init(key: [UInt8]) {
        resetKey(key: key)
    }
    
    public mutating func resetKey(key: [UInt8]) {
        v = tempV
        k = tempK
        
        hmac.resetKey(key: k)
        hmac.write(bytes: v)
        hmac.write(byte: 0)
        hmac.write(bytes: key)
        hmac.finalize(hash: &k)
        hmac.resetKey(key: k)
        hmac.write(bytes: v)
        hmac.finalize(hash: &v)
        
        hmac.resetKey(key: k)
        hmac.write(bytes: v)
        hmac.write(byte: 1)
        hmac.write(bytes: key)
        hmac.finalize(hash: &k)
        hmac.resetKey(key: k)
        hmac.write(bytes: v)
        hmac.finalize(hash: &v)
        retry = false
    }
    
    public mutating func generate(rand: inout [UInt8]) {
        generate(rand: &rand[0..<rand.count])
    }
    
    public mutating func generate(rand: inout ArraySlice<UInt8>) {
        var outlen = rand.count
        if retry {
            hmac.resetKey(key: k)
            hmac.write(bytes: v)
            hmac.write(byte: 0)
            hmac.finalize(hash: &k)
            hmac.resetKey(key: k)
            hmac.write(bytes: v)
            hmac.finalize(hash: &v)
        }
        
        while outlen > 0 {
            hmac.resetKey(key: k)
            hmac.write(bytes: v)
            hmac.finalize(hash: &v)
            let cpyCount = Swift.min(outlen, v.count)
            let cpyStart = rand.startIndex + rand.count - outlen
            rand[cpyStart..<cpyStart+cpyCount] = v[0..<cpyCount]
            outlen -= cpyCount
        }
        retry = true
    }
}

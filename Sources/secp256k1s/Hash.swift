typealias ABCDEFGH = (a: UInt32, b: UInt32, c: UInt32, d: UInt32, e: UInt32, f: UInt32, g: UInt32, h: UInt32)

public struct Secp256k1sSha256 {
    static let blockSizeBytes = 64
    static let blockSizeWords = 16
    static let sSize = 8
    static let hs: ABCDEFGH = (0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19)
    
    var s = Secp256k1sSha256.hs
    var bytesCount = 0
    var totalBytesCount = 0
    var abcdefgh = Secp256k1sSha256.hs
    
    var w: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    
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
        
        transformStep(1116352408, w.0)
        transformStep(1899447441, w.1)
        transformStep(3049323471, w.2)
        transformStep(3921009573, w.3)
        transformStep(961987163, w.4)
        transformStep(1508970993, w.5)
        transformStep(2453635748, w.6)
        transformStep(2870763221, w.7)
        transformStep(3624381080, w.8)
        transformStep(310598401, w.9)
        transformStep(607225278, w.10)
        transformStep(1426881987, w.11)
        transformStep(1925078388, w.12)
        transformStep(2162078206, w.13)
        transformStep(2614888103, w.14)
        transformStep(3248222580, w.15)
        
        w.0 = sigma1(w.14) &+ w.9 &+ sigma0(w.1) &+ w.0
        transformStep(3835390401, w.0)
        w.1 = sigma1(w.15) &+ w.10 &+ sigma0(w.2) &+ w.1
        transformStep(4022224774, w.1)
        w.2 = sigma1(w.0) &+ w.11 &+ sigma0(w.3) &+ w.2
        transformStep(264347078, w.2)
        w.3 = sigma1(w.1) &+ w.12 &+ sigma0(w.4) &+ w.3
        transformStep(604807628, w.3)
        w.4 = sigma1(w.2) &+ w.13 &+ sigma0(w.5) &+ w.4
        transformStep(770255983, w.4)
        w.5 = sigma1(w.3) &+ w.14 &+ sigma0(w.6) &+ w.5
        transformStep(1249150122, w.5)
        w.6 = sigma1(w.4) &+ w.15 &+ sigma0(w.7) &+ w.6
        transformStep(1555081692, w.6)
        w.7 = sigma1(w.5) &+ w.0 &+ sigma0(w.8) &+ w.7
        transformStep(1996064986, w.7)
        w.8 = sigma1(w.6) &+ w.1 &+ sigma0(w.9) &+ w.8
        transformStep(2554220882, w.8)
        w.9 = sigma1(w.7) &+ w.2 &+ sigma0(w.10) &+ w.9
        transformStep(2821834349, w.9)
        w.10 = sigma1(w.8) &+ w.3 &+ sigma0(w.11) &+ w.10
        transformStep(2952996808, w.10)
        w.11 = sigma1(w.9) &+ w.4 &+ sigma0(w.12) &+ w.11
        transformStep(3210313671, w.11)
        w.12 = sigma1(w.10) &+ w.5 &+ sigma0(w.13) &+ w.12
        transformStep(3336571891, w.12)
        w.13 = sigma1(w.11) &+ w.6 &+ sigma0(w.14) &+ w.13
        transformStep(3584528711, w.13)
        w.14 = sigma1(w.12) &+ w.7 &+ sigma0(w.15) &+ w.14
        transformStep(113926993, w.14)
        w.15 = sigma1(w.13) &+ w.8 &+ sigma0(w.0) &+ w.15
        transformStep(338241895, w.15)
        w.0 = sigma1(w.14) &+ w.9 &+ sigma0(w.1) &+ w.0
        transformStep(666307205, w.0)
        w.1 = sigma1(w.15) &+ w.10 &+ sigma0(w.2) &+ w.1
        transformStep(773529912, w.1)
        w.2 = sigma1(w.0) &+ w.11 &+ sigma0(w.3) &+ w.2
        transformStep(1294757372, w.2)
        w.3 = sigma1(w.1) &+ w.12 &+ sigma0(w.4) &+ w.3
        transformStep(1396182291, w.3)
        w.4 = sigma1(w.2) &+ w.13 &+ sigma0(w.5) &+ w.4
        transformStep(1695183700, w.4)
        w.5 = sigma1(w.3) &+ w.14 &+ sigma0(w.6) &+ w.5
        transformStep(1986661051, w.5)
        w.6 = sigma1(w.4) &+ w.15 &+ sigma0(w.7) &+ w.6
        transformStep(2177026350, w.6)
        w.7 = sigma1(w.5) &+ w.0 &+ sigma0(w.8) &+ w.7
        transformStep(2456956037, w.7)
        w.8 = sigma1(w.6) &+ w.1 &+ sigma0(w.9) &+ w.8
        transformStep(2730485921, w.8)
        w.9 = sigma1(w.7) &+ w.2 &+ sigma0(w.10) &+ w.9
        transformStep(2820302411, w.9)
        w.10 = sigma1(w.8) &+ w.3 &+ sigma0(w.11) &+ w.10
        transformStep(3259730800, w.10)
        w.11 = sigma1(w.9) &+ w.4 &+ sigma0(w.12) &+ w.11
        transformStep(3345764771, w.11)
        w.12 = sigma1(w.10) &+ w.5 &+ sigma0(w.13) &+ w.12
        transformStep(3516065817, w.12)
        w.13 = sigma1(w.11) &+ w.6 &+ sigma0(w.14) &+ w.13
        transformStep(3600352804, w.13)
        w.14 = sigma1(w.12) &+ w.7 &+ sigma0(w.15) &+ w.14
        transformStep(4094571909, w.14)
        w.15 = sigma1(w.13) &+ w.8 &+ sigma0(w.0) &+ w.15
        transformStep(275423344, w.15)
        w.0 = sigma1(w.14) &+ w.9 &+ sigma0(w.1) &+ w.0
        transformStep(430227734, w.0)
        w.1 = sigma1(w.15) &+ w.10 &+ sigma0(w.2) &+ w.1
        transformStep(506948616, w.1)
        w.2 = sigma1(w.0) &+ w.11 &+ sigma0(w.3) &+ w.2
        transformStep(659060556, w.2)
        w.3 = sigma1(w.1) &+ w.12 &+ sigma0(w.4) &+ w.3
        transformStep(883997877, w.3)
        w.4 = sigma1(w.2) &+ w.13 &+ sigma0(w.5) &+ w.4
        transformStep(958139571, w.4)
        w.5 = sigma1(w.3) &+ w.14 &+ sigma0(w.6) &+ w.5
        transformStep(1322822218, w.5)
        w.6 = sigma1(w.4) &+ w.15 &+ sigma0(w.7) &+ w.6
        transformStep(1537002063, w.6)
        w.7 = sigma1(w.5) &+ w.0 &+ sigma0(w.8) &+ w.7
        transformStep(1747873779, w.7)
        w.8 = sigma1(w.6) &+ w.1 &+ sigma0(w.9) &+ w.8
        transformStep(1955562222, w.8)
        w.9 = sigma1(w.7) &+ w.2 &+ sigma0(w.10) &+ w.9
        transformStep(2024104815, w.9)
        w.10 = sigma1(w.8) &+ w.3 &+ sigma0(w.11) &+ w.10
        transformStep(2227730452, w.10)
        w.11 = sigma1(w.9) &+ w.4 &+ sigma0(w.12) &+ w.11
        transformStep(2361852424, w.11)
        w.12 = sigma1(w.10) &+ w.5 &+ sigma0(w.13) &+ w.12
        transformStep(2428436474, w.12)
        w.13 = sigma1(w.11) &+ w.6 &+ sigma0(w.14) &+ w.13
        transformStep(2756734187, w.13)
        w.14 = sigma1(w.12) &+ w.7 &+ sigma0(w.15) &+ w.14
        transformStep(3204031479, w.14)
        w.15 = sigma1(w.13) &+ w.8 &+ sigma0(w.0) &+ w.15
        transformStep(3329325298, w.15)
        
        s = (s.a &+ abcdefgh.a, s.b &+ abcdefgh.b, s.c &+ abcdefgh.c, s.d &+ abcdefgh.d, s.e &+ abcdefgh.e, s.f &+ abcdefgh.f, s.g &+ abcdefgh.g, s.h &+ abcdefgh.h)
        
        w = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        
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
            w.0 = w.0 | UInt32(byte) << (bidx * 8)
        case 1:
            w.1 = w.1 | UInt32(byte) << (bidx * 8)
        case 2:
            w.2 = w.2 | UInt32(byte) << (bidx * 8)
        case 3:
            w.3 = w.3 | UInt32(byte) << (bidx * 8)
        case 4:
            w.4 = w.4 | UInt32(byte) << (bidx * 8)
        case 5:
            w.5 = w.5 | UInt32(byte) << (bidx * 8)
        case 6:
            w.6 = w.6 | UInt32(byte) << (bidx * 8)
        case 7:
            w.7 = w.7 | UInt32(byte) << (bidx * 8)
        case 8:
            w.8 = w.8 | UInt32(byte) << (bidx * 8)
        case 9:
            w.9 = w.9 | UInt32(byte) << (bidx * 8)
        case 10:
            w.10 = w.10 | UInt32(byte) << (bidx * 8)
        case 11:
            w.11 = w.11 | UInt32(byte) << (bidx * 8)
        case 12:
            w.12 = w.12 | UInt32(byte) << (bidx * 8)
        case 13:
            w.13 = w.13 | UInt32(byte) << (bidx * 8)
        case 14:
            w.14 = w.14 | UInt32(byte) << (bidx * 8)
        case 15:
            w.15 = w.15 | UInt32(byte) << (bidx * 8)
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
            w.0 = word
        case 1:
            w.1 = word
        case 2:
            w.2 = word
        case 3:
            w.3 = word
        case 4:
            w.4 = word
        case 5:
            w.5 = word
        case 6:
            w.6 = word
        case 7:
            w.7 = word
        case 8:
            w.8 = word
        case 9:
            w.9 = word
        case 10:
            w.10 = word
        case 11:
            w.11 = word
        case 12:
            w.12 = word
        case 13:
            w.13 = word
        case 14:
            w.14 = word
        case 15:
            w.15 = word
        default:
            fatalError()
        }
        
        if (bytesCount == Secp256k1sSha256.blockSizeBytes) {
            transform()
        }
    }
    
    fileprivate mutating func writeAbcdefgh(abcdefghInput: ABCDEFGH) {
        assert(bytesCount == 0)
        (w.0, w.1, w.2, w.3, w.4, w.5, w.6, w.7) = abcdefghInput
        bytesCount += 32
    }
    
    @inline(__always)
    func extractBytes(from word: UInt32, to bytes: inout [UInt8], at start: Int) {
        bytes[start] = UInt8(word >> 24 & 0xFF)
        bytes[start + 1] = UInt8(word >> 16 & 0xFF)
        bytes[start + 2] = UInt8(word >> 8 & 0xFF)
        bytes[start + 3] = UInt8(word & 0xFF)
    }
    
    fileprivate mutating func finalize2raw() -> ABCDEFGH {
        finalizeCore()
        defer {
            reset()
        }
        return s
    }
    
    public mutating func finalize() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: 32)
        finalize(hash: &hash)
        return hash
    }
    
    private mutating func finalizeCore() {
        let writtenSizeBits = (totalBytesCount + bytesCount) * 8
        write(byte: 0x80)
        
        if (Secp256k1sSha256.blockSizeBytes - bytesCount < 8) {
            bytesCount = Secp256k1sSha256.blockSizeBytes
            transform()
        }
        bytesCount = Secp256k1sSha256.blockSizeBytes - 4
        write(word: UInt32(writtenSizeBits))
    }
    
    private mutating func reset() {
        // reset
        s = Secp256k1sSha256.hs
        abcdefgh = Secp256k1sSha256.hs
        bytesCount = 0
        totalBytesCount = 0
    }
    
    public mutating func finalize(hash: inout [UInt8]) {
        let _ = finalizeWithRaw(hash: &hash)
    }
    
    fileprivate mutating func finalizeWithRaw(hash: inout [UInt8]) -> ABCDEFGH {
        assert(hash.count >= 32)
        
        finalizeCore()
        defer {
            reset()
        }
        
        extractBytes(from: s.a, to: &hash, at: 0 * 4)
        extractBytes(from: s.b, to: &hash, at: 1 * 4)
        extractBytes(from: s.c, to: &hash, at: 2 * 4)
        extractBytes(from: s.d, to: &hash, at: 3 * 4)
        extractBytes(from: s.e, to: &hash, at: 4 * 4)
        extractBytes(from: s.f, to: &hash, at: 5 * 4)
        extractBytes(from: s.g, to: &hash, at: 6 * 4)
        extractBytes(from: s.h, to: &hash, at: 7 * 4)
        
        return s
    }
}

public struct Secp256k1sHmacSha256 {
    var innerHasher = Secp256k1sSha256()
    var outterHasher = Secp256k1sSha256()
    
    static let innerCode: UInt8 = 0x36
    static let outterCode: UInt8 = 0x5c
    static let innerCodeWord: UInt32 = 0x36363636
    static let outterCodeWord: UInt32 = 0x5c5c5c5c
    
    public init() {
    }
    
    public init(key: [UInt8]) {
        resetKey(key: key)
    }
    
    public mutating func resetKey(key: [UInt8]) {
        var rkey = [UInt8](repeating: 0, count: 64)
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
    
    fileprivate mutating func resetKey(key: ABCDEFGH) {
        assert(innerHasher.bytesCount == 0 && outterHasher.bytesCount == 0)
        
        outterHasher.writeAbcdefgh(abcdefghInput: (
            key.a ^ Secp256k1sHmacSha256.outterCodeWord, key.b ^ Secp256k1sHmacSha256.outterCodeWord,
            key.c ^ Secp256k1sHmacSha256.outterCodeWord, key.d ^ Secp256k1sHmacSha256.outterCodeWord,
            key.e ^ Secp256k1sHmacSha256.outterCodeWord, key.f ^ Secp256k1sHmacSha256.outterCodeWord,
            key.g ^ Secp256k1sHmacSha256.outterCodeWord, key.h ^ Secp256k1sHmacSha256.outterCodeWord))
        innerHasher.writeAbcdefgh(abcdefghInput: (
            key.a ^ Secp256k1sHmacSha256.innerCodeWord, key.b ^ Secp256k1sHmacSha256.innerCodeWord,
            key.c ^ Secp256k1sHmacSha256.innerCodeWord, key.d ^ Secp256k1sHmacSha256.innerCodeWord,
            key.e ^ Secp256k1sHmacSha256.innerCodeWord, key.f ^ Secp256k1sHmacSha256.innerCodeWord,
            key.g ^ Secp256k1sHmacSha256.innerCodeWord, key.h ^ Secp256k1sHmacSha256.innerCodeWord))
        
        for _ in 0..<8 {
            outterHasher.write(word: Secp256k1sHmacSha256.outterCodeWord)
            innerHasher.write(word: Secp256k1sHmacSha256.innerCodeWord)
        }
    }
    
    public mutating func write(byte: UInt8) {
        innerHasher.write(byte: byte)
    }
    
    public mutating func write(bytes: [UInt8]) {
        innerHasher.write(bytes: bytes)
    }
    
    fileprivate mutating func write(abcdefghInput: ABCDEFGH) {
        innerHasher.write(word: abcdefghInput.a)
        innerHasher.write(word: abcdefghInput.b)
        innerHasher.write(word: abcdefghInput.c)
        innerHasher.write(word: abcdefghInput.d)
        innerHasher.write(word: abcdefghInput.e)
        innerHasher.write(word: abcdefghInput.f)
        innerHasher.write(word: abcdefghInput.g)
        innerHasher.write(word: abcdefghInput.h)
    }
    
    public mutating func write(bytes: ArraySlice<UInt8>) {
        innerHasher.write(bytes: bytes)
    }
    
    public mutating func finalize(hash: inout [UInt8]) {
        assert(hash.count >= 32)
        
        let rawHash = innerHasher.finalize2raw()
        outterHasher.writeAbcdefgh(abcdefghInput: rawHash)
        outterHasher.finalize(hash: &hash)
    }
    
    fileprivate mutating func finalizeWithRaw(hash: inout [UInt8]) -> ABCDEFGH {
        assert(hash.count >= 32)
        
        let rawHash = innerHasher.finalize2raw()
        outterHasher.writeAbcdefgh(abcdefghInput: rawHash)
        return outterHasher.finalizeWithRaw(hash: &hash)
    }
    
    fileprivate mutating func finalize2raw() -> ABCDEFGH {
        let rawHash = innerHasher.finalize2raw()
        outterHasher.writeAbcdefgh(abcdefghInput: rawHash)
        return outterHasher.finalize2raw()
    }
    
    public mutating func finalize() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: 32)
        finalize(hash: &hash)
        return hash
    }
}

public struct Secp256k1sRfc6979HmacSha256 {
    static let tempV: ABCDEFGH = (0x01010101, 0x01010101, 0x01010101, 0x01010101, 0x01010101, 0x01010101, 0x01010101, 0x01010101)
    static let tempK: ABCDEFGH = (0, 0, 0, 0, 0, 0, 0, 0)
    
    var v = Secp256k1sRfc6979HmacSha256.tempV
    var k = Secp256k1sRfc6979HmacSha256.tempK
    var retry = false
    var hmac = Secp256k1sHmacSha256()
    var outBuff = [UInt8](repeating: 0, count: 32)
    
    public init(key: [UInt8]) {
        resetKey(key: key)
    }
    
    public mutating func resetKey(key: [UInt8]) {
        v = Secp256k1sRfc6979HmacSha256.tempV
        k = Secp256k1sRfc6979HmacSha256.tempK
        
        hmac.resetKey(key: k)
        hmac.write(abcdefghInput: v)
        hmac.write(byte: 0)
        hmac.write(bytes: key)
        k = hmac.finalize2raw()
        hmac.resetKey(key: k)
        hmac.write(abcdefghInput: v)
        v = hmac.finalize2raw()
        
        hmac.resetKey(key: k)
        hmac.write(abcdefghInput: v)
        hmac.write(byte: 1)
        hmac.write(bytes: key)
        k = hmac.finalize2raw()
        hmac.resetKey(key: k)
        hmac.write(abcdefghInput: v)
        v = hmac.finalize2raw()
        retry = false
    }
    
    public mutating func generate(rand: inout [UInt8]) {
        generate(rand: &rand[0..<rand.count])
    }
    
    public mutating func generate(rand: inout ArraySlice<UInt8>) {
        var outlen = rand.count
        if retry {
            hmac.resetKey(key: k)
            hmac.write(abcdefghInput: v)
            hmac.write(byte: 0)
            k = hmac.finalize2raw()
            hmac.resetKey(key: k)
            hmac.write(abcdefghInput: v)
            v = hmac.finalize2raw()
        }
        
        while outlen > 0 {
            hmac.resetKey(key: k)
            hmac.write(abcdefghInput: v)
            v = hmac.finalizeWithRaw(hash: &outBuff)
            
            let cpyCount = Swift.min(outlen, 32)
            let cpyStart = rand.startIndex + rand.count - outlen
            rand[cpyStart..<cpyStart+cpyCount] = outBuff[0..<cpyCount]
            outlen -= cpyCount
        }
        retry = true
    }
}

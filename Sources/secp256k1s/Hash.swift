public struct Secp256k1sSha256 {
    typealias ABCDEFGH = (a: UInt32, b: UInt32, c: UInt32, d: UInt32, e: UInt32, f: UInt32, g: UInt32, h: UInt32)
    
    static let blockSizeBytes = 64
    static let blockSizeWords = 16
    static let sSize = 8
    static let hs: ABCDEFGH = (0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19)
    
    var s = Secp256k1sSha256.hs
    var ws = [UInt32](repeating: 0, count: Secp256k1sSha256.blockSizeWords)
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
    
    private mutating func transform() {
        assert(bytesCount == Secp256k1sSha256.blockSizeBytes)
        var t1: UInt32 = 0
        var t2: UInt32 = 0
        var w0 = ws[0], w1 = ws[1], w2 = ws[2], w3 = ws[3], w4 = ws[4], w5 = ws[5], w6 = ws[6], w7 = ws[7]
        var w8 = ws[8], w9 = ws[9], w10 = ws[10], w11 = ws[11], w12 = ws[12], w13 = ws[13], w14 = ws[14], w15 = ws[15]
        
        var a = s.a, b = s.b, c = s.c, d = s.d, e = s.e, f = s.f, g = s.g, h = s.h
        var stepi = 0
        
        t1 = h &+ bigSigma1(e) &+ ch(x: e, y: f, z: g) &+ Secp256k1sSha256.k0[stepi] &+ w0
        t2 = bigSigma0(a) &+ maj(x: a, y: b, z: c)
        h = t1 &+ t2
        d = d &+ t1
        stepi += 1
        
        t1 = g &+ bigSigma1(d) &+ ch(x: d, y: e, z: f) &+ Secp256k1sSha256.k0[stepi] &+ w1
        t2 = bigSigma0(h) &+ maj(x: h, y: a, z: b)
        g = t1 &+ t2
        c = c &+ t1
        stepi += 1
        
        t1 = f &+ bigSigma1(c) &+ ch(x: c, y: d, z: e) &+ Secp256k1sSha256.k0[stepi] &+ w2
        t2 = bigSigma0(g) &+ maj(x: g, y: h, z: a)
        f = t1 &+ t2
        b = b &+ t1
        stepi += 1
        
        t1 = e &+ bigSigma1(b) &+ ch(x: b, y: c, z: d) &+ Secp256k1sSha256.k0[stepi] &+ w3
        t2 = bigSigma0(f) &+ maj(x: f, y: g, z: h)
        e = t1 &+ t2
        a = a &+ t1
        stepi += 1
        
        t1 = d &+ bigSigma1(a) &+ ch(x: a, y: b, z: c) &+ Secp256k1sSha256.k0[stepi] &+ w4
        t2 = bigSigma0(e) &+ maj(x: e, y: f, z: g)
        d = t1 &+ t2
        h = h &+ t1
        stepi += 1
        
        t1 = c &+ bigSigma1(h) &+ ch(x: h, y: a, z: b) &+ Secp256k1sSha256.k0[stepi] &+ w5
        t2 = bigSigma0(d) &+ maj(x: d, y: e, z: f)
        c = t1 &+ t2
        g = g &+ t1
        stepi += 1
        
        t1 = b &+ bigSigma1(g) &+ ch(x: g, y: h, z: a) &+ Secp256k1sSha256.k0[stepi] &+ w6
        t2 = bigSigma0(c) &+ maj(x: c, y: d, z: e)
        b = t1 &+ t2
        f = f &+ t1
        stepi += 1
        
        t1 = a &+ bigSigma1(f) &+ ch(x: f, y: g, z: h) &+ Secp256k1sSha256.k0[stepi] &+ w7
        t2 = bigSigma0(b) &+ maj(x: b, y: c, z: d)
        a = t1 &+ t2
        e = e &+ t1
        stepi += 1
        
        /**********/
        t1 = h &+ bigSigma1(e) &+ ch(x: e, y: f, z: g) &+ Secp256k1sSha256.k0[stepi] &+ w8
        t2 = bigSigma0(a) &+ maj(x: a, y: b, z: c)
        h = t1 &+ t2
        d = d &+ t1
        stepi += 1
        
        t1 = g &+ bigSigma1(d) &+ ch(x: d, y: e, z: f) &+ Secp256k1sSha256.k0[stepi] &+ w9
        t2 = bigSigma0(h) &+ maj(x: h, y: a, z: b)
        g = t1 &+ t2
        c = c &+ t1
        stepi += 1
        
        t1 = f &+ bigSigma1(c) &+ ch(x: c, y: d, z: e) &+ Secp256k1sSha256.k0[stepi] &+ w10
        t2 = bigSigma0(g) &+ maj(x: g, y: h, z: a)
        f = t1 &+ t2
        b = b &+ t1
        stepi += 1
        
        t1 = e &+ bigSigma1(b) &+ ch(x: b, y: c, z: d) &+ Secp256k1sSha256.k0[stepi] &+ w11
        t2 = bigSigma0(f) &+ maj(x: f, y: g, z: h)
        e = t1 &+ t2
        a = a &+ t1
        stepi += 1
        
        t1 = d &+ bigSigma1(a) &+ ch(x: a, y: b, z: c) &+ Secp256k1sSha256.k0[stepi] &+ w12
        t2 = bigSigma0(e) &+ maj(x: e, y: f, z: g)
        d = t1 &+ t2
        h = h &+ t1
        stepi += 1
        
        t1 = c &+ bigSigma1(h) &+ ch(x: h, y: a, z: b) &+ Secp256k1sSha256.k0[stepi] &+ w13
        t2 = bigSigma0(d) &+ maj(x: d, y: e, z: f)
        c = t1 &+ t2
        g = g &+ t1
        stepi += 1
        
        t1 = b &+ bigSigma1(g) &+ ch(x: g, y: h, z: a) &+ Secp256k1sSha256.k0[stepi] &+ w14
        t2 = bigSigma0(c) &+ maj(x: c, y: d, z: e)
        b = t1 &+ t2
        f = f &+ t1
        stepi += 1
        
        t1 = a &+ bigSigma1(f) &+ ch(x: f, y: g, z: h) &+ Secp256k1sSha256.k0[stepi] &+ w15
        t2 = bigSigma0(b) &+ maj(x: b, y: c, z: d)
        a = t1 &+ t2
        e = e &+ t1
        stepi += 1
        
        for _ in 0..<3 {
            w0 = sigma1(w14) &+ w9 &+ sigma0(w1) &+ w0
            
            t1 = h &+ bigSigma1(e) &+ ch(x: e, y: f, z: g) &+ Secp256k1sSha256.k0[stepi] &+ w0
            t2 = bigSigma0(a) &+ maj(x: a, y: b, z: c)
            h = t1 &+ t2
            d = d &+ t1
            stepi += 1
            
            w1 = sigma1(w15) &+ w10 &+ sigma0(w2) &+ w1
            
            t1 = g &+ bigSigma1(d) &+ ch(x: d, y: e, z: f) &+ Secp256k1sSha256.k0[stepi] &+ w1
            t2 = bigSigma0(h) &+ maj(x: h, y: a, z: b)
            g = t1 &+ t2
            c = c &+ t1
            stepi += 1
            
            w2 = sigma1(w0) &+ w11 &+ sigma0(w3) &+ w2
            
            t1 = f &+ bigSigma1(c) &+ ch(x: c, y: d, z: e) &+ Secp256k1sSha256.k0[stepi] &+ w2
            t2 = bigSigma0(g) &+ maj(x: g, y: h, z: a)
            f = t1 &+ t2
            b = b &+ t1
            stepi += 1
            
            w3 = sigma1(w1) &+ w12 &+ sigma0(w4) &+ w3
            
            t1 = e &+ bigSigma1(b) &+ ch(x: b, y: c, z: d) &+ Secp256k1sSha256.k0[stepi] &+ w3
            t2 = bigSigma0(f) &+ maj(x: f, y: g, z: h)
            e = t1 &+ t2
            a = a &+ t1
            stepi += 1
            
            w4 = sigma1(w2) &+ w13 &+ sigma0(w5) &+ w4
            
            t1 = d &+ bigSigma1(a) &+ ch(x: a, y: b, z: c) &+ Secp256k1sSha256.k0[stepi] &+ w4
            t2 = bigSigma0(e) &+ maj(x: e, y: f, z: g)
            d = t1 &+ t2
            h = h &+ t1
            stepi += 1
            
            w5 = sigma1(w3) &+ w14 &+ sigma0(w6) &+ w5
            
            t1 = c &+ bigSigma1(h) &+ ch(x: h, y: a, z: b) &+ Secp256k1sSha256.k0[stepi] &+ w5
            t2 = bigSigma0(d) &+ maj(x: d, y: e, z: f)
            c = t1 &+ t2
            g = g &+ t1
            stepi += 1
            
            w6 = sigma1(w4) &+ w15 &+ sigma0(w7) &+ w6
            
            t1 = b &+ bigSigma1(g) &+ ch(x: g, y: h, z: a) &+ Secp256k1sSha256.k0[stepi] &+ w6
            t2 = bigSigma0(c) &+ maj(x: c, y: d, z: e)
            b = t1 &+ t2
            f = f &+ t1
            stepi += 1
            
            w7 = sigma1(w5) &+ w0 &+ sigma0(w8) &+ w7
            
            t1 = a &+ bigSigma1(f) &+ ch(x: f, y: g, z: h) &+ Secp256k1sSha256.k0[stepi] &+ w7
            t2 = bigSigma0(b) &+ maj(x: b, y: c, z: d)
            a = t1 &+ t2
            e = e &+ t1
            stepi += 1
            
            /**********/
            w8 = sigma1(w6) &+ w1 &+ sigma0(w9) &+ w8
            
            t1 = h &+ bigSigma1(e) &+ ch(x: e, y: f, z: g) &+ Secp256k1sSha256.k0[stepi] &+ w8
            t2 = bigSigma0(a) &+ maj(x: a, y: b, z: c)
            h = t1 &+ t2
            d = d &+ t1
            stepi += 1
            
            w9 = sigma1(w7) &+ w2 &+ sigma0(w10) &+ w9
            
            t1 = g &+ bigSigma1(d) &+ ch(x: d, y: e, z: f) &+ Secp256k1sSha256.k0[stepi] &+ w9
            t2 = bigSigma0(h) &+ maj(x: h, y: a, z: b)
            g = t1 &+ t2
            c = c &+ t1
            stepi += 1
            
            w10 = sigma1(w8) &+ w3 &+ sigma0(w11) &+ w10
            
            t1 = f &+ bigSigma1(c) &+ ch(x: c, y: d, z: e) &+ Secp256k1sSha256.k0[stepi] &+ w10
            t2 = bigSigma0(g) &+ maj(x: g, y: h, z: a)
            f = t1 &+ t2
            b = b &+ t1
            stepi += 1
            
            w11 = sigma1(w9) &+ w4 &+ sigma0(w12) &+ w11
            
            t1 = e &+ bigSigma1(b) &+ ch(x: b, y: c, z: d) &+ Secp256k1sSha256.k0[stepi] &+ w11
            t2 = bigSigma0(f) &+ maj(x: f, y: g, z: h)
            e = t1 &+ t2
            a = a &+ t1
            stepi += 1
            
            w12 = sigma1(w10) &+ w5 &+ sigma0(w13) &+ w12
            
            t1 = d &+ bigSigma1(a) &+ ch(x: a, y: b, z: c) &+ Secp256k1sSha256.k0[stepi] &+ w12
            t2 = bigSigma0(e) &+ maj(x: e, y: f, z: g)
            d = t1 &+ t2
            h = h &+ t1
            stepi += 1
            
            w13 = sigma1(w11) &+ w6 &+ sigma0(w14) &+ w13
            
            t1 = c &+ bigSigma1(h) &+ ch(x: h, y: a, z: b) &+ Secp256k1sSha256.k0[stepi] &+ w13
            t2 = bigSigma0(d) &+ maj(x: d, y: e, z: f)
            c = t1 &+ t2
            g = g &+ t1
            stepi += 1
            
            w14 = sigma1(w12) &+ w7 &+ sigma0(w15) &+ w14
            
            t1 = b &+ bigSigma1(g) &+ ch(x: g, y: h, z: a) &+ Secp256k1sSha256.k0[stepi] &+ w14
            t2 = bigSigma0(c) &+ maj(x: c, y: d, z: e)
            b = t1 &+ t2
            f = f &+ t1
            stepi += 1
            
            w15 = sigma1(w13) &+ w8 &+ sigma0(w0) &+ w15
            
            t1 = a &+ bigSigma1(f) &+ ch(x: f, y: g, z: h) &+ Secp256k1sSha256.k0[stepi] &+ w15
            t2 = bigSigma0(b) &+ maj(x: b, y: c, z: d)
            a = t1 &+ t2
            e = e &+ t1
            stepi += 1
        }
        
        
        s = (s.a &+ a, s.b &+ b, s.c &+ c, s.d &+ d, s.e &+ e, s.f &+ f, s.g &+ g, s.h &+ h)
        
        
        for i in 0..<ws.count {
            ws[i] = 0
        }
        totalBytesCount += Secp256k1sSha256.blockSizeBytes
        bytesCount = 0
        stepi = 0
    }
    
    public mutating func write(bytes: [UInt8]) {
        let wordFillBytesCount = (4 - bytesCount & 0x3) & 0x3
        var byteIdx = 0
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
    
    @inline(__always)
    mutating func write(byte: UInt8) {
        let widx = bytesCount >> 2
        let bidx = 3 - bytesCount & 0x3 // big endian
        ws[widx] = ws[widx] | UInt32(byte) << (bidx * 8)
        bytesCount += 1
        if (bytesCount == Secp256k1sSha256.blockSizeBytes) {
            transform()
        }
    }
    
    @inline(__always)
    mutating func write(word: UInt32) {
        assert(bytesCount & 0x3 == 0)
        
        let widx = bytesCount >> 2
        ws[widx] = word
        bytesCount += 4
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
        let writtenSizeBits = (totalBytesCount + bytesCount) * 8
        write(byte: 0x80)
        
        if (Secp256k1sSha256.blockSizeBytes - bytesCount < 8) {
            bytesCount = Secp256k1sSha256.blockSizeBytes
            transform()
        }
        bytesCount = Secp256k1sSha256.blockSizeBytes - 4
        write(word: UInt32(writtenSizeBits))
        
        var hash = [UInt8](repeating: 0, count: 32)
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
        bytesCount = 0
        totalBytesCount = 0
        
        return hash
    }
    
}

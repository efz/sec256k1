public struct Secpt256k1Scalar {
    var d : [UInt64]
    
    static let wordWidth = 8
    static let wordBitWidth = UInt32.bitWidth
    
    static let p : [UInt64] = [0xD0364141, 0xBFD25E8C, 0xAF48A03B, 0xBAAEDCE6, 0xFFFFFFFE, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF]
    public static var prime : Secpt256k1Scalar {
        let p32 = p.map { UInt32($0) }
        return Secpt256k1Scalar(words: p32)
    }
    
    static let overflowBitSet = UInt64(1 << UInt32.bitWidth)
    static let wordMask = UInt64(UInt32.max)
    
    public init() {
        d = Array.init(repeating: 0, count: Secpt256k1Scalar.wordWidth)
    }
    
    public init(words : [UInt32]) {
        self.init()
        for i in 0..<Secpt256k1Scalar.wordWidth {
            d[i] = UInt64(words[i])
        }
        reduce()
    }
    
    public init(bytes : [UInt8]) {
        self.init()
        for i in 0..<bytes.count {
            let wordIdx = 7 - i / 4
            let byteIdx = 3 - i % 4
            d[wordIdx] |= UInt64(bytes[i]) << (byteIdx * 8)
        }
        reduce()
    }
    
    public init(int v : UInt32) {
        self.init()
        d[0] = UInt64(v)
    }
    
    public init(scalar  s: Secpt256k1Scalar) {
        self.init()
        for i in 0..<Secpt256k1Scalar.wordWidth {
            d[i] = s.d[i]
        }
        reduce()
    }
    
    public func checkOverflow() -> Bool {
        var strictOverflow = false
        var equals = true
        
        for i in (0..<Secpt256k1Scalar.wordWidth).reversed() {
            strictOverflow = (d[i] > Secpt256k1Scalar.p[i] && equals) || strictOverflow
            equals = d[i] == Secpt256k1Scalar.p[i] && equals
        }
        return strictOverflow || equals
    }
    
    mutating func reduce(overflow : UInt64 = 0) {
        var t : UInt64 = 0
        for i in 0..<Secpt256k1Scalar.wordWidth {
            let tmp : UInt64 = (Secpt256k1Scalar.overflowBitSet | d[i]) - Secpt256k1Scalar.p[i] - t
            t = (tmp >> Secpt256k1Scalar.wordBitWidth) ^ 1
            d[i] = (d[i] & Secpt256k1Scalar.wordMask) | (tmp << Secpt256k1Scalar.wordBitWidth)
        }
        let takeUpperHalf = overflow | (1 - t)
        assert(takeUpperHalf == 1 || takeUpperHalf == 0)
        let upperMask = takeUpperHalf * Secpt256k1Scalar.wordMask
        let lowerMask = (1 - takeUpperHalf) * Secpt256k1Scalar.wordMask
        
        for i in 0..<Secpt256k1Scalar.wordWidth {
            d[i] = (upperMask & (d[i] >> Secpt256k1Scalar.wordBitWidth)) | (lowerMask  & d[i])
            assert(d[i] >> Secpt256k1Scalar.wordBitWidth == 0)
        }
    }
    
    public mutating func add(_ y : Secpt256k1Scalar, carry: UInt64 = 0) {
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        var t : UInt64 = carry
        for i in 0..<Secpt256k1Scalar.wordWidth {
            t = d[i] + y.d[i] + t
            d[i] = t & Secpt256k1Scalar.wordMask
            t = t >> Secpt256k1Scalar.wordBitWidth
        }
        assert(t <= 1)
        reduce(overflow: t)
    }
    
    public static func add(_ x : Secpt256k1Scalar, _ y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        var r = Secpt256k1Scalar.init(scalar: x)
        r.add(y)
        return r
    }
    
    public static func +(x : Secpt256k1Scalar, y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        return Secpt256k1Scalar.add(x, y)
    }
    
    public func isZero() -> Bool {
        return d.reduce(0) { $0 | $1 } == 0
    }
    
    public func isOne() -> Bool {
        return d[0] ^ 1 | d[1..<Secpt256k1Scalar.wordWidth].reduce(0) { $0 | $1 } == 0
    }
    
    public func getBytes() -> [UInt8] {
        assert(!checkOverflow())
        let b: [UInt8] = (0..<32).reversed().map { ($0 / 4, $0 % 4) }.map { idx in
            let word = d[idx.0]
            let byte : UInt8 = UInt8((word >> (idx.1 * 8)) & UInt64(UInt8.max))
            return byte
        }
        return b
    }
    
    public func getBits(offset : Int, count : Int) -> UInt32 {
        assert(offset + count <= Secpt256k1Scalar.wordBitWidth * Secpt256k1Scalar.wordWidth)
        assert(count < Secpt256k1Scalar.wordBitWidth)
        if offset >> 5 == (count + offset - 1) >> 5 {
            return UInt32((d[offset >> 5] >> (offset & 0x1F)) & ((1 << count) - 1))
        } else {
            assert((offset >> 5) + 1 < 8)
            let firstHalf = UInt32(d[offset >> 5] >> (offset & 0x1F))
            let secondHalf = UInt32((d[(offset >> 5) + 1] << (32 - (offset & 0x1F)) & Secpt256k1Scalar.wordMask))
            return (firstHalf | secondHalf) & ((1 << count) - 1)
        }
    }
}

extension Secpt256k1Scalar : Equatable {
    public static func == (lhs: Secpt256k1Scalar, rhs: Secpt256k1Scalar) -> Bool {
        return lhs.d == rhs.d
    }
}

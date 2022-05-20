public struct Secpt256k1Scalar {
    var d : [UInt64]
    var overflow: UInt64 = 0
    
    public var isOverflow : Bool {
        return overflow > 0
    }
    
    static let wordWidth = 8
    
    static let p : [UInt64] = [0xD0364141, 0xBFD25E8C, 0xAF48A03B, 0xBAAEDCE6, 0xFFFFFFFE, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF]
    public static var prime : Secpt256k1Scalar {
        let p32 = p.map { UInt32($0) }
        return Secpt256k1Scalar(words: p32)
    }
    
    static let wordHighBitSet = UInt64(1 << UInt32.bitWidth)
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
    
    mutating func checkOverflow() -> UInt64 {
        var strictOverflow = false
        var equals = true
        
        for i in (0..<Secpt256k1Scalar.wordWidth).reversed() {
            strictOverflow = (d[i] > Secpt256k1Scalar.p[i] && equals) || strictOverflow
            equals = d[i] == Secpt256k1Scalar.p[i] && equals
        }
        overflow = strictOverflow || equals ? 1 : 0
        return overflow
    }
    
    mutating func reduce() {
        let anyOverflow : UInt64 = overflow | checkOverflow();
        var t : UInt64 = 0
        assert(t <= 1)
        for i in 0..<Secpt256k1Scalar.wordWidth {
            let tmp : UInt64 = (Secpt256k1Scalar.wordHighBitSet | d[i]) - (anyOverflow * Secpt256k1Scalar.p[i] + t)
            t = (tmp >> UInt32.bitWidth) ^ 1
            d[i] = tmp & Secpt256k1Scalar.wordMask
        }
        overflow = 0
    }
    
    public mutating func add(_ y : Secpt256k1Scalar) {
        var t : UInt64 = 0
        for i in 0..<Secpt256k1Scalar.wordWidth {
            t = d[i] + y.d[i] + t
            d[i] = t & Secpt256k1Scalar.wordMask
            t = t >> UInt32.bitWidth
        }
        assert(t <= 1)
        overflow = overflow | t
        reduce()
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
        assert(overflow == 0)
        let b: [UInt8] = (0..<32).reversed().map { ($0 / 4, $0 % 4) }.map { idx in
            let word = d[idx.0]
            let byte : UInt8 = UInt8((word >> (idx.1 * 8)) & UInt64(UInt8.max))
            return byte
        }
        return b
    }
    
    public func getBits(offset : Int, count : Int) -> UInt32 {
        assert(offset + count <= UInt32.bitWidth * Secpt256k1Scalar.wordWidth)
        assert(count < UInt32.bitWidth)
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

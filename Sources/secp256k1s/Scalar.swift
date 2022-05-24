public struct Secpt256k1Scalar {
    var d : [UInt64]
    
    static let wordWidth = 8
    static let word64Width = 4
    static let wordBitWidth = UInt32.bitWidth
    static let word64BitWidth = UInt64.bitWidth
    
    static let p : [UInt64] = [0xD0364141, 0xBFD25E8C, 0xAF48A03B, 0xBAAEDCE6, 0xFFFFFFFE, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF]
    static let pPacked : [UInt64] = [0xBFD25E8CD0364141, 0xBAAEDCE6AF48A03B, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF]
    
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
    
    public func isEven() -> Bool {
        return d[0] == 0
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
    
    public mutating func clear() {
        (0..<Secpt256k1Scalar.wordWidth).forEach() { d[$0] = 0 }
    }
    
    public mutating func negate() {
        assert(!checkOverflow())
        var carry : UInt64 = 0
        for i in 0..<Secpt256k1Scalar.wordWidth {
            d[i] = (Secpt256k1Scalar.overflowBitSet | Secpt256k1Scalar.p[i]) - d[i] - carry
            carry = (d[i] >> Secpt256k1Scalar.wordBitWidth) ^ 1
            d[i] = d[i] & Secpt256k1Scalar.wordMask
        }
        assert(carry == 0)
        assert(!checkOverflow())
    }
    
    public static func substract(_ x : Secpt256k1Scalar, _ y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        var r1 = Secpt256k1Scalar.init(scalar: x)
        var r2 = Secpt256k1Scalar.init(scalar: y)
        r2.negate()
        r1.add(r2)
        return r2
    }
    
    public static func -(x : Secpt256k1Scalar, y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        return Secpt256k1Scalar.substract(x, y)
    }
    
    static func subPfrom512bits(start: Int, bits512: inout [UInt64]) {
        let shift = start & 0x3F
        var bitsIdx = start >> 6
        var pIdx = 0
        var t : UInt64 = 0
        var overflow = false
        
        (bits512[bitsIdx], overflow) = bits512[bitsIdx].subtractingReportingOverflow(Secpt256k1Scalar.pPacked[pIdx] << shift)
        t = overflow ? 1 : 0
        
        repeat {
            pIdx += 1
            bitsIdx += 1
            
            (bits512[bitsIdx], overflow) = bits512[bitsIdx].subtractingReportingOverflow(t)
            t = overflow ? 1 : 0
            (bits512[bitsIdx], overflow) = bits512[bitsIdx].subtractingReportingOverflow(
                (Secpt256k1Scalar.pPacked[pIdx] << shift) | (Secpt256k1Scalar.pPacked[pIdx - 1] >> (Secpt256k1Scalar.word64BitWidth - shift)))
            t += overflow ? 1 : 0
        } while pIdx < Secpt256k1Scalar.word64Width - 1
        
        pIdx += 1
        bitsIdx += 1
        
        (bits512[bitsIdx], overflow) = bits512[bitsIdx].subtractingReportingOverflow(t)
        t = overflow ? 1 : 0
        (bits512[bitsIdx], overflow) = bits512[bitsIdx].subtractingReportingOverflow(Secpt256k1Scalar.pPacked[pIdx - 1] >> (Secpt256k1Scalar.word64BitWidth - shift))
        t += overflow ? 1 : 0
        assert(t == 0)
    }
    
    public mutating func mul(_ y : Secpt256k1Scalar) {
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        var tmpd: [UInt64] = Array.init(repeating: 0, count: Secpt256k1Scalar.wordWidth * 2 + 1)
        var t : UInt64 = 0
        var t2: UInt64 = 0
        var mulOverflow = false
        for idxSum in 0..<(Secpt256k1Scalar.wordWidth * 2) {
            for i in Swift.max(0, idxSum - Secpt256k1Scalar.wordWidth + 1)..<Swift.min(idxSum+1, Secpt256k1Scalar.wordWidth) {
                //print("idxsum: \(idxSum), i: \(i)")
                let mulVal = d[i] * y.d[idxSum - i]
                (t, mulOverflow) = t.addingReportingOverflow(mulVal)
                t2 += mulOverflow ? 1 : 0
            }
            tmpd[idxSum>>1] = tmpd[idxSum>>1] | (((t & Secpt256k1Scalar.wordMask) << (Secpt256k1Scalar.wordBitWidth * (idxSum & 1))))
            t = t >> Secpt256k1Scalar.wordBitWidth | t2 << Secpt256k1Scalar.wordBitWidth
            t2 = t2 >> Secpt256k1Scalar.wordBitWidth
        }
        assert(t2 == 0)
        tmpd[Secpt256k1Scalar.wordWidth] = t
        
        var bit = (Secpt256k1Scalar.word64Width * 2 + 1) * Secpt256k1Scalar.word64BitWidth - 1
        while bit > Secpt256k1Scalar.word64Width * Secpt256k1Scalar.word64BitWidth - 1 {
            let wordIdx = bit >> 6
            let wordBitIdx = bit & 0x3F
    
            var need2Clear = tmpd[wordIdx] & (1 << wordBitIdx)
            
            if need2Clear > 0 {
                let subStartBit = bit - Secpt256k1Scalar.word64Width * Secpt256k1Scalar.word64BitWidth
                Secpt256k1Scalar.subPfrom512bits(start: subStartBit, bits512: &tmpd)
                need2Clear = tmpd[wordIdx] & (1 << wordBitIdx)
            }

            bit -= (need2Clear > 0) ? 0 : 1
        }
        
        for i in 0..<(Secpt256k1Scalar.wordWidth) {
            let shift = (i & 1) * Secpt256k1Scalar.wordBitWidth
            d[i] = (tmpd[i>>1] >> shift) & Secpt256k1Scalar.wordMask
        }
        let overflow: UInt64 = tmpd[Secpt256k1Scalar.wordWidth]
        
        assert(overflow <= 1)
        reduce(overflow: overflow)
        assert(!checkOverflow())
    }
    
    public static func mul(x : Secpt256k1Scalar, y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        var r = x
        r.mul(y)
        return r
    }
    
    public static func *(x : Secpt256k1Scalar, y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        return Secpt256k1Scalar.mul(x: x, y: y)
    }
}

extension Secpt256k1Scalar : Equatable {
    public static func == (lhs: Secpt256k1Scalar, rhs: Secpt256k1Scalar) -> Bool {
        return lhs.d == rhs.d
    }
}

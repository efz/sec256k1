public struct Secpt256k1Scalar {
    var d : [UInt64]
    var bits512: [UInt64]
    
    static let wordWidth = 4
    static let pCompWordWidth = 3
    static let wordBitWidth = UInt64.bitWidth
    
    static let p : [UInt64] = [0xBFD25E8CD0364141, 0xBAAEDCE6AF48A03B, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF]
    static let pMinus2 : [UInt64] = [0xBFD25E8CD036413F, 0xBAAEDCE6AF48A03B, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF]
    static let pComp: [UInt64] = [~p[0] + 1, ~p[1], ~p[2]]
    static let pCompLeadingZeros = 127
    
    private static let pMinus2MetaData = { () -> (segmentDefs: [(start: Int, end: Int)], segments: [Int:Secpt256k1Scalar], maxSegmentLen: Int) in
        var segmentDefs: [(start: Int, end: Int)] = []
        var segments: [Int:Secpt256k1Scalar] = [:]
        var maxSegmentLen = 0
        var curSegStart = -1
        let onNewSegment: (Int) -> Void = { end in
            segmentDefs.append((curSegStart, end))
            let segmentLen = end - curSegStart
            segments[segmentLen] = Secpt256k1Scalar.zero
            if segmentLen > maxSegmentLen {
                maxSegmentLen = segmentLen
            }
            curSegStart = -1
        }
        
        for i in 0..<Secpt256k1Scalar.wordWidth {
            var bitMask: UInt64 = 1
            for j in 0..<Secpt256k1Scalar.wordBitWidth {
                let bitPos = i * Secpt256k1Scalar.wordBitWidth + j
                
                let bitSet = Secpt256k1Scalar.pMinus2[i] & bitMask != 0
                if bitSet {
                    if curSegStart == -1 {
                        curSegStart = bitPos
                    }
                } else if curSegStart != -1 {
                    onNewSegment(bitPos)
                }
                
                bitMask = bitMask << 1
            }
        }
        if curSegStart != -1 {
            let endPos = Secpt256k1Scalar.wordWidth * Secpt256k1Scalar.wordBitWidth
            onNewSegment(endPos)
        }
        return (segmentDefs, segments, maxSegmentLen)
    }()
    
    public static let zero = Secpt256k1Scalar()
    public static let one = Secpt256k1Scalar(int: 1)
    
    public static var prime : Secpt256k1Scalar {
        return Secpt256k1Scalar(words64: p)
    }
    
    static let wordMask = UInt64.max
    
    public init() {
        d = [UInt64](repeating: 0, count: Secpt256k1Scalar.wordWidth * 2)
        bits512 = [UInt64](repeating: 0, count: Secpt256k1Scalar.wordWidth * 2)
    }
    
    public init(words : [UInt32]) {
        self.init()
        for i in 0..<Secpt256k1Scalar.wordWidth {
            d[i] = (UInt64(words[2 * i + 1]) << UInt32.bitWidth) | UInt64(words[2 * i])
        }
        reduce()
    }
    
    public init(words64 : [UInt64]) {
        self.init()
        for i in 0..<Secpt256k1Scalar.wordWidth {
            d[i] = words64[i]
        }
        reduce()
    }
    
    public init(bytes : [UInt8]) {
        self.init()
        for i in 0..<bytes.count {
            let wordIdx = 3 - i / 8
            let byteIdx = 7 - i % 8
            d[wordIdx] |= UInt64(bytes[i]) << (byteIdx * 8)
        }
        reduce()
    }
    
    public init(int v : UInt32) {
        self.init()
        d[0] = UInt64(v)
    }
    
    public init(int64 v : UInt64) {
        self.init()
        d[0] = v
    }
    
    public init(scalar  s: Secpt256k1Scalar) {
        self.init()
        for i in 0..<Secpt256k1Scalar.wordWidth {
            d[i] = s.d[i]
        }
        reduce()
    }
    
    mutating func setInt(_ v: UInt64) {
        d[0] = v
        for i in 1..<Secpt256k1Scalar.wordWidth {
            d[i] = 0
        }
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
        guard overflow > 0 || checkOverflow() else {
            return
        }
        assert(overflow <= 1)
        
        var t : UInt64 = 0
        var carry = false
        for i in 0..<Secpt256k1Scalar.wordWidth {
            (d[i], carry) = d[i].subtractingReportingOverflow(t)
            t = carry ? 1 : 0
            (d[i], carry) = d[i].subtractingReportingOverflow(Secpt256k1Scalar.p[i])
            t += carry ? 1 : 0
        }
        assert(t == overflow)
    }
    
    public mutating func add(_ y : Secpt256k1Scalar, carry: UInt64 = 0) {
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        var t : UInt64 = carry
        var overflow = false
        for i in 0..<Secpt256k1Scalar.wordWidth {
            (d[i], overflow) = d[i].addingReportingOverflow(t)
            t = overflow ? 1 : 0
            (d[i], overflow) = d[i].addingReportingOverflow(y.d[i])
            t += overflow ? 1 : 0
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
        return d[0..<Secpt256k1Scalar.wordWidth].reduce(0) { $0 | $1 } == 0
    }
    
    public func isOne() -> Bool {
        return d[0] ^ 1 | d[1..<Secpt256k1Scalar.wordWidth].reduce(0) { $0 | $1 } == 0
    }
    
    public func isEven() -> Bool {
        return d[0] == 0
    }
    
    public func getBytes() -> [UInt8] {
        assert(!checkOverflow())
        let b: [UInt8] = (0..<32).reversed().map { ($0 / 8, $0 % 8) }.map { idx in
            let word = d[idx.0]
            let byte : UInt8 = UInt8((word >> (idx.1 * 8)) & UInt64(UInt8.max))
            return byte
        }
        return b
    }
    
    public func getBits64(offset : Int, count : Int) -> UInt64 {
        assert(offset + count <= Secpt256k1Scalar.wordBitWidth * Secpt256k1Scalar.wordWidth)
        assert(count < Secpt256k1Scalar.wordBitWidth)
        if offset >> 6 == (count + offset - 1) >> 6 {
            return UInt64((d[offset >> 6] >> (offset & 0x3F)) & ((1 << count) - 1))
        } else {
            assert((offset >> 6) + 1 < 4)
            let firstHalf = UInt64(d[offset >> 6] >> (offset & 0x3F))
            let secondHalf = UInt64((d[(offset >> 6) + 1] << (64 - (offset & 0x3F)) & Secpt256k1Scalar.wordMask))
            return (firstHalf | secondHalf) & ((1 << count) - 1)
        }
    }
    
    public func getBits(offset : Int, count : Int) -> UInt32 {
        assert(count < UInt32.bitWidth)
        return UInt32(getBits64(offset: offset, count: count))
    }
    
    public mutating func clear() {
        (0..<Secpt256k1Scalar.wordWidth).forEach() { d[$0] = 0 }
    }
    
    public mutating func negate() {
        assert(!checkOverflow())
        guard !isZero() else {
            return
        }
        var t : UInt64 = 0
        var t2 : UInt64 = 0
        var overflow = false
        for i in 0..<Secpt256k1Scalar.wordWidth {
            (d[i], overflow) = Secpt256k1Scalar.p[i].subtractingReportingOverflow(d[i])
            t2 = overflow ? 1 : 0
            (d[i], overflow) = d[i].subtractingReportingOverflow(t)
            t2 += overflow ? 1 : 0
            (t, t2) = (t2, 0)
        }
        assert(t == 0)
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
    
    static func reduceBitbyBit(bits512: inout [UInt64], from startPos: Int, to endPos: Int) {
        assert(endPos >= Secpt256k1Scalar.wordBitWidth * Secpt256k1Scalar.wordWidth - 1)
        assert(startPos >= endPos)
        assert(bits512.count * Secpt256k1Scalar.wordBitWidth >= startPos)
        
        var bit = startPos
        while bit > endPos {
            let wordIdx = bit >> 6
            let wordBitIdx = bit & 0x3F
            let need2Clear = (bits512[wordIdx] & (1 << wordBitIdx)) >> wordBitIdx
            assert(need2Clear <= 1)
            
            guard need2Clear > 0 else {
                bit = Secpt256k1Scalar.wordBitWidth * wordIdx + Secpt256k1Scalar.wordBitWidth - bits512[wordIdx].leadingZeroBitCount - 1
                continue
            }
            
            let subStartBit = bit - Secpt256k1Scalar.wordWidth * Secpt256k1Scalar.wordBitWidth
            let shift = subStartBit & 0x3F
            var tmpdIdx = subStartBit >> 6
            var t : UInt64 = 0
            var overflow = false
            
            (bits512[tmpdIdx], overflow) = bits512[tmpdIdx].subtractingReportingOverflow((Secpt256k1Scalar.p[0] << shift))
            t += overflow ? 1 : 0
            tmpdIdx += 1
            
            for pIdx in 1..<Secpt256k1Scalar.wordWidth {
                (bits512[tmpdIdx], overflow) = bits512[tmpdIdx].subtractingReportingOverflow(t)
                t = overflow ? 1 : 0
                (bits512[tmpdIdx], overflow) = bits512[tmpdIdx].subtractingReportingOverflow(
                    (Secpt256k1Scalar.p[pIdx] << shift) | (Secpt256k1Scalar.p[pIdx - 1] >> (Secpt256k1Scalar.wordBitWidth - shift)))
                t += overflow ? 1 : 0
                tmpdIdx += 1
            }
            
            (bits512[tmpdIdx], overflow) = bits512[tmpdIdx].subtractingReportingOverflow(t)
            t = overflow ? 1 : 0
            (bits512[tmpdIdx], overflow) = bits512[tmpdIdx].subtractingReportingOverflow(
                Secpt256k1Scalar.p[Secpt256k1Scalar.wordWidth - 1] >> (Secpt256k1Scalar.wordBitWidth - shift))
            t += overflow ? 1 : 0
            
            assert(t == 0 || (wordBitIdx == 0 && wordIdx == tmpdIdx + 1))
            if t != 0 {
                bits512[wordIdx] -= t
            }
        }
    }
    
    private mutating func reduceByPcomp() {
        let reductionPerRun = Secpt256k1Scalar.pCompLeadingZeros
        let reduceFromSize = Secpt256k1Scalar.wordWidth * 2
        let reduceToSize = Secpt256k1Scalar.wordWidth
        let runs : Int = (reduceFromSize * Secpt256k1Scalar.wordBitWidth - reduceToSize * Secpt256k1Scalar.wordBitWidth + reductionPerRun - 1) / reductionPerRun
        
        //var tmpBits = [UInt64](repeating: 0, count: reduceFromSize - reduceToSize + Secpt256k1Scalar.pCompWordWidth)
        
        let mStart = reduceToSize
        let mEndAtStart = reduceFromSize - 1
        var mEnd = mEndAtStart
        
        for r in 0..<runs {
            let mSize = mEnd - mStart + 1
            let rSize = mSize + Secpt256k1Scalar.pCompWordWidth
            var t: UInt64 = 0
            var t2: UInt64 = 0
            var overflow = false
            
            for i in 0..<rSize {
                d[i] = 0
            }
            
            for i in 0..<mSize {
                for j in 0..<Secpt256k1Scalar.pCompWordWidth {
                    let k = i + j
                    (d[k], overflow) = d[k].addingReportingOverflow(t)
                    (t, t2) = (t2, 0)
                    t += overflow ? 1 : 0
                    let (mulValHi, mulValLo) = bits512[i + mStart].multipliedFullWidth(by: Secpt256k1Scalar.pComp[j])
                    (d[k], overflow) = d[k].addingReportingOverflow(mulValLo)
                    t += overflow ? 1 : 0
                    (t, overflow) = t.addingReportingOverflow(mulValHi)
                    t2 = overflow ? 1 : 0
                }
                assert(d[i + Secpt256k1Scalar.pCompWordWidth] == 0)
                d[i + Secpt256k1Scalar.pCompWordWidth] = t
                t = 0
                assert(t2 == 0)
            }
            assert(t == 0 && t2 == 0)
            
            for i in 0..<Secpt256k1Scalar.wordWidth {
                (bits512[i], overflow) = bits512[i].addingReportingOverflow(t)
                t = overflow ? 1 : 0
                (bits512[i], overflow) = bits512[i].addingReportingOverflow(d[i])
                t += overflow ? 1 : 0
            }
            
            for i in Secpt256k1Scalar.wordWidth..<rSize {
                (bits512[i], overflow) = d[i].addingReportingOverflow(t)
                t = overflow ? 1 : 0
            }
            assert(t == 0)
            
            mEnd = mEndAtStart - (reductionPerRun * (r + 1)) >> 6
        }
    }
    
    private mutating func mulArrays(_ x: [UInt64], _ y: [UInt64]) {
        for i in 0..<Secpt256k1Scalar.wordWidth*2 {
            bits512[i] = 0
        }
        var t : UInt64 = 0
        var t2: UInt64 = 0
        var overflow = false
        for i in 0..<Secpt256k1Scalar.wordWidth {
            for j in 0..<Secpt256k1Scalar.wordWidth {
                let k = i + j
                (bits512[k], overflow) = bits512[k].addingReportingOverflow(t)
                (t, t2) = (t2, 0)
                t += overflow ? 1 : 0
                let (mulValHi, mulValLo) = x[i].multipliedFullWidth(by: y[j])
                (bits512[k], overflow) = bits512[k].addingReportingOverflow(mulValLo)
                t += overflow ? 1 : 0
                (t, overflow) = t.addingReportingOverflow(mulValHi)
                t2 = overflow ? 1 : 0
            }
            assert(bits512[i + Secpt256k1Scalar.wordWidth] == 0)
            bits512[i + Secpt256k1Scalar.wordWidth] = t
            t = 0
            assert(t2 == 0)
        }
        assert(t == 0 && t2 == 0)
    }
    
    public mutating func mul(_ y : Secpt256k1Scalar) {
        mulInternal(y)
    }
    
    private mutating func mulInternal(_ y : Secpt256k1Scalar? = nil) {
        assert(!checkOverflow())
        assert(y == nil || !y!.checkOverflow())
        
        if let other = y {
            mulArrays(d, other.d)
        } else {
            mulArrays(d, d)
        }
        reduceByPcomp()
        d[0..<Secpt256k1Scalar.wordWidth] = bits512[0..<Secpt256k1Scalar.wordWidth]
        for i in Secpt256k1Scalar.wordWidth..<d.count {
            d[i] = 0
        }
        reduce()
    }
    
    public mutating func sqr() {
        mulInternal()
    }
    
    private mutating func inverseByPowers() {
        var powers = Secpt256k1Scalar(scalar: self)
        setInt(1)
        assert(isOne())
        
        for i in 0..<Secpt256k1Scalar.wordWidth {
            var bitMask: UInt64 = 1
            
            for _ in 0..<Secpt256k1Scalar.wordBitWidth {
                if Secpt256k1Scalar.pMinus2[i] & bitMask != 0 {
                    mul(powers)
                }
                powers.sqr()
                bitMask = bitMask << 1
            }
        }
    }
    
    private mutating func inverseBySegmentBuilding() {
        var segments = Secpt256k1Scalar.pMinus2MetaData.segments
        
        // Build required segments
        var seg = Secpt256k1Scalar(int: 1)
        var x = Secpt256k1Scalar(scalar: self)
        for i in 1..<Secpt256k1Scalar.pMinus2MetaData.maxSegmentLen+1 {
            seg.mul(x)
            if segments[i] != nil {
                segments[i] = Secpt256k1Scalar(scalar: seg)
            }
            x.sqr()
        }
        
        setInt(1)
        assert(isOne())
        
        // Append segments to build in self^P-2
        var lastSegStart = -1
        for segDef in Secpt256k1Scalar.pMinus2MetaData.segmentDefs.reversed() {
            if lastSegStart < segDef.end {// last segment
                lastSegStart = segDef.end
            }
            
            let segmentlen = segDef.end - segDef.start
            
            for _ in segDef.end..<lastSegStart + segmentlen {
                sqr() // append 0s for segment seperation
            }
            
            let segment = segments[segmentlen]!
            assert(!segment.isZero())
            mul(segment)
            lastSegStart = segDef.start
        }
        
        for _ in 0..<lastSegStart {
            sqr() // append prefix 0s
        }
    }
    
    public mutating func inverse() {
        inverseByPowers()
        reduce()
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

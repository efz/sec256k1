import Darwin
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
    
    public static let zero = Secpt256k1Scalar()
    public static let one = Secpt256k1Scalar(int: 1)
    
    public static var prime : Secpt256k1Scalar {
        return Secpt256k1Scalar(words64: p)
    }
    
    static let wordMask = UInt64.max
    
    public init() {
        d = [UInt64](repeating: 0, count: Secpt256k1Scalar.wordWidth * 4)
        bits512 = [UInt64](repeating: 0, count: Secpt256k1Scalar.wordWidth * 4)
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
    
    private mutating func reduceByPcomp() {
        let mStart = 4
        
        // round 1
        var acc = Accumulator(bits512[0])
        acc.mulAddFast(bits512[mStart], Secpt256k1Scalar.pComp[0])
        d[0] = acc.exractFast()
        acc.mulAddFast(bits512[mStart], Secpt256k1Scalar.pComp[1])
        acc.mulAddFast(bits512[mStart+1], Secpt256k1Scalar.pComp[0])
        acc.sumAdd(bits512[1])
        d[1] = acc.exract()
        acc.mulAdd(bits512[mStart], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(bits512[mStart+1], Secpt256k1Scalar.pComp[1])
        acc.mulAdd(bits512[mStart+2], Secpt256k1Scalar.pComp[0])
        acc.sumAdd(bits512[2])
        d[2] = acc.exract()
        acc.mulAdd(bits512[mStart+1], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(bits512[mStart+2], Secpt256k1Scalar.pComp[1])
        acc.mulAdd(bits512[mStart+3], Secpt256k1Scalar.pComp[0])
        acc.sumAdd(bits512[3])
        d[3] = acc.exract()
        acc.mulAdd(bits512[mStart+2], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(bits512[mStart+3], Secpt256k1Scalar.pComp[1])
        d[4] = acc.exract()
        acc.mulAdd(bits512[mStart+3], Secpt256k1Scalar.pComp[2])
        d[5] = acc.exractFast()
        d[6] = acc.exractFast()
        assert(acc.isZero())
        
        // round 2
        acc = Accumulator(d[0])
        acc.mulAddFast(d[mStart], Secpt256k1Scalar.pComp[0])
        bits512[0] = acc.exractFast()
        acc.mulAddFast(d[mStart], Secpt256k1Scalar.pComp[1])
        acc.mulAddFast(d[mStart+1], Secpt256k1Scalar.pComp[0])
        acc.sumAdd(d[1])
        bits512[1] = acc.exract()
        acc.mulAdd(d[mStart], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(d[mStart+1], Secpt256k1Scalar.pComp[1])
        acc.mulAdd(d[mStart+2], Secpt256k1Scalar.pComp[0])
        acc.sumAdd(d[2])
        bits512[2] = acc.exract()
        acc.mulAdd(d[mStart+1], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(d[mStart+2], Secpt256k1Scalar.pComp[1])
        acc.sumAdd(d[3])
        bits512[3] = acc.exract()
        acc.mulAddFast(d[mStart+2], Secpt256k1Scalar.pComp[2])
        bits512[4] = acc.exractFast()
        bits512[5] = acc.exractFast()
        assert(acc.isZero())
        
        // round 3
        acc = Accumulator(bits512[0])
        acc.mulAddFast(bits512[mStart], Secpt256k1Scalar.pComp[0])
        d[0] = acc.exractFast()
        acc.mulAddFast(bits512[mStart], Secpt256k1Scalar.pComp[1])
        acc.sumAdd(bits512[1])
        d[1] = acc.exractFast()
        acc.mulAddFast(bits512[mStart], Secpt256k1Scalar.pComp[2])
        acc.sumAdd(bits512[2])
        d[2] = acc.exractFast()
        acc.sumAddFast(bits512[3])
        d[3] = acc.exractFast()
        assert(acc.isZero())
    }
    
    private static func mulArraysFast(_ res: inout [UInt64], _ x: ArraySlice<UInt64>, _ y: ArraySlice<UInt64>) {
        var acc = Accumulator()
        
        acc.mulAddFast(x[x.startIndex + 0], y[y.startIndex + 0])
        res[0] = acc.exractFast()
        
        acc.mulAdd(x[x.startIndex + 0], y[y.startIndex + 1])
        acc.mulAdd(x[x.startIndex + 1], y[y.startIndex + 0])
        res[1] = acc.exract()
        
        acc.mulAdd(x[x.startIndex + 0], y[y.startIndex + 2])
        acc.mulAdd(x[x.startIndex + 2], y[y.startIndex + 0])
        acc.mulAdd(x[x.startIndex + 1], y[y.startIndex + 1])
        res[2] = acc.exract()
        
        acc.mulAdd(x[x.startIndex + 0], y[y.startIndex + 3])
        acc.mulAdd(x[x.startIndex + 3], y[y.startIndex + 0])
        acc.mulAdd(x[x.startIndex + 1], y[y.startIndex + 2])
        acc.mulAdd(x[x.startIndex + 2], y[y.startIndex + 1])
        res[3] = acc.exract()
        
        acc.mulAdd(x[x.startIndex + 1], y[y.startIndex + 3])
        acc.mulAdd(x[x.startIndex + 3], y[y.startIndex + 1])
        acc.mulAdd(x[x.startIndex + 2], y[y.startIndex + 2])
        res[4] = acc.exract()
        
        acc.mulAdd(x[x.startIndex + 2], y[y.startIndex + 3])
        acc.mulAdd(x[x.startIndex + 3], y[y.startIndex + 2])
        res[5] = acc.exract()
        
        acc.mulAddFast(x[x.startIndex + 3], y[y.startIndex + 3])
        res[6] = acc.exractFast()
        
        res[7] = acc.exractFast()
        
        assert(acc.exractFast() == 0)
    }
    
    private static func sqrArrayFast(_ res: inout [UInt64], _ x: ArraySlice<UInt64>) {
        var acc = Accumulator()
        
        acc.mulAddFast(x[x.startIndex + 0], x[x.startIndex + 0])
        res[0] = acc.exractFast()
        
        acc.mulAdd2(x[x.startIndex + 0], x[x.startIndex + 1])
        res[1] = acc.exract()
        
        acc.mulAdd2(x[x.startIndex + 0], x[x.startIndex + 2])
        acc.mulAdd(x[x.startIndex + 1], x[x.startIndex + 1])
        res[2] = acc.exract()
        
        acc.mulAdd2(x[x.startIndex + 0], x[x.startIndex + 3])
        acc.mulAdd2(x[x.startIndex + 1], x[x.startIndex + 2])
        res[3] = acc.exract()
        
        acc.mulAdd2(x[x.startIndex + 1], x[x.startIndex + 3])
        acc.mulAdd(x[x.startIndex + 2], x[x.startIndex + 2])
        res[4] = acc.exract()
        
        acc.mulAdd2(x[x.startIndex + 2], x[x.startIndex + 3])
        res[5] = acc.exract()
        
        acc.mulAddFast(x[x.startIndex + 3], x[x.startIndex + 3])
        res[6] = acc.exractFast()
        
        res[7] = acc.exractFast()
        
        assert(acc.exractFast() == 0)
    }
    
    private static func mulArrays(_ res: inout [UInt64], _ x: ArraySlice<UInt64>, _ y: ArraySlice<UInt64>) {
        for i in 0..<x.count+y.count {
            res[i] = 0
        }
        var t : UInt64 = 0
        var t2: UInt64 = 0
        var overflow = false
        for i in x.startIndex..<x.endIndex {
            for j in y.startIndex..<y.endIndex {
                let k = i + j - x.startIndex - y.startIndex
                (res[k], overflow) = res[k].addingReportingOverflow(t)
                (t, t2) = (t2, 0)
                t += overflow ? 1 : 0
                let (mulValHi, mulValLo) = x[i].multipliedFullWidth(by: y[j])
                (res[k], overflow) = res[k].addingReportingOverflow(mulValLo)
                t += overflow ? 1 : 0
                (t, overflow) = t.addingReportingOverflow(mulValHi)
                t2 = overflow ? 1 : 0
            }
            assert(res[i - x.startIndex + y.count] == 0)
            res[i - x.startIndex + y.count] = t
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
            Secpt256k1Scalar.mulArraysFast(&bits512, d[0..<Secpt256k1Scalar.wordWidth], other.d[0..<Secpt256k1Scalar.wordWidth])
        } else {
            Secpt256k1Scalar.sqrArrayFast(&bits512, d[0..<Secpt256k1Scalar.wordWidth])
        }
        reduceByPcomp()
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

private struct Accumulator {
    var c0, c1, c2: UInt64
    
    init() {
        (c0, c1, c2) = (0, 0, 0)
    }
    
    init(_ val: UInt64) {
        (c0, c1, c2) = (val, 0, 0)
    }
    
    mutating func mulAddFast(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        c1 += hi
    }
    
    mutating func mulAdd(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c1, overflow) = c1.addingReportingOverflow(hi)
        c2 += overflow ? 1 : 0
    }
    
    mutating func mulAdd2(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        var hiCopy = hi
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c1, overflow) = c1.addingReportingOverflow(hi)
        c2 += overflow ? 1 : 0
        
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hiCopy += overflow ? 1 : 0
        (c1, overflow) = c1.addingReportingOverflow(hiCopy)
        c2 += overflow ? 1 : 0
    }
    
    mutating func sumAdd(_ x: UInt64) {
        var overflow = false
        (c0, overflow) = c0.addingReportingOverflow(x)
        (c1, overflow) = c1.addingReportingOverflow(overflow ? 1 : 0)
        c2 += overflow ? 1 : 0
    }
    
    mutating func sumAddFast(_ x: UInt64) {
        var overflow = false
        (c0, overflow) = c0.addingReportingOverflow(x)
        c1 += overflow ? 1 : 0
        assert(c2 == 0)
    }
    
    mutating func exractFast() -> UInt64 {
        defer {
            (c0, c1) = (c1, 0)
            assert(c2 == 0)
        }
        return c0
    }
    
    mutating func exract() -> UInt64 {
        defer {
            (c0, c1, c2) = (c1, c2, 0)
        }
        return c0
    }
    
    func isZero() -> Bool {
        return (c0, c1, c2) == (0, 0, 0)
    }
}

public struct Secpt256k1Scalar {
    typealias Bits64x3 = (UInt64, UInt64, UInt64)
    typealias Bits64x4 = (UInt64, UInt64, UInt64, UInt64)
    typealias Bits64x5 = (UInt64, UInt64, UInt64, UInt64, UInt64)
    typealias Bits64x7 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
    typealias Bits64x8 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
    
    private var d: Bits64x4
    private var acc: Accumulator
    
    private func getWord(_ idx: Int) throws -> UInt64 {
        switch idx {
        case 0:
            return d.0
        case 1:
            return d.1
        case 2:
            return d.2
        case 3:
            return d.3
        default:
            fatalError("invalid index \(idx)")
        }
    }
    
    static let wordWidth = 4
    static let pCompWordWidth = 3
    static let wordBitWidth = UInt64.bitWidth
    
    static let p : Bits64x4 = (0xBFD25E8CD0364141, 0xBAAEDCE6AF48A03B, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF)
    static let pMinus2 : Bits64x4 = (0xBFD25E8CD036413F, 0xBAAEDCE6AF48A03B, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF)
    static let pComp: Bits64x3 = (~p.0 + 1, ~p.1, ~p.2)
    static let pCompLeadingZeros = 127
    
    public static let zero = Secpt256k1Scalar()
    public static let one = Secpt256k1Scalar(int: 1)
    
    public static var prime : Secpt256k1Scalar {
        return Secpt256k1Scalar(bits64x4: p)
    }
    
    static let wordMask = UInt64.max
    
    public init() {
        d = (0, 0, 0, 0)
        acc = Accumulator()
    }
    
    public init(words : [UInt32]) {
        self.init()
        d.0 = UInt64(words[1]) << UInt32.bitWidth | UInt64(words[0])
        d.1 = UInt64(words[2 * 1 + 1]) << UInt32.bitWidth | UInt64(words[2*1])
        d.2 = UInt64(words[2 * 2 + 1]) << UInt32.bitWidth | UInt64(words[2*2])
        d.3 = UInt64(words[2 * 3 + 1]) << UInt32.bitWidth | UInt64(words[2*3])
        reduce()
    }
    
    init(bits64x4 : Bits64x4) {
        self.init()
        d.0 = bits64x4.0
        d.1 = bits64x4.1
        d.2 = bits64x4.2
        d.3 = bits64x4.3
        reduce()
    }
    
    public init(words64 : [UInt64]) {
        self.init()
        d.0 = words64[0]
        d.1 = words64[1]
        d.2 = words64[2]
        d.3 = words64[3]
        reduce()
    }
    
    public init(bytes : [UInt8]) {
        self.init()
        for i in 0..<bytes.count {
            let wordIdx = 3 - i / 8
            let byteIdx = 7 - i % 8
            let val = UInt64(bytes[i]) << (byteIdx * 8)
            switch wordIdx {
            case 0:
                d.0 |= val
            case 1:
                d.1 |= val
            case 2:
                d.2 |= val
            case 3:
                d.3 |= val
            default:
                fatalError("invalid index \(wordIdx)")
            }
        }
        reduce()
    }
    
    public init(int v : UInt32) {
        self.init()
        d.0 = UInt64(v)
    }
    
    public init(int64 v : UInt64) {
        self.init()
        d.0 = v
    }
    
    public init(scalar  s: Secpt256k1Scalar) {
        self.init()
        d.0 = s.d.0
        d.1 = s.d.1
        d.2 = s.d.2
        d.3 = s.d.3
        reduce()
    }
    
    mutating func setInt(_ v: UInt64) {
        d.0 = v
        d.1 = 0
        d.2 = 0
        d.3 = 0
    }
    
    public func checkOverflow() -> Bool {
        var strictOverflow = false
        var equals = true
        
        strictOverflow = d.3 > Secpt256k1Scalar.p.3
        equals = d.3 == Secpt256k1Scalar.p.3
        
        strictOverflow = (d.2 > Secpt256k1Scalar.p.2 && equals) || strictOverflow
        equals = d.2 == Secpt256k1Scalar.p.2 && equals
        
        strictOverflow = (d.1 > Secpt256k1Scalar.p.1 && equals) || strictOverflow
        equals = d.1 == Secpt256k1Scalar.p.1 && equals
        
        strictOverflow = (d.0 > Secpt256k1Scalar.p.0 && equals) || strictOverflow
        equals = d.0 == Secpt256k1Scalar.p.0 && equals
        
        return strictOverflow || equals
    }
    
    mutating func reduce(overflow : UInt64 = 0) {
        assert(overflow <= 1)
        
        var reduced: Bits64x4 = (0, 0, 0, 0)
        var t : UInt64 = 0
        var carry = false
        
        (reduced.0, carry) = d.0.subtractingReportingOverflow(Secpt256k1Scalar.p.0)
        t += carry ? 1 : 0
        
        (reduced.1, carry) = d.1.subtractingReportingOverflow(t)
        t = carry ? 1 : 0
        (reduced.1, carry) = reduced.1.subtractingReportingOverflow(Secpt256k1Scalar.p.1)
        t += carry ? 1 : 0
        
        (reduced.2, carry) = d.2.subtractingReportingOverflow(t)
        t = carry ? 1 : 0
        (reduced.2, carry) = reduced.2.subtractingReportingOverflow(Secpt256k1Scalar.p.2)
        t += carry ? 1 : 0
        
        (reduced.3, carry) = d.3.subtractingReportingOverflow(t)
        t = carry ? 1 : 0
        (reduced.3, carry) = reduced.3.subtractingReportingOverflow(Secpt256k1Scalar.p.3)
        t += carry ? 1 : 0
        
        assert(t <= 1)
        
        if overflow > 0 || t == 0 {
            d = reduced
        }
    }
    
    public mutating func add(_ y : Secpt256k1Scalar, carry: UInt64 = 0) {
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        var t : UInt64 = carry
        var overflow = false
        
        (d.0, overflow) = d.0.addingReportingOverflow(y.d.0)
        t += overflow ? 1 : 0
        
        (d.1, overflow) = d.1.addingReportingOverflow(t)
        t = overflow ? 1 : 0
        (d.1, overflow) = d.1.addingReportingOverflow(y.d.1)
        t += overflow ? 1 : 0
        
        (d.2, overflow) = d.2.addingReportingOverflow(t)
        t = overflow ? 1 : 0
        (d.2, overflow) = d.2.addingReportingOverflow(y.d.2)
        t += overflow ? 1 : 0
        
        (d.3, overflow) = d.3.addingReportingOverflow(t)
        t = overflow ? 1 : 0
        (d.3, overflow) = d.3.addingReportingOverflow(y.d.3)
        t += overflow ? 1 : 0
        
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
        return d.0 | d.1 | d.2 | d.3 == 0
    }
    
    public func isOne() -> Bool {
        return d.0 == 1 && d.1 | d.2 | d.3 == 0
    }
    
    public func isEven() -> Bool {
        return d.0 & 1 == 0
    }
    
    public func getBits64(offset : Int, count : Int) throws -> UInt64 {
        assert(offset + count <= Secpt256k1Scalar.wordBitWidth * Secpt256k1Scalar.wordWidth)
        assert(count < Secpt256k1Scalar.wordBitWidth)
        if offset >> 6 == (count + offset - 1) >> 6 {
            return UInt64((try getWord(offset >> 6) >> (offset & 0x3F)) & ((1 << count) - 1))
        } else {
            assert((offset >> 6) + 1 < 4)
            let firstHalf = UInt64(try getWord(offset >> 6) >> (offset & 0x3F))
            let secondHalf = UInt64((try getWord((offset >> 6) + 1) << (64 - (offset & 0x3F)) & Secpt256k1Scalar.wordMask))
            return (firstHalf | secondHalf) & ((1 << count) - 1)
        }
    }
    
    public func getBits(offset : Int, count : Int) throws -> UInt32 {
        assert(count < UInt32.bitWidth)
        return UInt32(try getBits64(offset: offset, count: count))
    }
    
    public mutating func clear() {
        d = (0, 0, 0, 0)
    }
    
    public mutating func negate() {
        assert(!checkOverflow())
        guard !isZero() else {
            return
        }
        assert(Secpt256k1Scalar.p.0 != 0 && Secpt256k1Scalar.p.1 != 0 && Secpt256k1Scalar.p.2 != 0 && Secpt256k1Scalar.p.3 != 0)
        var t : UInt64 = 0
        var overflow = false
        
        (d.0, overflow) = Secpt256k1Scalar.p.0.subtractingReportingOverflow(d.0)
        t = overflow ? 1 : 0
        
        t = Secpt256k1Scalar.p.1 - t
        (d.1, overflow) = t.subtractingReportingOverflow(d.1)
        t = overflow ? 1 : 0
        
        t = Secpt256k1Scalar.p.2 - t
        (d.2, overflow) = t.subtractingReportingOverflow(d.2)
        t = overflow ? 1 : 0
        
        t = Secpt256k1Scalar.p.3 - t
        (d.3, overflow) = t.subtractingReportingOverflow(d.3)
        
        assert(!overflow)
    }
    
    public static func substract(_ x : Secpt256k1Scalar, _ y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        var r1 = Secpt256k1Scalar.init(scalar: x)
        var r2 = Secpt256k1Scalar.init(scalar: y)
        r2.negate()
        r1.add(r2)
        return r1
    }
    
    public static func -(x : Secpt256k1Scalar, y : Secpt256k1Scalar) -> Secpt256k1Scalar {
        return Secpt256k1Scalar.substract(x, y)
    }
    
    private mutating func reduceByPcomp(_ bits512: Bits64x8) {
        assert(Secpt256k1Scalar.pComp.2 == 1)
        
        var bits448: Bits64x7 = (0, 0, 0, 0, 0, 0, 0)
        // round 1
        bits448.0 = bits512.0
        bits448.1 = bits512.1
        
        acc.reset(bits512.2)
        
        acc.mulAddFast(bits512.6, Secpt256k1Scalar.pComp.0)
        bits448.2 = acc.extractFast()
        acc.mulAddFast(bits512.6, Secpt256k1Scalar.pComp.1)
        acc.mulAdd(bits512.7, Secpt256k1Scalar.pComp.0)
        acc.sumAdd(bits512.3)
        bits448.3 = acc.extract()
        acc.sumAdd(bits512.6) // acc.mulAdd(bits512[mStart], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(bits512.7, Secpt256k1Scalar.pComp.1)
        acc.sumAdd(bits512.4)
        bits448.4 = acc.extract()
        acc.sumAdd(bits512.7) //acc.mulAdd(bits512[mStart+1], Secpt256k1Scalar.pComp[2])
        acc.sumAdd(bits512.5)
        bits448.5 = acc.extract()
        bits448.6 = acc.extractFast()
        assert(acc.isZero())
        
        var bits320: Bits64x5 = (0, 0, 0, 0, 0)
        // round 2
        bits320.0 = bits448.0
        
        acc.reset(bits448.1)
        acc.mulAddFast(bits448.5, Secpt256k1Scalar.pComp.0)
        bits320.1 = acc.extractFast()
        acc.mulAddFast(bits448.5, Secpt256k1Scalar.pComp.1)
        acc.mulAdd(bits448.6, Secpt256k1Scalar.pComp.0)
        acc.sumAdd(bits448.2)
        bits320.2 = acc.extract()
        acc.sumAdd(bits448.5) //acc.mulAdd(d[mStart], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(bits448.6, Secpt256k1Scalar.pComp.1)
        acc.sumAdd(bits448.3)
        bits320.3 = acc.extract()
        acc.sumAdd(bits448.6) //acc.mulAdd(d[mStart+1], Secpt256k1Scalar.pComp[2])
        acc.sumAdd(bits448.4)
        bits320.4 = acc.extractFast()
        assert(acc.isZero())
        
        // round 3
        acc.reset(bits320.0)
        acc.mulAddFast(bits320.4, Secpt256k1Scalar.pComp.0)
        d.0 = acc.extractFast()
        acc.mulAddFast(bits320.4, Secpt256k1Scalar.pComp.1)
        acc.sumAdd(bits320.1)
        d.1 = acc.extract()
        acc.sumAdd(bits320.4) // acc.mulAddFast(bits512[mStart], Secpt256k1Scalar.pComp[2])
        acc.sumAdd(bits320.2)
        d.2 = acc.extract()
        acc.sumAdd(bits320.3)
        d.3 = acc.extractFast()
        
        let overflow = acc.extractFast()
        assert(overflow <= 1)
        assert(acc.isZero())
        reduce(overflow: overflow)
    }
    
    private mutating func mulArraysFast(_ x: Bits64x4, _ y: Bits64x4) -> Bits64x8 {
        acc.reset(0)
        var res: Bits64x8 = (0, 0, 0, 0, 0, 0, 0, 0)
        
        acc.mulAddFast(x.0, y.0)
        res.0 = acc.extractFast()
        
        acc.mulAdd(x.0, y.1)
        acc.mulAdd(x.1, y.0)
        res.1 = acc.extract()
        
        acc.mulAdd(x.0, y.2)
        acc.mulAdd(x.2, y.0)
        acc.mulAdd(x.1, y.1)
        res.2 = acc.extract()
        
        acc.mulAdd(x.0, y.3)
        acc.mulAdd(x.3, y.0)
        acc.mulAdd(x.1, y.2)
        acc.mulAdd(x.2, y.1)
        res.3 = acc.extract()
        
        acc.mulAdd(x.1, y.3)
        acc.mulAdd(x.3, y.1)
        acc.mulAdd(x.2, y.2)
        res.4 = acc.extract()
        
        acc.mulAdd(x.2, y.3)
        acc.mulAdd(x.3, y.2)
        res.5 = acc.extract()
        
        acc.mulAddFast(x.3, y.3)
        res.6 = acc.extractFast()
        res.7 = acc.extractFast()
        
        assert(acc.extractFast() == 0)
        
        return res
    }
    
    private mutating func sqrArrayFast(_ x: Bits64x4) -> Bits64x8 {
        acc.reset(0)
        var res: Bits64x8 = (0, 0, 0, 0, 0, 0, 0, 0)
        
        acc.mulAddFast(x.0, x.0)
        res.0 = acc.extractFast()
        
        acc.mulAdd2(x.0, x.1)
        res.1 = acc.extract()
        
        acc.mulAdd2(x.0, x.2)
        acc.mulAdd(x.1, x.1)
        res.2 = acc.extract()
        
        acc.mulAdd2(x.0, x.3)
        acc.mulAdd2(x.1, x.2)
        res.3 = acc.extract()
        
        acc.mulAdd2(x.1, x.3)
        acc.mulAdd(x.2, x.2)
        res.4 = acc.extract()
        
        acc.mulAdd2(x.2, x.3)
        res.5 = acc.extract()
        
        acc.mulAddFast(x.3, x.3)
        res.6 = acc.extractFast()
        
        res.7 = acc.extractFast()
        
        assert(acc.extractFast() == 0)
        return res
    }
    
    public mutating func mul(_ y : Secpt256k1Scalar) {
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        mulInternal(y)
    }
    
    private mutating func mulInternal(_ y : Secpt256k1Scalar? = nil) {
        let bits512: Bits64x8
        
        if let other = y {
            bits512 = mulArraysFast(d, other.d)
        } else {
            bits512 = sqrArrayFast(d)
        }
        reduceByPcomp(bits512)
    }
    
    public mutating func sqr() {
        assert(!checkOverflow())
        
        mulInternal()
    }
    
    private mutating func inverseByPowers() {
        let shiftNumMul = { (shift: Int, num: Secpt256k1Scalar, prev: Secpt256k1Scalar) -> Secpt256k1Scalar in
            var shiftedNum = num
            for _ in 0..<shift {
                shiftedNum.mulInternal()
            }
            shiftedNum.mulInternal(prev)
            return shiftedNum
        }
        
        let x1 = Secpt256k1Scalar(scalar: self)
        setInt(1)
        assert(isOne())
        
        let x2 = shiftNumMul(1, x1, x1)
        let x4 = shiftNumMul(2, x2, x2)
        let x8 = shiftNumMul(4, x4, x4)
        let x16 = shiftNumMul(8, x8, x8)
        let x32 = shiftNumMul(16, x16, x16)
        let x64 = shiftNumMul(32, x32,  x32)
        let x96 = shiftNumMul(32, x64, x32)
        let x112 = shiftNumMul(16, x96, x16)
        let x120 = shiftNumMul(8, x112, x8)
        let x124 = shiftNumMul(4, x120, x4)
        
        var x3 = x2
        x3.mulInternal()
        x3.mulInternal(x1)
        
        let x127 = shiftNumMul(3, x124, x3)
        
        ///
        mulInternal(x127)
        mulInternal()
        
        // 1011,1010,1010,1110,1101,1100,1110,0110,1010,1111,0100,1000,1010,0000,0011,1011
        shiftMul(1, x1)
        shiftMul(4, x3)
        shiftMul(2, x1)
        shiftMul(2, x1)
        shiftMul(2, x1)
        shiftMul(4, x3)
        shiftMul(3, x2)
        shiftMul(4, x3)
        shiftMul(5, x3)
        shiftMul(4, x2)
        shiftMul(2, x1)
        shiftMul(2, x1)
        shiftMul(5, x4)
        shiftMul(2, x1)
        shiftMul(3, x1)
        shiftMul(4, x1)
        shiftMul(2, x1)
        shiftMul(10,x3)
        
        //shiftMul(3, x2)
        // 1011,1111,1101,0010,0101,1110,1000,1100,1101,0000,0011,0110,0100,0001,0011,1111
        shiftMul(4, x3)
        
        shiftMul(9, x8)
        shiftMul(2, x1)
        shiftMul(3, x1)
        shiftMul(3, x1)
        shiftMul(5, x4)
        shiftMul(2, x1)
        shiftMul(5, x2)
        shiftMul(4, x2)
        shiftMul(2, x1)
        shiftMul(8, x2)
        shiftMul(3, x2)
        shiftMul(3, x1)
        shiftMul(6, x1)
        shiftMul(5, x3)
        shiftMul(3, x3)
    }
    
    private mutating func shiftMul(_ count: Int, _ x: Secpt256k1Scalar) {
        for _ in 0..<count {
            mulInternal()
        }
        mulInternal(x)
    }
    
    private mutating func shift(_ count: Int) {
        for _ in 0..<count {
            self.mulInternal()
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
    
    mutating func reset (_ val: UInt64) {
        (c0, c1, c2) = (val, 0, 0)
    }
    
    mutating func mulAddFast(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        c1 += hi
        assert(c2 == 0)
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
    
    mutating func extractFast() -> UInt64 {
        defer {
            (c0, c1) = (c1, 0)
            assert(c2 == 0)
        }
        return c0
    }
    
    mutating func extract() -> UInt64 {
        defer {
            (c0, c1, c2) = (c1, c2, 0)
        }
        return c0
    }
    
    func isZero() -> Bool {
        return (c0, c1, c2) == (0, 0, 0)
    }
}

public struct Secpt256k1Field {
    typealias Bits64x2 = (UInt64, UInt64)
    typealias Bits64x3 = (UInt64, UInt64, UInt64)
    typealias Bits64x4 = (UInt64, UInt64, UInt64, UInt64)
    typealias Bits64x5 = (UInt64, UInt64, UInt64, UInt64, UInt64)
    typealias Bits64x6 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
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
    static let wordBitWidth = UInt64.bitWidth
    
    static let p : Bits64x4 = (0xFFFFFFFEFFFFFC2F, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF)
    static let pMinus2 : Bits64x4 = (p.0 - 2, p.1, p.2, p.3)
    //(0xFFFFFFFEFFFFFC2D, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF)
    static let pComp: Bits64x4 = (~p.0 + 1, ~p.1, ~p.2, ~p.3)
    static let pPlus1Div4: Bits64x4 = (0xFFFFFFFFBFFFFF0C, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFF3)
    static let pCompLeadingZeros = 223
    static let pCompWordWidth = 1
    
    public static let zero = Secpt256k1Field()
    public static let one = Secpt256k1Field(int: 1)
    
    public static var prime : Secpt256k1Field {
        return Secpt256k1Field(bits64x4: p)
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
    
    public init(field s: Secpt256k1Field) {
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
        var accC = Accumulator(d.0)
        accC.sumAddFast(Secpt256k1Field.pComp.0)
        let _ = accC.extractFast()
        accC.sumAddFast(d.1)
        let _ = accC.extractFast()
        accC.sumAddFast(d.2)
        let _ = accC.extractFast()
        accC.sumAddFast(d.3)
        let _ = accC.extractFast()
        
        let overflow = accC.extractFast()
        assert(accC.isZero())
        assert(overflow <= 1)
        return overflow != 0
    }
    
    mutating func reduce(overflow : UInt64 = 0) {
        assert(overflow <= 1)
        
        var reduced: Bits64x4 = (0, 0, 0, 0)
        
        acc.reset(d.0)
        acc.sumAddFast(Secpt256k1Field.pComp.0)
        reduced.0 = acc.extractFast()
        acc.sumAddFast(d.1)
        reduced.1 = acc.extractFast()
        acc.sumAddFast(d.2)
        reduced.2 = acc.extractFast()
        acc.sumAddFast(d.3)
        reduced.3 = acc.extractFast()
        
        let carry = acc.extractFast()
        assert(carry <= 1)
        assert(acc.isZero())
        
        if overflow > 0 || carry == 1 {
            d = reduced
        }
    }
    
    public mutating func add(_ y : Secpt256k1Field, carry: UInt64 = 0) {
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        acc.reset(d.0)
        acc.sumAddFast(y.d.0)
        d.0 = acc.extractFast()
        acc.sumAddFast(d.1)
        acc.sumAddFast(y.d.1)
        d.1 = acc.extractFast()
        acc.sumAddFast(d.2)
        acc.sumAddFast(y.d.2)
        d.2 = acc.extractFast()
        acc.sumAddFast(d.3)
        acc.sumAddFast(y.d.3)
        d.3 = acc.extractFast()
        
        let overflow = acc.extractFast()
        assert(acc.isZero())
        
        assert(overflow <= 1)
        reduce(overflow: overflow)
    }
    
    public static func add(_ x : Secpt256k1Field, _ y : Secpt256k1Field) -> Secpt256k1Field {
        var r = Secpt256k1Field.init(field: x)
        r.add(y)
        return r
    }
    
    public static func +(x : Secpt256k1Field, y : Secpt256k1Field) -> Secpt256k1Field {
        return Secpt256k1Field.add(x, y)
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
        assert(offset + count <= Secpt256k1Field.wordBitWidth * Secpt256k1Field.wordWidth)
        assert(count < Secpt256k1Field.wordBitWidth)
        if offset >> 6 == (count + offset - 1) >> 6 {
            return UInt64((try getWord(offset >> 6) >> (offset & 0x3F)) & ((1 << count) - 1))
        } else {
            assert((offset >> 6) + 1 < 4)
            let firstHalf = UInt64(try getWord(offset >> 6) >> (offset & 0x3F))
            let secondHalf = UInt64((try getWord((offset >> 6) + 1) << (64 - (offset & 0x3F)) & Secpt256k1Field.wordMask))
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
        assert(Secpt256k1Field.p.0 != 0 && Secpt256k1Field.p.1 != 0 && Secpt256k1Field.p.2 != 0 && Secpt256k1Field.p.3 != 0)
        var t : UInt64 = 0
        var overflow = false
        
        (d.0, overflow) = Secpt256k1Field.p.0.subtractingReportingOverflow(d.0)
        t = overflow ? 1 : 0
        
        t = Secpt256k1Field.p.1 - t
        (d.1, overflow) = t.subtractingReportingOverflow(d.1)
        t = overflow ? 1 : 0
        
        t = Secpt256k1Field.p.2 - t
        (d.2, overflow) = t.subtractingReportingOverflow(d.2)
        t = overflow ? 1 : 0
        
        t = Secpt256k1Field.p.3 - t
        (d.3, overflow) = t.subtractingReportingOverflow(d.3)
        
        assert(!overflow)
    }
    
    public static func substract(_ x : Secpt256k1Field, _ y : Secpt256k1Field) -> Secpt256k1Field {
        var r1 = Secpt256k1Field.init(field: x)
        var r2 = Secpt256k1Field.init(field: y)
        r2.negate()
        r1.add(r2)
        return r1
    }
    
    public static func -(x : Secpt256k1Field, y : Secpt256k1Field) -> Secpt256k1Field {
        return Secpt256k1Field.substract(x, y)
    }
    
    private mutating func reduceByPcomp(_ bits512: Bits64x8) {
        var bits384: Bits64x6 = (0, 0, 0, 0, 0, 0)
        // round 1
        bits384.0 = bits512.0
        
        acc.reset(bits512.1)
        acc.mulAddFast(bits512.5, Secpt256k1Field.pComp.0)
        bits384.1 = acc.extractFast()
        acc.mulAddFast(bits512.6, Secpt256k1Field.pComp.0)
        acc.sumAddFast(bits512.2)
        bits384.2 = acc.extractFast()
        acc.mulAddFast(bits512.7, Secpt256k1Field.pComp.0)
        acc.sumAddFast(bits512.3)
        bits384.3 = acc.extractFast()
        acc.sumAddFast(bits512.4)
        bits384.4 = acc.extractFast()
        bits384.5 = acc.extractFast()
        assert(acc.isZero())
        
        // round 2
        acc.reset(bits384.0)
        acc.mulAddFast(bits384.4, Secpt256k1Field.pComp.0)
        d.0 = acc.extractFast()
        acc.mulAddFast(bits384.5, Secpt256k1Field.pComp.0)
        acc.sumAddFast(bits384.1)
        d.1 = acc.extractFast()
        acc.sumAddFast(bits384.2)
        d.2 = acc.extractFast()
        acc.sumAddFast(bits384.3)
        d.3 = acc.extractFast()
        
        let overflow = acc.extractFast()
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
    
    public mutating func mul(_ y : Secpt256k1Field) {
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        mulInternal(y)
    }
    
    private mutating func mulInternal(_ y : Secpt256k1Field? = nil) {
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
        let shiftNumMul = { (shift: Int, num: Secpt256k1Field, prev: Secpt256k1Field) -> Secpt256k1Field in
            var shiftedNum = num
            for _ in 0..<shift {
                shiftedNum.mulInternal()
            }
            shiftedNum.mulInternal(prev)
            return shiftedNum
        }
        
        let x1 = Secpt256k1Field(field: self)
        setInt(1)
        assert(isOne())
        
        let x2 = shiftNumMul(1, x1, x1)
        let x4 = shiftNumMul(2, x2, x2)
        let x8 = shiftNumMul(4, x4, x4)
        let x16 = shiftNumMul(8, x8, x8)
        
        var x22 = x16
        x22.shiftMul(4, x4)
        x22.shiftMul(2, x2)
        
        let x44 = shiftNumMul(22, x22, x22)
        let x88 = shiftNumMul(44, x44, x44)
        let x176 = shiftNumMul(88, x88, x88)
        let x220 = shiftNumMul(44, x176, x44)
        let x222 = shiftNumMul(2, x220, x2)
        let x223 = shiftNumMul(1, x222, x1)
        
        ///
        mulInternal(x223)
        mulInternal()
        
        // 1111,1111,1111,1111,1111,1100,0010,1101
        shiftMul(22, x22)
        shiftMul(5, x1)
        shiftMul(3, x2)
        shiftMul(2, x1)
    }
    
    public mutating func sqrt() {
        assert(!checkOverflow())
        
        let initalVal = self
        
        sqrtByPowers()
        reduce()
        
        var x = self
        x.sqr()
        if x == initalVal {
            return
        }
        negate()
        assert({() -> Bool in
            var y = self
            y.sqr()
            return y == initalVal
        }())
    }
    
    private mutating func sqrtByPowers() {
        let shiftNumMul = { (shift: Int, num: Secpt256k1Field, prev: Secpt256k1Field) -> Secpt256k1Field in
            var shiftedNum = num
            for _ in 0..<shift {
                shiftedNum.mulInternal()
            }
            shiftedNum.mulInternal(prev)
            return shiftedNum
        }
        
        let x1 = Secpt256k1Field(field: self)
        setInt(1)
        assert(isOne())
        
        let x2 = shiftNumMul(1, x1, x1)
        let x4 = shiftNumMul(2, x2, x2)
        let x8 = shiftNumMul(4, x4, x4)
        let x16 = shiftNumMul(8, x8, x8)
        
        var x22 = x16
        x22.shiftMul(4, x4)
        x22.shiftMul(2, x2)
        
        let x44 = shiftNumMul(22, x22, x22)
        let x88 = shiftNumMul(44, x44, x44)
        let x176 = shiftNumMul(88, x88, x88)
        let x220 = shiftNumMul(44, x176, x44)
        let x222 = shiftNumMul(2, x220, x2)
        let x223 = shiftNumMul(1, x222, x1)
        
        ///
        mulInternal(x223)
        mulInternal()
        
        // ...1111,1011,1111,1111,1111,1111,1111,0000,1100
        shiftMul(22, x22)
        shiftMul(6, x2)
        shift(2)
    }
    
    private mutating func shiftMul(_ count: Int, _ x: Secpt256k1Field) {
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
    
    public static func mul(x : Secpt256k1Field, y : Secpt256k1Field) -> Secpt256k1Field {
        var r = x
        r.mul(y)
        return r
    }
    
    public static func *(x : Secpt256k1Field, y : Secpt256k1Field) -> Secpt256k1Field {
        return Secpt256k1Field.mul(x: x, y: y)
    }
}

extension Secpt256k1Field: Equatable {
    public static func == (lhs: Secpt256k1Field, rhs: Secpt256k1Field) -> Bool {
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


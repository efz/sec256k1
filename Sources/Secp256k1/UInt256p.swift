typealias Bits64x2 = (UInt64, UInt64)
typealias Bits64x3 = (UInt64, UInt64, UInt64)
typealias Bits64x4 = (UInt64, UInt64, UInt64, UInt64)
typealias Bits64x5 = (UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x6 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x7 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x8 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x9 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)

public protocol UInt256pInterface {
    init()
    init(words32: [UInt32], overflowed: inout Bool)
    init(words64: [UInt64], overflowed: inout Bool)
    init(bytes: [UInt8], overflowed: inout Bool)
    init(bytes: ArraySlice<UInt8>, overflowed: inout Bool)
    init(int32 v: UInt32)
    init(int64 v: UInt64)
    init(int v: Int)
    
    func serialize(bytes: inout ArraySlice<UInt8>)
    
    func getBits64(offset: Int, count: Int) -> UInt64
    func getBits(offset: Int, count: Int) -> Int
    func isZero() -> Bool
    func isOne() -> Bool
    func isEven() -> Bool
    mutating func clear()
    
    mutating func sqr()
    mutating func negate()
    mutating func inverse()
    mutating func mul(_ y: Self)
    mutating func add(_ y: Self)
    mutating func add(_ y: Self, carry: UInt64)
    mutating func div(_ y: Self)
    mutating func sub(_ y: Self)
    
    static func *(_ x: Self, _ y: Self) -> Self
    static func +(_ x : Self,_ y : Self) -> Self
    static func -(_ x: Self, _ y: Self) -> Self
    static func /(_ x : Self,_ y : Self) -> Self
    static func neg(_ x: Self) -> Self
    static func sqr(_ x: Self) -> Self
    static func inv(_ x: Self) -> Self
}

protocol UInt256p: UInt256pInterface, Equatable {
    static var p: Bits64x4 { get }
    static var wordWidth: Int { get }
    static var wordBitWidth: Int { get }
    static var wordMask: UInt64 { get }
    var d: Bits64x4 { get set }
    var acc: Accumulator { get set }
    init(bits64x4: Bits64x4, overflowed: inout Bool)
    init(words64: [UInt64])
    
    func checkOverflow() -> Bool
    mutating func reduce(overflow: UInt64)
    mutating func reduce()
    func getWord(_ idx: Int) -> UInt64
    mutating func setInt(_ v: UInt64)
    
    mutating func mulArrays(_ x: Bits64x4, _ y: Bits64x4) -> Bits64x8
    mutating func sqrArray(_ x: Bits64x4) -> Bits64x8
    mutating func shift(_ count: Int)
    mutating func reduce512Bits(_ bits512: Bits64x8)
    mutating func shiftMul(_ count: Int, _ x: Self)
    mutating func shiftNumMul(_ shift: Int, _ num: Self, _ prev: Self) -> Self
}

extension UInt256p {
    public init(words32: [UInt32], overflowed: inout Bool) {
        self.init()
        d.0 = UInt64(words32[1]) << UInt32.bitWidth | UInt64(words32[0])
        d.1 = UInt64(words32[2 * 1 + 1]) << UInt32.bitWidth | UInt64(words32[2*1])
        d.2 = UInt64(words32[2 * 2 + 1]) << UInt32.bitWidth | UInt64(words32[2*2])
        d.3 = UInt64(words32[2 * 3 + 1]) << UInt32.bitWidth | UInt64(words32[2*3])
        overflowed = checkOverflow()
        if overflowed {
            reduce()
        }
    }
    
    init(words64: [UInt64]) {
        var overflowed = false
        self.init(words64: words64, overflowed: &overflowed)
        assert(!overflowed)
    }
    
    public init(words64: [UInt64], overflowed: inout Bool) {
        self.init()
        d.0 = words64[0]
        d.1 = words64[1]
        d.2 = words64[2]
        d.3 = words64[3]
        overflowed = checkOverflow()
        if overflowed {
            reduce()
        }
    }
    
    public init(bits64x4: Bits64x4, overflowed: inout Bool) {
        self.init()
        d.0 = bits64x4.0
        d.1 = bits64x4.1
        d.2 = bits64x4.2
        d.3 = bits64x4.3
        overflowed = checkOverflow()
        if overflowed {
            reduce()
        }
    }
    
    public init(bytes: [UInt8], overflowed: inout Bool) {
        self.init(bytes: bytes[0..<bytes.count], overflowed: &overflowed)
    }
    
    public init(bytes: ArraySlice<UInt8>, overflowed: inout Bool) {
        assert(bytes.count <=  32)
        
        self.init()
        for i in 0..<bytes.count {
            let wordIdx = 3 - i / 8
            let byteIdx = 7 - i % 8
            let val = UInt64(bytes[bytes.startIndex + i]) << (byteIdx * 8)
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
        overflowed = checkOverflow()
        if overflowed {
            reduce()
        }
    }
    
    public init(int64 v: UInt64) {
        self.init()
        d.0 = v
    }
    
    public init(int32 v: UInt32) {
        self.init()
        d.0 = UInt64(v)
    }
    
    public init(int v: Int) {
        self.init()
        d.0 = UInt64(v)
    }
    
    @inline(__always)
    mutating func setInt(_ v: UInt64) {
        d.0 = v
        d.1 = 0
        d.2 = 0
        d.3 = 0
    }
    
    private func serializeWord(word: UInt64, bytes: inout ArraySlice<UInt8>) {
        assert(bytes.count == 8)
        for i in 0..<8 {
            bytes[bytes.startIndex + i] = UInt8((word >> ((7 - i) * 8)) & 0xFF)
        }
    }
    
    public func serialize(bytes: inout ArraySlice<UInt8>) {
        assert(bytes.count >= 32)
        serializeWord(word: d.3, bytes: &bytes[bytes.startIndex..<bytes.startIndex+8])
        serializeWord(word: d.2, bytes: &bytes[bytes.startIndex+8..<bytes.startIndex+16])
        serializeWord(word: d.1, bytes: &bytes[bytes.startIndex+16..<bytes.startIndex+24])
        serializeWord(word: d.0, bytes: &bytes[bytes.startIndex+24..<bytes.startIndex+32])
    }
    
    @inline(__always)
    mutating func reduce() {
        reduce(overflow: 0)
    }
    
    @inline(__always)
    func getWord(_ idx: Int) -> UInt64 {
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
    
    @inline(__always)
    public func getBits64(offset: Int, count: Int) -> UInt64 {
        assert(offset + count <= Self.wordBitWidth * Self.wordWidth)
        assert(count < Self.wordBitWidth)
        if offset >> 6 == (count + offset - 1) >> 6 {
            return UInt64((getWord(offset >> 6) >> (offset & 0x3F)) & ((1 << count) - 1))
        } else {
            assert((offset >> 6) + 1 < 4)
            let firstHalf = UInt64(getWord(offset >> 6) >> (offset & 0x3F))
            let secondHalf = UInt64((getWord((offset >> 6) + 1) << (64 - (offset & 0x3F))))
            return (firstHalf | secondHalf) & ((1 << count) - 1)
        }
    }
    
    @inline(__always)
    public func getBits(offset: Int, count: Int) -> Int {
        assert(count < UInt32.bitWidth)
        return Int(getBits64(offset: offset, count: count))
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
    
    public mutating func clear() {
        d = (0, 0, 0, 0)
    }
    
    @inline(__always)
    mutating func mulArrays(_ x: Bits64x4, _ y: Bits64x4) -> Bits64x8 {
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
    
    @inline(__always)
    mutating func sqrArray(_ x: Bits64x4) -> Bits64x8 {
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
    
    @inline(__always)
    mutating func shift(_ count: Int) {
        for _ in 0..<count {
            sqr()
        }
    }
    
    @inline(__always)
    public mutating func sqr() {
        assert(!checkOverflow())
        
        let bits512 = sqrArray(d)
        reduce512Bits(bits512)
    }
    
    @inline(__always)
    public mutating func mul(_ y: Self) {
        assert(type(of: y).p == Self.p)
        assert(!checkOverflow())
        assert(!y.checkOverflow())
        
        let bits512 = mulArrays(d, y.d)
        reduce512Bits(bits512)
    }
    
    @inline(__always)
    mutating func shiftMul(_ count: Int, _ x: Self) {
        assert(type(of: x).p == Self.p)
        for _ in 0..<count {
            sqr()
        }
        mul(x)
    }
    
    @inline(__always)
    mutating func shiftNumMul(_ shift: Int, _ num: Self, _ prev: Self) -> Self {
        assert(type(of: num).p == Self.p)
        assert(type(of: prev).p == Self.p)
        var shiftedNum = num
        for _ in 0..<shift {
            shiftedNum.sqr()
        }
        shiftedNum.mul(prev)
        return shiftedNum
    }
    
    @inline(__always)
    public mutating func add(_ y: Self, carry: UInt64) {
        assert(type(of: y).p == Self.p)
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
    
    @inline(__always)
    public mutating func add(_ y: Self) {
        add(y, carry: 0)
    }
    
    @inline(__always)
    public mutating func sub(_ y: Self) {
        assert(type(of: y).p == Self.p)
        var ny = y
        ny.negate()
        add(ny)
    }
    
    @inline(__always)
    public static func +(_ x : Self, _ y : Self) -> Self {
        assert(type(of: x).p == type(of: y).p)
        var r = x
        r.add(y)
        return r
    }
    
    @inline(__always)
    public static func -(_ x : Self, _ y : Self) -> Self {
        assert(type(of: x).p == type(of: y).p)
        var r = x
        r.sub(y)
        return r
    }
    
    @inline(__always)
    public static func *(_ x: Self, _ y: Self) -> Self {
        assert(type(of: x).p == type(of: y).p)
        var r = x
        r.mul(y)
        return r
    }
    
    public mutating func div(_ y: Self) {
        assert(type(of: y).p == Self.p)
        var yInv = y
        yInv.inverse()
        mul(yInv)
    }
    
    public static func /(_ x: Self, _ y: Self) -> Self {
        assert(type(of: x).p == type(of: y).p)
        var r = x
        r.div(y)
        return r
    }
    
    @inline(__always)
    public static func neg(_ x: Self) -> Self {
        var r = x
        r.negate()
        return r
    }
    
    @inline(__always)
    public static func sqr(_ x: Self) -> Self {
        var r = x
        r.sqr()
        return r
    }
    
    public static func inv(_ x: Self) -> Self {
        var r = x
        r.inverse()
        return r
    }
}

extension UInt256p {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.d == rhs.d
    }
}


struct Accumulator {
    var c: (UInt64, UInt64, UInt64)
    
    init() {
        c = (0, 0, 0)
    }
    
    init(_ val: UInt64) {
        c = (val, 0, 0)
    }
    
    @inline(__always)
    mutating func reset (_ val: UInt64) {
        c = (val, 0, 0)
    }
    
    @inline(__always)
    mutating func mulAddFast(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        c.1 += hi
        assert(c.2 == 0)
    }
    
    @inline(__always)
    mutating func mulAdd(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c.1, overflow) = c.1.addingReportingOverflow(hi)
        c.2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func mulAdd2(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        var hiCopy = hi
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c.1, overflow) = c.1.addingReportingOverflow(hi)
        c.2 += overflow ? 1 : 0
        
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hiCopy += overflow ? 1 : 0
        (c.1, overflow) = c.1.addingReportingOverflow(hiCopy)
        c.2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func sumAdd(_ x: UInt64) {
        var overflow = false
        (c.0, overflow) = c.0.addingReportingOverflow(x)
        (c.1, overflow) = c.1.addingReportingOverflow(overflow ? 1 : 0)
        c.2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func sumAddFast(_ x: UInt64) {
        var overflow = false
        (c.0, overflow) = c.0.addingReportingOverflow(x)
        c.1 += overflow ? 1 : 0
        assert(c.2 == 0)
    }
    
    @inline(__always)
    mutating func extractFast() -> UInt64 {
        defer {
            (c.0, c.1) = (c.1, 0)
            assert(c.2 == 0)
        }
        return c.0
    }
    
    @inline(__always)
    mutating func extract() -> UInt64 {
        defer {
            c = (c.1, c.2, 0)
        }
        return c.0
    }
    
    func isZero() -> Bool {
        return c == (0, 0, 0)
    }
}

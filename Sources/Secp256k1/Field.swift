struct Secp256k1Field: UInt256p {
    var d: Bits64x4
    var acc: Accumulator
    
    static let wordWidth = 4
    static let wordBitWidth = UInt64.bitWidth
    
    static let p : Bits64x4 = (0xFFFFFFFEFFFFFC2F, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF)
    static let pMinus2 : Bits64x4 = (p.0 - 2, p.1, p.2, p.3)
    //(0xFFFFFFFEFFFFFC2D, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF)
    static let pComp: Bits64x4 = (~p.0 + 1, ~p.1, ~p.2, ~p.3)
    static let pPlus1Div4: Bits64x4 = (0xFFFFFFFFBFFFFF0C, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFF3)
    static let pCompLeadingZeros = 223
    static let pCompWordWidth = 1
    
    static let zero = Secp256k1Field()
    static let one = Secp256k1Field(int32: 1)
    static let three = Secp256k1Field(int32: 3)
    static let two = Secp256k1Field(int32: 2)
    
    static let wordMask = UInt64.max
    
    init() {
        d = (0, 0, 0, 0)
        acc = Accumulator()
    }
    
    @inline(__always)
    func checkOverflow() -> Bool {
        var accC = Accumulator(d.0)
        accC.sumAddFast(Secp256k1Field.pComp.0)
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
    
    @inline(__always)
    mutating func reduce(overflow: UInt64 = 0) {
        assert(overflow <= 1)
        
        let dCopy = d
        
        acc.reset(d.0)
        acc.sumAddFast(Secp256k1Field.pComp.0)
        d.0 = acc.extractFast()
        acc.sumAddFast(d.1)
        d.1 = acc.extractFast()
        acc.sumAddFast(d.2)
        d.2 = acc.extractFast()
        acc.sumAddFast(d.3)
        d.3 = acc.extractFast()
        
        let carry = acc.extractFast()
        assert(carry <= 1)
        assert(acc.isZero())
        
        if overflow | carry == 0 {
            d = dCopy
        }
    }
    
    @inline(__always)
    mutating func negate() {
        assert(!checkOverflow())
        guard !isZero() else {
            return
        }
        assert(Secp256k1Field.p.0 != 0 && Secp256k1Field.p.1 != 0 && Secp256k1Field.p.2 != 0 && Secp256k1Field.p.3 != 0)
        var t : UInt64 = 0
        var overflow = false
        
        (d.0, overflow) = Secp256k1Field.p.0.subtractingReportingOverflow(d.0)
        t = overflow ? 1 : 0
        
        t = Secp256k1Field.p.1 - t
        (d.1, overflow) = t.subtractingReportingOverflow(d.1)
        t = overflow ? 1 : 0
        
        t = Secp256k1Field.p.2 - t
        (d.2, overflow) = t.subtractingReportingOverflow(d.2)
        t = overflow ? 1 : 0
        
        t = Secp256k1Field.p.3 - t
        (d.3, overflow) = t.subtractingReportingOverflow(d.3)
        
        assert(!overflow)
    }
    
    @inline(__always)
    mutating func reduce512To320Bits(_ bits512: Bits64x8) -> Bits64x5 {
        var bits320: Bits64x5 = (0, 0, 0, 0, 0)
        // round 1
        
        acc.reset(bits512.0)
        acc.mulAddFast(bits512.4, Secp256k1Field.pComp.0)
        bits320.0 = acc.extractFast()
        acc.mulAddFast(bits512.5, Secp256k1Field.pComp.0)
        acc.sumAddFast(bits512.1)
        bits320.1 = acc.extractFast()
        acc.mulAddFast(bits512.6, Secp256k1Field.pComp.0)
        acc.sumAddFast(bits512.2)
        bits320.2 = acc.extractFast()
        acc.mulAddFast(bits512.7, Secp256k1Field.pComp.0)
        acc.sumAddFast(bits512.3)
        bits320.3 = acc.extractFast()
        bits320.4 = acc.extractFast()
        assert(acc.isZero())
        assert(bits320.4.leadingZeroBitCount > 16)
        
        return bits320
    }
    
    @inline(__always)
    mutating func reduce320Bits(_ bits320: Bits64x5) {
        acc.reset(bits320.0)
        acc.mulAddFast(bits320.4, Secp256k1Field.pComp.0)
        d.0 = acc.extractFast()
        acc.sumAddFast(bits320.1)
        d.1 = acc.extractFast()
        acc.sumAddFast(bits320.2)
        d.2 = acc.extractFast()
        acc.sumAddFast(bits320.3)
        d.3 = acc.extractFast()
        
        let overflow = acc.extractFast()
        assert(overflow <= 1)
        assert(acc.isZero())
        reduce(overflow: overflow)
    }
    
    @inline(__always)
    mutating func reduce512Bits(_ bits512: Bits64x8) {
        let bits320 = reduce512To320Bits(bits512)
        reduce320Bits(bits320)
    }
    
    mutating func inverse() {
        guard !isZero() else {
            fatalError("Devide by zero")
        }
        
        let x1 = self
        let x2 = shiftNumMul(1, x1, x1)
        let x4 = shiftNumMul(2, x2, x2)
        let x8 = shiftNumMul(4, x4, x4)
        let x16 = shiftNumMul(8, x8, x8)
        
        var x22 = x16
        x22.shiftMul(4, x4)
        x22.shiftMul(2, x2)
        
        let x44 = shiftNumMul(22, x22, x22)
        let x88 = shiftNumMul(44, x44, x44)
        self = shiftNumMul(88, x88, x88) // self = x176
        shiftMul(44, x44)
        shiftMul(2, x2)
        shiftMul(1, x1) // self = x223
        
        ///
        sqr()
        
        // 1111,1111,1111,1111,1111,1100,0010,1101
        shiftMul(22, x22)
        shiftMul(5, x1)
        shiftMul(3, x2)
        shiftMul(2, x1)
    }
    
    mutating func sqrt() -> Bool {
        assert(!checkOverflow())
        
        let initalVal = self
        
        sqrtByPowers()
        
        var x = self
        x.sqr()
        if x == initalVal {
            return true
        } else {
            d = initalVal.d
            return false
        }
    }
    
    static func sqrt(_ x: Secp256k1Field) -> Secp256k1Field? {
        var r = x
        let hasSqrt = r.sqrt()
        return hasSqrt ? r : nil
    }
    
    private mutating func sqrtByPowers() {
        let x1 = self
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
        self = shiftNumMul(1, x222, x1) // self = x223
        
        ///
        sqr()
        
        // ...1111,1011,1111,1111,1111,1111,1111,0000,1100
        shiftMul(22, x22)
        shiftMul(6, x2)
        shift(2)
    }
    
    @inline(__always)
    mutating func mulIntAdd( _ m: UInt64, _ x: Secp256k1Field = Secp256k1Field.zero, _ n: UInt64 = 1) {
        assert(!checkOverflow())
        assert(!x.checkOverflow())
        assert(m < UInt64(UInt8.max))
        assert(n < UInt64(UInt8.max))
        
        acc.reset(0)
        var res: Bits64x5 = (0, 0, 0, 0, 0)
        
        acc.mulAddFast(d.0, m)
        acc.mulAddFast(x.d.0, n)
        res.0 = acc.extractFast()
        
        acc.mulAddFast(d.1, m)
        acc.mulAddFast(x.d.1, n)
        res.1 = acc.extractFast()
        
        acc.mulAddFast(d.2, m)
        acc.mulAddFast(x.d.2, n)
        res.2 = acc.extractFast()
        
        acc.mulAddFast(d.3, m)
        acc.mulAddFast(x.d.3, n)
        res.3 = acc.extractFast()
        res.4 = acc.extractFast()
        
        assert(acc.isZero())
        
        reduce320Bits(res)
    }
    
    @inline(__always)
    static func mulInt(_ x: Secp256k1Field, _ y: UInt64) -> Secp256k1Field {
        var r = x
        r.mulIntAdd(y)
        return r
    }
    
    @inline(__always)
    static func mulIntAdd(_ x: Secp256k1Field,  _ m: UInt64,  _ y: Secp256k1Field = Secp256k1Field.zero, _ n: UInt64 = 1) -> Secp256k1Field {
        var r = x
        r.mulIntAdd(m, y, n)
        return r
    }
    
    @inline(__always)
    static func mulIntSub(_ x: Secp256k1Field,  _ m: UInt64,  _ y: Secp256k1Field = Secp256k1Field.zero, _ n: UInt64 = 1) -> Secp256k1Field {
        var r = x
        r.mulIntAdd(m, Secp256k1Field.neg(y), n)
        return r
    }
    
    
    @inline(__always)
    mutating func mulMulIntAdd(_ b: Secp256k1Field,  _ m: UInt64, _ x: Secp256k1Field, _ y: Secp256k1Field,  _ n: UInt64) {
        assert(!checkOverflow())
        assert(!b.checkOverflow())
        assert(!x.checkOverflow())
        assert(!y.checkOverflow())
        assert(m < UInt64(UInt8.max))
        assert(n < UInt64(UInt8.max))
        
        let ab = mulArrays(d, b.d)
        let ab320 = reduce512To320Bits(ab)
        let xy = mulArrays(x.d, y.d)
        let xy320 = reduce512To320Bits(xy)
        
        var abm_xyn: Bits64x5 = (0, 0, 0, 0, 0)
        
        acc.reset(0)
        
        acc.mulAddFast(ab320.0, m)
        acc.mulAddFast(xy320.0, n)
        abm_xyn.0 = acc.extractFast()
        
        acc.mulAddFast(ab320.1, m)
        acc.mulAddFast(xy320.1, n)
        abm_xyn.1 = acc.extractFast()
        
        acc.mulAddFast(ab320.2, m)
        acc.mulAddFast(xy320.2, n)
        abm_xyn.2 = acc.extractFast()
        
        acc.mulAddFast(ab320.3, m)
        acc.mulAddFast(xy320.3, n)
        abm_xyn.3 = acc.extractFast()
        
        acc.mulAddFast(ab320.4, m)
        acc.mulAddFast(xy320.4, n)
        abm_xyn.4 = acc.extractFast()
        
        assert(acc.isZero())
        
        reduce320Bits(abm_xyn)
    }
    
    @inline(__always)
    static func mulMulIntAdd(_ a: Secp256k1Field, _ b: Secp256k1Field,  _ m: UInt64, _ x: Secp256k1Field, _ y: Secp256k1Field,  _ n: UInt64) -> Secp256k1Field {
        var r = a
        r.mulMulIntAdd(b, m, x, y, n)
        return r
    }
    
    @inline(__always)
    static func mulMulIntSub(_ a: Secp256k1Field, _ b: Secp256k1Field,  _ m: UInt64, _ x: Secp256k1Field, _ y: Secp256k1Field,  _ n: UInt64) -> Secp256k1Field {
        var r = a
        let nx = neg(x)
        r.mulMulIntAdd(b, m, nx, y, n)
        return r
    }
    
    @inline(__always)
    mutating func mulMulInt(_ b: Secp256k1Field,  _ m: UInt64) {
        assert(!checkOverflow())
        assert(!b.checkOverflow())
        assert(m < UInt64(UInt8.max))
        
        let ab = mulArrays(d, b.d)
        var bits320 = reduce512To320Bits(ab)
        
        acc.reset(0)
        acc.mulAddFast(bits320.0, m)
        bits320.0 = acc.extractFast()
        acc.mulAddFast(bits320.1, m)
        bits320.1 = acc.extractFast()
        acc.mulAddFast(bits320.2, m)
        bits320.2 = acc.extractFast()
        acc.mulAddFast(bits320.3, m)
        bits320.3 = acc.extractFast()
        acc.mulAddFast(bits320.4, m)
        bits320.4 = acc.extractFast()
        
        assert(acc.isZero())
        
        reduce320Bits(bits320)
    }
    
    @inline(__always)
    static func mulMulInt(_ a: Secp256k1Field, _ b: Secp256k1Field,  _ m: UInt64) -> Secp256k1Field {
        var r = a
        r.mulMulInt(b, m)
        return r
    }
    
    @inline(__always)
    mutating func mulAdd(_ b: Secp256k1Field, _ x: Secp256k1Field, _ y: Secp256k1Field) {
        assert(!checkOverflow())
        assert(!b.checkOverflow())
        assert(!x.checkOverflow())
        assert(!y.checkOverflow())
        
        let ab = mulArrays(d, b.d)
        let ab320 = reduce512To320Bits(ab)
        let xy = mulArrays(x.d, y.d)
        let xy320 = reduce512To320Bits(xy)
        
        var abm_xyn: Bits64x5 = (0, 0, 0, 0, 0)
        
        acc.reset(0)
        
        acc.sumAddFast(ab320.0)
        acc.sumAddFast(xy320.0)
        abm_xyn.0 = acc.extractFast()
        
        acc.sumAddFast(ab320.1)
        acc.sumAddFast(xy320.1)
        abm_xyn.1 = acc.extractFast()
        
        acc.sumAddFast(ab320.2)
        acc.sumAddFast(xy320.2)
        abm_xyn.2 = acc.extractFast()
        
        acc.sumAddFast(ab320.3)
        acc.sumAddFast(xy320.3)
        abm_xyn.3 = acc.extractFast()
        
        acc.sumAddFast(ab320.4)
        acc.sumAddFast(xy320.4)
        abm_xyn.4 = acc.extractFast()
        
        assert(acc.isZero())
        
        reduce320Bits(abm_xyn)
    }
    
    @inline(__always)
    static func mulAdd(_ a: Secp256k1Field, _ b: Secp256k1Field, _ x: Secp256k1Field, _ y: Secp256k1Field) -> Secp256k1Field {
        var r = a
        r.mulAdd(b, x, y)
        return r
    }
    
    @inline(__always)
    static func mulSub(_ a: Secp256k1Field, _ b: Secp256k1Field, _ x: Secp256k1Field, _ y: Secp256k1Field) -> Secp256k1Field {
        var r = a
        var nx = x
        nx.negate()
        r.mulAdd(b, nx, y)
        return r
    }
    
    @inline(__always)
    mutating func mulAdd(_ x: Secp256k1Field, _ y: Secp256k1Field) {
        assert(!checkOverflow())
        assert(!x.checkOverflow())
        assert(!y.checkOverflow())
        
        let xy = mulArrays(x.d, y.d)
        var bits320 = reduce512To320Bits(xy)
        
        acc.reset(0)
        acc.sumAddFast(d.0)
        acc.sumAddFast(bits320.0)
        bits320.0 = acc.extractFast()
        acc.sumAddFast(d.1)
        acc.sumAddFast(bits320.1)
        bits320.1 = acc.extractFast()
        acc.sumAddFast(d.2)
        acc.sumAddFast(bits320.2)
        bits320.2 = acc.extractFast()
        acc.sumAddFast(d.3)
        acc.sumAddFast(bits320.3)
        bits320.3 = acc.extractFast()
        acc.sumAddFast(bits320.4)
        bits320.4 = acc.extractFast()
        assert(acc.isZero())
        
        reduce320Bits(bits320)
    }
    
    @inline(__always)
    static func mulAdd(_ a: Secp256k1Field, _ x: Secp256k1Field, _ y: Secp256k1Field) -> Secp256k1Field {
        var r = a
        r.mulAdd(x, y)
        return r
    }
    
    @inline(__always)
    static func mulSub(_ a: Secp256k1Field, _ x: Secp256k1Field, _ y: Secp256k1Field) -> Secp256k1Field {
        var r = a
        var nx = x
        nx.negate()
        r.mulAdd(nx, y)
        return r
    }
}



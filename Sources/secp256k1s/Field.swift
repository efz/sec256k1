public struct Secpt256k1Field: UInt256p {
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
    
    public static let zero = Secpt256k1Field()
    public static let one = Secpt256k1Field(int32: 1)
    static let three = Secpt256k1Field(int32: 3)
    static let two = Secpt256k1Field(int32: 2)
    
    static let wordMask = UInt64.max
    
    public init() {
        d = (0, 0, 0, 0)
        acc = Accumulator()
    }
    
    @inline(__always)
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
    
    @inline(__always)
    mutating func reduce(overflow: UInt64 = 0) {
        assert(overflow <= 1)
        
        let dCopy = d
        
        acc.reset(d.0)
        acc.sumAddFast(Secpt256k1Field.pComp.0)
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
    
    mutating func reduce512Bits(_ bits512: Bits64x8) {
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
        assert(overflow <= 1)
        assert(acc.isZero())
        assert(!(overflow > 0 && checkOverflow())) // ??
        reduce(overflow: overflow)
    }
    
    public mutating func inverse() {
        guard !isZero() else {
            fatalError("Devide by zero")
        }
        
        let shiftNumMul = { (shift: Int, num: Secpt256k1Field, prev: Secpt256k1Field) -> Secpt256k1Field in
            var shiftedNum = num
            for _ in 0..<shift {
                shiftedNum.sqr()
            }
            shiftedNum.mul(prev)
            return shiftedNum
        }
        
        let x1 = self
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
        mul(x223)
        sqr()
        
        // 1111,1111,1111,1111,1111,1100,0010,1101
        shiftMul(22, x22)
        shiftMul(5, x1)
        shiftMul(3, x2)
        shiftMul(2, x1)
    }
    
    public mutating func sqrt() -> Bool {
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
    
    public static func sqrt(_ x: Secpt256k1Field) -> Secpt256k1Field? {
        var r = x
        let hasSqrt = r.sqrt()
        return hasSqrt ? r : nil
    }
    
    private mutating func sqrtByPowers() {
        let shiftNumMul = { (shift: Int, num: Secpt256k1Field, prev: Secpt256k1Field) -> Secpt256k1Field in
            var shiftedNum = num
            for _ in 0..<shift {
                shiftedNum.sqr()
            }
            shiftedNum.mul(prev)
            return shiftedNum
        }
        
        let x1 = self
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
        mul(x223)
        sqr()
        
        // ...1111,1011,1111,1111,1111,1111,1111,0000,1100
        shiftMul(22, x22)
        shiftMul(6, x2)
        shift(2)
    }
    
    @inline(__always)
    mutating func mulInt(_ y: UInt64) {
        assert(!checkOverflow())
        assert(y < UInt64(UInt8.max))
        
        acc.reset(0)
        var res: Bits64x5 = (0, 0, 0, 0, 0)
        
        acc.mulAddFast(d.0, y)
        res.0 = acc.extractFast()
        
        acc.mulAddFast(d.1, y)
        res.1 = acc.extractFast()
        
        acc.mulAddFast(d.2, y)
        res.2 = acc.extractFast()
        
        acc.mulAddFast(d.3, y)
        res.3 = acc.extractFast()
        res.4 = acc.extractFast()
        
        assert(acc.isZero())
        
        acc.reset(res.0)
        acc.mulAddFast(res.4, Secpt256k1Field.pComp.0)
        d.0 = acc.extractFast()
        
        acc.sumAddFast(res.1)
        d.1 = acc.extractFast()
        
        acc.sumAddFast(res.2)
        d.2 = acc.extractFast()
        
        acc.sumAddFast(res.3)
        d.3 = acc.extractFast()
        
        assert(acc.isZero())
        reduce()
    }
    
    @inline(__always)
    public static func mulInt(_ x: Secpt256k1Field, _ y: UInt64) -> Secpt256k1Field {
        var r = x
        r.mulInt(y)
        return r
    }
}



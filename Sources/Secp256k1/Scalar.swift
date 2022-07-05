struct Secp256k1Scalar: UInt256p {
    var d: Bits64x4
    var acc: Accumulator
    
    static let wordWidth = 4
    static let pCompWordWidth = 3
    static let wordBitWidth = UInt64.bitWidth
    
    static let p : Bits64x4 = (0xBFD25E8CD0364141, 0xBAAEDCE6AF48A03B, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF)
    static let pMinus2 : Bits64x4 = (0xBFD25E8CD036413F, 0xBAAEDCE6AF48A03B, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF)
    static let pComp: Bits64x3 = (~p.0 + 1, ~p.1, ~p.2)
    static let pCompLeadingZeros = 127
    static let pHalf = (p.1 << 63 | p.0 >> 1, p.2 << 63 | p.1 >> 1 ,p.3 << 63 | p.2 >> 1 ,p.3 >> 1)
    
    static let zero = Secp256k1Scalar()
    static let one = Secp256k1Scalar(int32: 1)
    
    static let wordMask = UInt64.max
    
    init() {
        d = (0, 0, 0, 0)
        acc = Accumulator()
    }
    
    func checkOverflow() -> Bool {
        var accC = Accumulator(d.0)
        accC.sumAddFast(Secp256k1Scalar.pComp.0)
        let _ = accC.extractFast()
        accC.sumAddFast(d.1)
        accC.sumAddFast(Secp256k1Scalar.pComp.1)
        let _ = accC.extractFast()
        accC.sumAddFast(d.2)
        accC.sumAddFast(Secp256k1Scalar.pComp.2)
        let _ = accC.extractFast()
        accC.sumAddFast(d.3)
        let _ = accC.extractFast()
        
        let overflow = accC.extractFast()
        assert(accC.isZero())
        assert(overflow <= 1)
        return overflow != 0
    }
    
    mutating func reduce(overflow: UInt64 = 0) {
        assert(overflow <= 1)
        
        var reduced: Bits64x4 = (0, 0, 0, 0)
        
        acc.reset(d.0)
        acc.sumAddFast(Secp256k1Scalar.pComp.0)
        reduced.0 = acc.extractFast()
        acc.sumAddFast(d.1)
        acc.sumAddFast(Secp256k1Scalar.pComp.1)
        reduced.1 = acc.extractFast()
        acc.sumAddFast(d.2)
        acc.sumAddFast(Secp256k1Scalar.pComp.2)
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
    
    mutating func negate() {
        assert(!checkOverflow())
        guard !isZero() else {
            return
        }
        assert(Secp256k1Scalar.p.0 != 0 && Secp256k1Scalar.p.1 != 0 && Secp256k1Scalar.p.2 != 0 && Secp256k1Scalar.p.3 != 0)
        var t : UInt64 = 0
        var overflow = false
        
        (d.0, overflow) = Secp256k1Scalar.p.0.subtractingReportingOverflow(d.0)
        t = overflow ? 1 : 0
        
        t = Secp256k1Scalar.p.1 - t
        (d.1, overflow) = t.subtractingReportingOverflow(d.1)
        t = overflow ? 1 : 0
        
        t = Secp256k1Scalar.p.2 - t
        (d.2, overflow) = t.subtractingReportingOverflow(d.2)
        t = overflow ? 1 : 0
        
        t = Secp256k1Scalar.p.3 - t
        (d.3, overflow) = t.subtractingReportingOverflow(d.3)
        
        assert(!overflow)
    }
    
    mutating func reduce512Bits(_ bits512: Bits64x8) {
        assert(Secp256k1Scalar.pComp.2 == 1)
        
        var bits448: Bits64x7 = (0, 0, 0, 0, 0, 0, 0)
        // round 1
        bits448.0 = bits512.0
        bits448.1 = bits512.1
        
        acc.reset(bits512.2)
        
        acc.mulAddFast(bits512.6, Secp256k1Scalar.pComp.0)
        bits448.2 = acc.extractFast()
        acc.mulAddFast(bits512.6, Secp256k1Scalar.pComp.1)
        acc.mulAdd(bits512.7, Secp256k1Scalar.pComp.0)
        acc.sumAdd(bits512.3)
        bits448.3 = acc.extract()
        acc.sumAdd(bits512.6) // acc.mulAdd(bits512[mStart], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(bits512.7, Secp256k1Scalar.pComp.1)
        acc.sumAdd(bits512.4)
        bits448.4 = acc.extract()
        acc.sumAdd(bits512.7) //acc.mulAdd(bits512[mStart+1], Secpt256k1Scalar.pComp[2])
        acc.sumAdd(bits512.5)
        bits448.5 = acc.extract()
        bits448.6 = acc.extractFast()
        assert(acc.isZero())
        
        var bits384: Bits64x6 = (0, 0, 0, 0, 0, 0)
        // round 2
        bits384.0 = bits448.0
        
        acc.reset(bits448.1)
        acc.mulAddFast(bits448.5, Secp256k1Scalar.pComp.0)
        bits384.1 = acc.extractFast()
        acc.mulAddFast(bits448.5, Secp256k1Scalar.pComp.1)
        acc.mulAdd(bits448.6, Secp256k1Scalar.pComp.0)
        acc.sumAdd(bits448.2)
        bits384.2 = acc.extract()
        acc.sumAdd(bits448.5) //acc.mulAdd(d[mStart], Secpt256k1Scalar.pComp[2])
        acc.mulAdd(bits448.6, Secp256k1Scalar.pComp.1)
        acc.sumAdd(bits448.3)
        bits384.3 = acc.extract()
        acc.sumAdd(bits448.6) //acc.mulAdd(d[mStart+1], Secpt256k1Scalar.pComp[2])
        acc.sumAdd(bits448.4)
        bits384.4 = acc.extractFast()
        bits384.5 = acc.extractFast()
        assert(acc.isZero())
        
        // round 3
        acc.reset(bits384.0)
        acc.mulAddFast(bits384.4, Secp256k1Scalar.pComp.0)
        d.0 = acc.extractFast()
        acc.mulAddFast(bits384.4, Secp256k1Scalar.pComp.1)
        acc.mulAdd(bits384.5, Secp256k1Scalar.pComp.0)
        acc.sumAdd(bits384.1)
        d.1 = acc.extract()
        acc.mulAdd(bits384.5, Secp256k1Scalar.pComp.1)
        acc.sumAdd(bits384.4) // acc.mulAddFast(bits512[mStart], Secpt256k1Scalar.pComp[2])
        acc.sumAdd(bits384.2)
        d.2 = acc.extract()
        acc.sumAdd(bits384.5)
        acc.sumAdd(bits384.3)
        d.3 = acc.extractFast()
        
        let overflow = acc.extractFast()
        assert(overflow <= 1)
        assert(acc.isZero())
        assert(!(overflow > 0 && checkOverflow())) // ??
        reduce(overflow: overflow)
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
        let x32 = shiftNumMul(16, x16, x16)
        let x64 = shiftNumMul(32, x32,  x32)
        let x96 = shiftNumMul(32, x64, x32)
        let x112 = shiftNumMul(16, x96, x16)
        let x120 = shiftNumMul(8, x112, x8)
        let x124 = shiftNumMul(4, x120, x4)
        
        var x3 = x2
        x3.sqr()
        x3.mul(x1)
        
        self = shiftNumMul(3, x124, x3) // self = x127
        
        ///
        sqr()
        
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
    
    func isHigherThanHalfP() -> Bool {
        assert(!checkOverflow())
        
        var t : UInt64 = 0
        var overflow = false
        
        (_, overflow) = Secp256k1Scalar.pHalf.0.subtractingReportingOverflow(d.0)
        t = overflow ? 1 : 0
        
        t = Secp256k1Scalar.pHalf.1 - t
        (_, overflow) = t.subtractingReportingOverflow(d.1)
        t = overflow ? 1 : 0
        
        t = Secp256k1Scalar.pHalf.2 - t
        (_, overflow) = t.subtractingReportingOverflow(d.2)
        t = overflow ? 1 : 0
        
        t = Secp256k1Scalar.pHalf.3 - t
        (_, overflow) = t.subtractingReportingOverflow(d.3)
        
        return overflow
    }
}


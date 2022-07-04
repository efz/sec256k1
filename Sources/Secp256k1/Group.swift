struct Secp256k1Group {
    static let curvA = Secp256k1Field.zero
    static let curvB = Secp256k1Field(int64: 7)
    static let infinity = Secp256k1Group()
    static let three = Secp256k1Field(int32: 3)
    static let two = Secp256k1Field(int32: 2)
    
    var x: Secp256k1Field
    var y: Secp256k1Field
    var z: Secp256k1Field
    var isInfinity: Bool
    
    init() {
        x = Secp256k1Field.zero
        y = Secp256k1Field.zero
        z = Secp256k1Field.one
        isInfinity = true
    }
    
    init?(x: Secp256k1Field, y: Secp256k1Field) {
        self.x = x
        self.y = y
        z = Secp256k1Field.one
        isInfinity = false
        if !isValid() {
            return nil
        }
    }
    
    init?(x: Secp256k1Field, y: Secp256k1Field, z: Secp256k1Field) {
        self.x = x
        self.y = y
        self.z = z
        isInfinity = false
        if !isValidJ() {
            return nil
        }
    }
    
    init?(x: Secp256k1Field) {
        self.x = x
        z = Secp256k1Field.one
        isInfinity = false
        if let computedY = Secp256k1Group.calcY(x: x) {
            y = computedY
        } else {
            return nil
        }
    }
    
    init?(x: Secp256k1Field, odd: Bool) {
        self.x = x
        z = Secp256k1Field.one
        isInfinity = false
        if let computedY = Secp256k1Group.calcY(x: x) {
            y = computedY
        } else {
            return nil
        }
        if odd != !y.isEven() {
            y.negate()
        }
    }
    
    init?(bytes: ArraySlice<UInt8>) {
        assert(bytes.count >= 32)
        
        var overflowed = false
        let tmpX = Secp256k1Field(bytes: bytes[bytes.startIndex..<bytes.startIndex+32], overflowed: &overflowed)
        if overflowed {
            return nil
        }
        if bytes.count < 64 {
            self.init(x: tmpX)
        } else {
            let tempY = Secp256k1Field(bytes: bytes[bytes.startIndex+32..<bytes.startIndex+64], overflowed: &overflowed)
            if overflowed {
                return nil
            }
            self.init(x: tmpX, y: tempY)
        }
        if isInfinity || !isValid() {
            return nil
        }
    }
    
    init?(bytes: ArraySlice<UInt8>, odd: Bool? = nil) {
        self.init(bytes: bytes)
        if odd != nil && !odd! != y.isEven() {
            if bytes.count >= 64 {
                return nil
            }
            reflect()
        }
    }
    
    func serialize(bytes: inout ArraySlice<UInt8>) {
        assert(bytes.count >= 32)
        assert(isNormalized() && isValid() && !isInfinity)
        
        x.serialize(bytes: &bytes[bytes.startIndex..<bytes.startIndex+32])
        if bytes.count >= 64 {
            y.serialize(bytes: &bytes[bytes.startIndex+32..<bytes.startIndex+64])
        }
    }
    
    static func calcY(x: Secp256k1Field) -> Secp256k1Field? {
        var computedY = x * x * x + Secp256k1Group.curvB
        let yExists = computedY.sqrt()
        return yExists ? computedY : nil
    }
    
    func isValid() -> Bool {
        assert(z.isOne())
        
        if isInfinity {
            return true
        }
        let rhs = x * x * x + Secp256k1Group.curvB
        let lhs = y * y
        if rhs != lhs {
            return false
        }
        return true
    }
    
    func isNormalized() -> Bool {
        return z.isOne()
    }
    
    func isOdd() -> Bool {
        return !y.isEven()
    }
    
    func isValidJ() -> Bool {
        if isInfinity {
            return true
        }
        let z2 = z * z
        let z6 = z2 * z2 * z2
        
        let rhs = x * x * x + z6 * Secp256k1Group.curvB
        let lhs = y * y
        if rhs != lhs {
            return false
        }
        return true
    }
    
    mutating func add(_ b: Secp256k1Group) {
        assert(z.isOne() && b.z.isOne())
        assert(isValid() && b.isValid())
        assert(self != b) // double?
        
        if b.isInfinity {
            return
        } else if isInfinity {
            self = b
            return
        }
        
        let xDiff = (b.x - x)
        if xDiff.isZero() {
            y = Secp256k1Field.zero
            isInfinity = true
            return
        }
        
        let yDiff = b.y - y
        let m = yDiff / xDiff
        var m2 = m
        m2.sqr()
        x = m2 - x - b.x
        
        let c = b.y - m * b.x
        y = m * x + c
        y.negate()
        
        assert(isValid())
    }
    
    static func normalizeJ(_ a: Secp256k1Group) -> Secp256k1Group {
        var r: Secp256k1Group = a
        r.normalizeJ()
        return r
    }
    
    mutating func normalizeJ() {
        let zInv = Secp256k1Field.inv(z)
        let zInv2 = Secp256k1Field.sqr(zInv)
        let zInv3 = zInv2 * zInv
        z = Secp256k1Field.one
        x = x  * zInv2
        y = y  * zInv3
    }
    
    mutating func addJ(_ b: Secp256k1Group) {
        assert(isValidJ() && b.isValidJ())
        //assert(Secp256k1Group.normalizeJ(self) != Secp256k1Group.normalizeJ(b)) // double?
        
        if b.isInfinity {
            return
        } else if isInfinity {
            self = b
            return
        }
        
        let z2 = Secp256k1Field.sqr(z)
        let bz2 = Secp256k1Field.sqr(b.z)
        let bxz2 = b.x * z2
        let xbz2 = x * bz2
        let xDiffJ = bxz2 - xbz2
        
        let z3 = z2 * z
        let bz3 = bz2 * b.z
        let byz3 = b.y * z3
        let yDiffJ = Secp256k1Field.mulSub(byz3, y, bz3) // yDiffJ = mj
        
        if xDiffJ.isZero() {
            if yDiffJ.isZero() {
                doubleJ()
                return
            }
            y = Secp256k1Field.zero
            isInfinity = true
            return
        }
        
        let xDiffJ2 = Secp256k1Field.sqr(xDiffJ)
        let t1 = xbz2 + bxz2
        x = Secp256k1Field.mulSub(yDiffJ, yDiffJ, xDiffJ2, t1)
        
        let zbz = z * b.z
        z = xDiffJ * zbz
        
        let tc = Secp256k1Field.mulSub(byz3, xDiffJ, yDiffJ, bxz2)
        y = Secp256k1Field.mulAdd(yDiffJ, x, xDiffJ2, tc)
        y.negate()
    }
    
    mutating func addAffine2J(_ b: Secp256k1Group) {
        assert(isValidJ() && b.isValid())
        //assert(Secp256k1Group.normalizeJ(self) != b) // double?
        
        if b.isInfinity {
            return
        } else if isInfinity {
            self = b
            return
        }
        
        let z2 = Secp256k1Field.sqr(z)
        let bxz2 = b.x * z2
        let xDiffJ = bxz2 - x
        
        let z3 = z2 * z
        let byz3 = b.y * z3
        let yDiffJ = byz3 - y
        
        if xDiffJ.isZero() {
            if yDiffJ.isZero() {
                doubleJ()
                return
            }
            y = Secp256k1Field.zero
            isInfinity = true
            return
        }
        
        let mj = yDiffJ
        
        let xDiffJ2 = Secp256k1Field.sqr(xDiffJ)
        let t1 = x + bxz2
        x = Secp256k1Field.mulSub(mj, mj, xDiffJ2, t1)
        
        z = xDiffJ * z
        
        let tc = Secp256k1Field.mulSub(byz3, xDiffJ, mj, bxz2)
        y = Secp256k1Field.mulAdd(mj, x, xDiffJ2, tc)
        y.negate()
    }
    
    mutating func double() {
        assert(z.isOne())
        assert(isValid())
        
        guard !isInfinity else {
            return
        }
        
        if y.isZero() {
            isInfinity = true
            return
        }
        
        var x2 = x
        x2.sqr()
        
        let m = (Secp256k1Field.three * x2) / (Secp256k1Field.two * y)
        var m2 = m
        m2.sqr()
        
        let c = y - m * x
        
        x = m2 - x - x
        y = m * x + c
        y.negate()
        
        assert(isValid())
    }
    
    mutating func doubleJ() {
        assert(isValidJ())
        
        guard !isInfinity else {
            return
        }
        
        if y.isZero() {
            isInfinity = true
            return
        }
        
        z = Secp256k1Field.mulMulInt(y, z, 2)
        
        let x2 = Secp256k1Field.sqr(x)
        let y2 = Secp256k1Field.sqr(y)
        let x3 = x2 * x
        
        x = Secp256k1Field.mulMulIntSub(x2, x2, 9, x, y2, 8)
        let t2 = Secp256k1Field.mulIntSub(x3, 9, y2, 2)
        y = Secp256k1Field.mulMulIntSub(x3, x3, 27, y2, t2, 4)
        
        y.negate()
    }
    
    mutating func reflect() {
        assert(isValid())
        guard !isInfinity else {
            return
        }
        y.negate()
    }
    
    func isSame(scalarX: Secp256k1Scalar) -> Bool {
        var overflow = false
        let scalarX_f = Secp256k1Field(bits64x4: scalarX.d, overflowed: &overflow)
        assert(!overflow)
        
        let z2 = Secp256k1Field.sqr(z)
        if x == z2 * scalarX_f {
            return true
        }
        let scalarP_f = Secp256k1Field(bits64x4: Secp256k1Scalar.p, overflowed: &overflow)
        assert(!overflow)
        
        return x == (scalarX_f + scalarP_f) * z2
    }
}


extension Secp256k1Group: Equatable {
    static func == (lhs: Secp256k1Group, rhs: Secp256k1Group) -> Bool {
        assert(lhs.z.isOne() && rhs.z.isOne())
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.isInfinity == rhs.isInfinity
    }
}

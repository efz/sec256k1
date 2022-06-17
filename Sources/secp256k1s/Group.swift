public struct Secp256k1Group {
    public static let curvA = Secpt256k1Field.zero
    public static let curvB = Secpt256k1Field(int64: 7)
    public static let infinity = Secp256k1Group()
    static let threeDivTwo = Secpt256k1Field(int32: 3) / Secpt256k1Field(int32: 2)
    static let three = Secpt256k1Field(int32: 3)
    static let two = Secpt256k1Field(int32: 2)
    static let eight = Secpt256k1Field(int32: 8)
    
    public var x: Secpt256k1Field
    public var y: Secpt256k1Field
    public var z: Secpt256k1Field
    public var isInfinity: Bool
    
    public init() {
        x = Secpt256k1Field.zero
        y = Secpt256k1Field.zero
        z = Secpt256k1Field.one
        isInfinity = true
    }
    
    public init?(x: Secpt256k1Field, y: Secpt256k1Field) {
        self.x = x
        self.y = y
        z = Secpt256k1Field.one
        isInfinity = false
        if !isValid() {
            return nil
        }
    }
    
    public init?(x: Secpt256k1Field, y: Secpt256k1Field, z: Secpt256k1Field) {
        self.x = x
        self.y = y
        self.z = z
        isInfinity = false
        if !isValidJ() {
            return nil
        }
    }
    
    public init?(x: Secpt256k1Field) {
        self.x = x
        z = Secpt256k1Field.one
        isInfinity = false
        if let computedY = Secp256k1Group.calcY(x: x) {
            y = computedY
        } else {
            return nil
        }
    }
    
    public init?(x: Secpt256k1Field, odd: Bool) {
        self.x = x
        z = Secpt256k1Field.one
        isInfinity = false
        if let computedY = Secp256k1Group.calcY(x: x) {
            y = computedY
        } else {
            return nil
        }
        if odd && y.isEven() {
            y.negate()
        }
    }
    
    static func calcY(x: Secpt256k1Field) -> Secpt256k1Field? {
        var computedY = x * x * x + Secp256k1Group.curvB
        let yExists = computedY.sqrt()
        return yExists ? computedY : nil
    }
    
    public func isValid() -> Bool {
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
    
    public func isValidJ() -> Bool {
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
    
    public mutating func add(_ b: Secp256k1Group) {
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
            y = Secpt256k1Field.zero
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
    
    public static func normalizeJ(_ a: Secp256k1Group) -> Secp256k1Group {
        var r: Secp256k1Group = a
        r.normalizeJ()
        return r
    }
    
    public mutating func normalizeJ() {
        let z2 = Secpt256k1Field.sqr(z)
        let z3 = z2 * z
        z = Secpt256k1Field.one
        x = x / z2
        y = y / z3
    }
    
    public mutating func addJ(_ b: Secp256k1Group) {
        assert(isValidJ() && b.isValidJ())
        assert(Secp256k1Group.normalizeJ(self) != Secp256k1Group.normalizeJ(b)) // double?
        
        if b.isInfinity {
            return
        } else if isInfinity {
            self = b
            return
        }
        
        let z2 = Secpt256k1Field.sqr(z)
        let bz2 = Secpt256k1Field.sqr(b.z)
        let bxz2 = b.x * z2
        let xbz2 = x * bz2
        let xDiffJ = bxz2 - xbz2
        if xDiffJ.isZero() {
            y = Secpt256k1Field.zero
            isInfinity = true
            return
        }
        
        let z3 = z2 * z
        let bz3 = bz2 * b.z
        let byz3 =  b.y * z3
        let yDiffJ = byz3 - y * bz3 // yDiffJ = mj
        let yDiffJ2 = Secpt256k1Field.sqr(yDiffJ) // yDiffJ2 = mj2
        
        let xDiffJ2 = Secpt256k1Field.sqr(xDiffJ)
        x = yDiffJ2 - xDiffJ2 * (xbz2 + bxz2)
        
        z = xDiffJ * z * b.z
        
        let cj = xDiffJ2 * (byz3 * xDiffJ - yDiffJ * bxz2)
        y = yDiffJ * x + cj
        y.negate()
    }
    
    public mutating func addAffine2J(_ b: Secp256k1Group) {
        assert(isValidJ() && b.isValid())
        assert(Secp256k1Group.normalizeJ(self) != b) // double?
        
        if b.isInfinity {
            return
        } else if isInfinity {
            self = b
            return
        }
        
        let z2 = Secpt256k1Field.sqr(z)
        let bxz2 = b.x * z2
        let xDiffJ = bxz2 - x
        if xDiffJ.isZero() {
            y = Secpt256k1Field.zero
            isInfinity = true
            return
        }
        
        let z3 = z2 * z
        let byz3 = b.y * z3
        let yDiffJ = byz3 - y
        let mj = yDiffJ
        let mj2 = Secpt256k1Field.sqr(mj)
        
        let xDiffJ2 = Secpt256k1Field.sqr(xDiffJ)
        x = mj2 - xDiffJ2 * (x + bxz2)
        
        z = xDiffJ * z
        
        let cj = xDiffJ2 * (byz3  * xDiffJ - mj * bxz2)
        y = mj * x + cj
        y.negate()
    }
    
    public mutating func double() {
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
        
        let m = (Secpt256k1Field.three * x2) / (Secpt256k1Field.two * y)
        var m2 = m
        m2.sqr()
        
        let c = y - m * x
        
        x = m2 - x - x
        y = m * x + c
        y.negate()
        
        assert(isValid())
    }
    
    public mutating func doubleJ() {
        assert(isValidJ())
        
        guard !isInfinity else {
            return
        }
        
        if y.isZero() {
            isInfinity = true
            return
        }
        
        let yz = y * z
        z = Secpt256k1Field.mulInt(yz, 2)
        
        let x2 = Secpt256k1Field.sqr(x)
        let y2 = Secpt256k1Field.sqr(y)
        let x3 = x2 * x
        let x6 = Secpt256k1Field.sqr(x3)
        
        // x = x * (9 * x^3 - 8 * y^2)
        let y2by8 = Secpt256k1Field.mulInt(y2, 8)
        let x3by9 =  Secpt256k1Field.mulInt(x3, 9)
        let t1 = x3by9 - y2by8
        x = x * t1
        
        // y = 27 * x^6 - 4 * y^2 * (9 * x^3 - 2 * y^2)
        let x6by27 = Secpt256k1Field.mulInt(x6, 27)
        let y2by4 = Secpt256k1Field.mulInt(y2, 4)
        
        let t2 = x3by9 - Secpt256k1Field.mulInt(y2, 2)
        let t3 = y2by4 * t2
        
        y = x6by27 - t3
        
        y.negate()
    }
    
    public mutating func reflect() {
        assert(isValid())
        guard !isInfinity else {
            return
        }
        y.negate()
    }
}


extension Secp256k1Group: Equatable {
    public static func == (lhs: Secp256k1Group, rhs: Secp256k1Group) -> Bool {
        assert(lhs.z.isOne() && rhs.z.isOne())
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.isInfinity == rhs.isInfinity
    }
}

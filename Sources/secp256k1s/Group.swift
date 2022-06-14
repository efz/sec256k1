public struct Secp256k1Group {
    public static let curvA = Secpt256k1Field.zero
    public static let curvB = Secpt256k1Field(int64: 7)
    public static let infinity = Secp256k1Group()
    static let threeDivTwo = Secpt256k1Field(int32: 3) / Secpt256k1Field(int32: 2)
    
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
    
    public mutating func normalizeJ() {
        let z2 = Secpt256k1Field.sqr(z)
        let z3 = z2 * z
        z = Secpt256k1Field.one
        x = x / z2
        y = y / z3
    }
    
    public mutating func addJ(_ b: Secp256k1Group) {
        assert(isValidJ() && b.isValidJ())
        
        if b.isInfinity {
            return
        } else if isInfinity {
            self = b
            return
        }
        
        let z2 = Secpt256k1Field.sqr(z)
        let bz2 = Secpt256k1Field.sqr(b.z)
        let xDiffJ = (b.x * z2 - x * bz2)
        if xDiffJ.isZero() {
            y = Secpt256k1Field.zero
            isInfinity = true
            return
        }
        
        let z3 = z2 * z
        let bz3 = bz2 * b.z
        let yDiffJ = b.y * z3 - y * bz3
        let mj = yDiffJ
        let mj2 = Secpt256k1Field.sqr(mj)
        
        let xDiffJ2 = Secpt256k1Field.sqr(xDiffJ)
        x = mj2 - xDiffJ2 * (x * bz2 + b.x * z2)
        
        z = xDiffJ * z * b.z
        
        let cj = xDiffJ2 * (b.y * z3  * xDiffJ - mj * b.x * z2)
        y = mj * x + cj
        y.negate()
    }
    
    public mutating func addAffine2J(_ b: Secp256k1Group) {
        assert(isValidJ() && b.isValid())
        
        if b.isInfinity {
            return
        } else if isInfinity {
            self = b
            return
        }
        
        let z2 = Secpt256k1Field.sqr(z)
        let xDiffJ = (b.x * z2 - x)
        if xDiffJ.isZero() {
            y = Secpt256k1Field.zero
            isInfinity = true
            return
        }
        
        let z3 = z2 * z
        let yDiffJ = b.y * z3 - y
        let mj = yDiffJ
        let mj2 = Secpt256k1Field.sqr(mj)
        
        let xDiffJ2 = Secpt256k1Field.sqr(xDiffJ)
        x = mj2 - xDiffJ2 * (x + b.x * z2)
        
        z = xDiffJ * z
        
        let cj = xDiffJ2 * (b.y * z3  * xDiffJ - mj * b.x * z2)
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
        
        z = y * z
        
        let x2 = Secpt256k1Field.sqr(x)
        let mj = Secp256k1Group.threeDivTwo * x2
        let mj2 = Secpt256k1Field.sqr(mj)
        
        let y2 = Secpt256k1Field.sqr(y)
        let cj = y2 * (y2 - mj * x)
        
        x = mj2 - Secpt256k1Field.two * x * y2
        
        y = mj * x + cj
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
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.isInfinity == rhs.isInfinity
    }
}

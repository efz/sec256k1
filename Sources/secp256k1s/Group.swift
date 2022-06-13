struct Secp256k1Group {
    static let curvA = Secpt256k1Field.zero
    static let curvB = Secpt256k1Field(int64: 7)
    static let infinity = Secp256k1Group()
    
    var x: Secpt256k1Field
    var y: Secpt256k1Field
    var isInfinity: Bool
    
    init() {
        x = Secpt256k1Field.zero
        y = Secpt256k1Field.zero
        isInfinity = true
    }
    
    init?(x: Secpt256k1Field, y: Secpt256k1Field) {
        self.x = x
        self.y = y
        isInfinity = false
        if !isValid() {
            return nil
        }
    }
    
    init?(x: Secpt256k1Field) {
        self.x = x
        isInfinity = false
        if let computedY = Secp256k1Group.calcY(x: x) {
            y = computedY
        } else {
            return nil
        }
    }
    
    static func calcY(x: Secpt256k1Field) -> Secpt256k1Field? {
        var computedY = x * x * x + Secp256k1Group.curvB
        let yExists = computedY.sqrt()
        return yExists ? computedY : nil
    }
    
    func isValid() -> Bool {
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
    
    mutating func add(_ b: Secp256k1Group) {
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
    
    mutating func double() {
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
    
    mutating func reflect() {
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

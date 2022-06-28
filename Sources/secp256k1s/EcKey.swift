public struct Secp256k1PrivateKey: Equatable {
    var privKey: Secpt256k1Scalar
    
    var pubKey: Secp256k1PublicKey? {
        get {
            return Secp256k1PublicKey(privKey: self)
        }
    }
    
    init?(s: Secpt256k1Scalar) {
        if s.isZero() {
            return nil
        }
        privKey = s
    }
    
    public init?(bytes: [UInt8]) {
        var overflow = false
        let tmp = Secpt256k1Scalar(bytes: bytes, overflowed: &overflow)
        if overflow || tmp.isZero() {
            return nil
        }
        
        privKey = tmp
    }
    
    public func serialize(bytes: inout [UInt8]) {
        assert(bytes.count >= 32)
        privKey.serialize(bytes: &bytes[0..<32])
    }
    
    public mutating func tweakAdd(tweak: Secpt256k1Scalar) throws {
        let r = privKey + tweak
        if r.isZero() {
            throw InvalidTweak()
        }
        privKey = r
    }
    
    public mutating func tweakMul(tweak: Secpt256k1Scalar) throws {
        if tweak.isZero() {
            throw InvalidTweak()
        }
        let r = privKey * tweak
        if r.isZero() {
            throw InvalidTweak()
        }
        privKey = r
    }
}


public struct Secp256k1PublicKey: Equatable {
    var pubKey: Secp256k1Group
    let ecmult = Secp256k1Ecmult()
    
    init?(privKey: Secp256k1PrivateKey) {
        var tmp = ecmult.gen(gn: privKey.privKey)
        guard !tmp.isInfinity else {
            return nil
        }
        tmp.normalizeJ()
        guard tmp.isValid() else {
            return nil
        }
        pubKey = tmp
    }
    
    init?(ge: Secp256k1Group) {
        if !ge.isNormalized() || !ge.isValid() || ge.isInfinity {
            return nil
        }
        
        self.pubKey = ge
    }
    
    public init?(bytes: [UInt8]) {
        let bytesEnd: Int
        let isOdd: Bool
        
        if bytes.count == 33 && (bytes[0] == 0x02 || bytes[0] == 0x03) {
            bytesEnd = 33
            isOdd =  bytes[0] == 0x03
        } else if bytes.count == 65 && (bytes[0] == 0x04 || bytes[0] == 0x06 || bytes[0] == 0x07) {
            bytesEnd = 65
            isOdd =  bytes[0] == 0x07
        } else {
            return nil
        }
        
        let tmp = Secp256k1Group(bytes: bytes[1..<bytesEnd], odd: isOdd)
        if tmp == nil {
            return nil
        }
        
        pubKey = tmp!
        if !pubKey.isNormalized() || !pubKey.isValid() || pubKey.isInfinity {
            return nil
        }
    }
    
    public func serialize(bytes: inout [UInt8], compress: Bool) {
        assert(compress ? bytes.count >= 33 : bytes.count >= 65)
        
        guard !pubKey.isInfinity && pubKey.isNormalized() && pubKey.isValid() else {
            fatalError("Invalid pk group element")
        }
        
        var code: UInt8 = compress ? 0x02 : 0x04
        code = code | (pubKey.isOdd() ? 0x03 : 0x00)
        bytes[0] = code
        pubKey.serialize(bytes: &bytes[1..<(compress ? 33 : 65)])
    }
    
    public mutating func tweakAdd(tweak: Secpt256k1Scalar) throws {
        var r = ecmult.gen(point: pubKey, gn: tweak)
        if (!r.isValidJ() || r.isInfinity) {
            throw InvalidTweak()
        }
        r.normalizeJ()
        assert(r.isValidJ() && !r.isInfinity)
        pubKey = r
    }
    
    public mutating func tweakMul(tweak: Secpt256k1Scalar) throws {
        guard !tweak.isZero() else {
            throw InvalidTweak("Mul by zero tweak")
        }
        
        var r = ecmult.gen(point: pubKey, pn: tweak)
        if (!r.isValidJ() || r.isInfinity) {
            throw InvalidTweak()
        }
        r.normalizeJ()
        assert(r.isValidJ() && !r.isInfinity)
        pubKey = r
    }
    
    public static func ==(lhs: Secp256k1PublicKey, rhs: Secp256k1PublicKey) -> Bool {
        return lhs.pubKey == rhs.pubKey
    }
}

struct InvalidTweak: Error {
    let msg: String
    
    init(_ msg: String = "") {
        self.msg = msg
    }
}

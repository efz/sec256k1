/**
 Sec256k1 private key for creating signatures.
 */
public struct Secp256k1PrivateKey: Equatable {
    var privKey: Secp256k1Scalar
    
    /**
     Public key corresponding to this private key.
     */
    public var pubKey: Secp256k1PublicKey? {
        get {
            return Secp256k1PublicKey(privKey: self)
        }
    }
    
    init() {
        let nonceGenerator = Secp256k1DefaultNonceGenerator()
        var keyGen = Secp256k1KeyGenerator(nonceGenerator)
        privKey = keyGen.genScalar()
    }
    
    init?(s: Secp256k1Scalar) {
        if s.isZero() {
            return nil
        }
        privKey = s
    }
    
    /**
     Deserialize 32 bytes array as big endian 256 bit integer.
     */
    public init?(bytes32: [UInt8]) {
        guard bytes32.count >= 32 else{
            return nil
        }
        
        var overflow = false
        let tmp = Secp256k1Scalar(bytes: bytes32[0..<32], overflowed: &overflow)
        if overflow || tmp.isZero() {
            return nil
        }
        
        privKey = tmp
    }
    
    /**
     Serialize private key in to 32 byte array as big endian 256 bit integer.
     */
    public func serialize(bytes32: inout [UInt8]) throws {
        guard bytes32.count >= 32 else {
            throw Secp256k1Error("Output less than 32 byets")
        }
        privKey.serialize(bytes: &bytes32[0..<32])
    }
    
    /**
     Adds a tweak to private key.
     */
    public mutating func tweakAdd(tweak: Secp256k1Tweak) throws {
        let r = privKey + tweak.s
        if r.isZero() {
            throw Secp256k1Error("Zero after tweak")
        }
        privKey = r
    }
    
    /**
     Multiply private key by a tweak.
     */
    public mutating func tweakMul(tweak: Secp256k1Tweak) throws {
        let r = privKey * tweak.s
        if r.isZero() {
            throw Secp256k1Error("Zero after tweak")
        }
        privKey = r
    }
}

/**
 Sec256k1 public key for verifying signatures.
 */
public struct Secp256k1PublicKey: Equatable {
    static let ecmult = Secp256k1Ecmult()
    
    var pubKey: Secp256k1Group
    
    init?(privKey: Secp256k1PrivateKey) {
        var tmp = Secp256k1PublicKey.ecmult.gen(gn: privKey.privKey)
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
    
    /**
     Deserialize compressed or uncompressed public key byte array. See ``serialize(bytes33or65:compress:)`` for valid serializations.
     */
    public init?(bytes33or65: [UInt8]) {
        self.init(bytes33or65: bytes33or65[0..<bytes33or65.count])
    }
    
    /**
     Deserialize compressed or uncompressed public key byte array. See ``serialize(bytes33or65:compress:)`` for valid serializations.
     */
    public init?(bytes33or65: ArraySlice<UInt8>) {
        let bytesEnd: Int
        var isOdd: Bool?
        
        if bytes33or65.count == 33 && (bytes33or65[bytes33or65.startIndex + 0] == 0x02 || bytes33or65[bytes33or65.startIndex + 0] == 0x03) {
            bytesEnd = 33
            isOdd =  bytes33or65[bytes33or65.startIndex + 0] == 0x03
        } else if bytes33or65.count == 65 && (bytes33or65[bytes33or65.startIndex + 0] == 0x04 || bytes33or65[bytes33or65.startIndex + 0] == 0x06 || bytes33or65[bytes33or65.startIndex + 0] == 0x07) {
            bytesEnd = 65
            isOdd =  bytes33or65[bytes33or65.startIndex + 0] == 0x07
        } else {
            return nil
        }
        
        if bytes33or65[bytes33or65.startIndex + 0] == 0x04 {
            isOdd = nil
        }
        
        let tmp = Secp256k1Group(bytes: bytes33or65[bytes33or65.startIndex+1..<bytesEnd], odd: isOdd)
        if tmp == nil {
            return nil
        }
        
        pubKey = tmp!
        if !pubKey.isNormalized() || !pubKey.isValid() || pubKey.isInfinity {
            return nil
        }
    }
    /**
     Serialize public key into 33 byte (in compressed form) or 65 byte (in none-compressed form) array.
     In compressed form, 0th  byte is either 3 (for odd key) or 2 (for even key) and bytes 1 to 33 is public key x cordinate as big endian 256 bit integer.
     In uncompressed form, 0th byte is  always 4. Bytes 1 to 33 is public key x cordinate as big endian 256 bit integer. Bytes 33 to 65 is public key y coordinate as big endina 256 bit integer.
     */
    public func serialize(bytes33or65: inout [UInt8], compress: Bool) throws {
        guard compress ? bytes33or65.count >= 33 : bytes33or65.count >= 65 else {
            throw Secp256k1Error("Output less than 33 or 65 bytes")
        }
        
        guard !pubKey.isInfinity && pubKey.isNormalized() && pubKey.isValid() else {
            throw Secp256k1Error("Invalid public key")
        }
        
        var code: UInt8 = compress ? 0x02 : 0x04
        code = code | (compress && pubKey.isOdd() ? 0x03 : 0x00)
        bytes33or65[0] = code
        pubKey.serialize(bytes: &bytes33or65[1..<(compress ? 33 : 65)])
    }
    
    /**
     Add the given tweak to public key.
     */
    public mutating func tweakAdd(tweak: Secp256k1Tweak) throws {
        var r = Secp256k1PublicKey.ecmult.gen(point: pubKey, gn: tweak.s)
        if (!r.isValidJ() || r.isInfinity) {
            throw Secp256k1Error("Invalid key after tweak")
        }
        r.normalizeJ()
        assert(r.isValidJ() && !r.isInfinity)
        pubKey = r
    }
    
    /**
     Multiplies the public key by the given tweak.
     */
    public mutating func tweakMul(tweak: Secp256k1Tweak) throws {
        var r = Secp256k1PublicKey.ecmult.gen(point: pubKey, pn: tweak.s)
        if (!r.isValidJ() || r.isInfinity) {
            throw Secp256k1Error("Invalid key after tweak")
        }
        r.normalizeJ()
        assert(r.isValidJ() && !r.isInfinity)
        pubKey = r
    }
    
    /**
     Combines multiple public keys to a single public key.
     - parameters pubKeys: Array of public keys to combine.
     */
    public mutating func combine(pubKeys: ArraySlice<Secp256k1PublicKey>) throws {
        for pk in pubKeys {
            pubKey.addJ(pk.pubKey)
        }
        if pubKey.isInfinity {
            throw Secp256k1Error()
        }
        pubKey.normalizeJ()
    }
    
    /**
     Combines multiple public keys to a single public key.
     - parameters pubKeys: Array of public keys to combine.
     */
    public static func combine(pubKeys: [Secp256k1PublicKey]) throws -> Secp256k1PublicKey {
        guard pubKeys.count >= 2 else {
            throw Secp256k1Error("Less than 2 keys")
        }
        
        var r = pubKeys[0]
        try r.combine(pubKeys: pubKeys[1..<pubKeys.count])
        return r
    }
    
    public static func ==(lhs: Secp256k1PublicKey, rhs: Secp256k1PublicKey) -> Bool {
        return lhs.pubKey == rhs.pubKey
    }
}

/**
 Tweak to add/multiply ``Secp256k1PublicKey`` or ``Secp256k1PrivateKey``.
 */
public struct Secp256k1Tweak {
    let s: Secp256k1Scalar
    
    init(s: Secp256k1Scalar) {
        self.s = s
    }
    
    /**
     - parameters bytes32: 32 byte tweak as big endian 256 bit integer.
     */
    public init?(bytes32: [UInt8]) {
        guard bytes32.count == 32 else {
            return nil
        }
        var overflow = false
        let tweak = Secp256k1Scalar(bytes: bytes32, overflowed: &overflow)
        if tweak.isZero() || overflow {
            return nil
        }
        s = tweak
    }
}

public struct Secp256k1Error: Error {
    let msg: String
    
    public init(_ msg: String = "") {
        self.msg = msg
    }
}

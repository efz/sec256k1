public struct Secp256k1Ecdsa {
    public static let defaultMaxSignAttempts = 100
    static let ecmult = Secp256k1Ecmult()
    
    var sigR: Secp256k1Scalar
    var sigS: Secp256k1Scalar
    
    init?(r: Secp256k1Scalar, s: Secp256k1Scalar) {
        if r.isZero() || s.isZero() {
            return nil
        }
        
        sigR = r
        sigS = s
    }
    
    public init?(bytes64: [UInt8]) {
        guard bytes64.count >= 64 else {
            return nil
        }
        
        var overflow = false
        sigR = Secp256k1Scalar(bytes: bytes64[0..<32], overflowed: &overflow)
        if overflow || sigR.isZero() {
            return nil
        }
        sigS = Secp256k1Scalar(bytes: bytes64[32..<64], overflowed: &overflow)
        if overflow || sigS.isZero() {
            return nil
        }
    }
    
    public func isNormalized() -> Bool {
        return !sigS.isHigherThanHalfP()
    }
    
    public mutating func normalize() {
        if sigS.isHigherThanHalfP() {
            sigS.negate()
        }
    }
    
    public func serialize(bytes64: inout [UInt8]) throws {
        guard bytes64.count >= 64 else {
            throw Secp256k1Error("Output less than 64 bytes")
        }
        sigR.serialize(bytes: &bytes64[0..<32])
        sigS.serialize(bytes: &bytes64[32..<64])
    }
    
    init?(message: Secp256k1Message, nonce: Secp256k1Scalar, privateKey: Secp256k1PrivateKey) {
        assert(!nonce.isZero())
        
        var rg = Self.ecmult.gen(gn: nonce)
        if rg.isInfinity || !rg.isValidJ() {
            return nil
        }
        
        rg.normalizeJ()
        if rg.isInfinity || !rg.isValid() {
            return nil
        }
        
        var overflowed = false
        sigR = Secp256k1Scalar(bits64x4: rg.x.d, overflowed:&overflowed)
        if sigR.isZero() {
            return nil
        }
        
        let nonceInv = Secp256k1Scalar.inv(nonce)
        sigS = nonceInv * (message.s + privateKey.privKey * sigR)
        if sigS.isZero() {
            return nil
        }
        
        normalize()
    }
    
    public func verify(message: Secp256k1Message, publicKey: Secp256k1PublicKey) -> Bool {
        let w = Secp256k1Scalar.inv(sigS)
        let u1 = message.s * w
        let u2 = sigR * w
        
        let xy =  Secp256k1Ecdsa.ecmult.gen(point: publicKey.pubKey, pn: u2, gn: u1)
        if xy.isInfinity {
            return false
        }
        return xy.isSame(scalarX: sigR)
    }
}

public protocol Secp256k1NonceGenerator {
    mutating func genNonce(bytes32: inout [UInt8])
}

public class Secp256k1DefaultNonceGenerator: Secp256k1NonceGenerator {
    var rfc6979HmacSha256: Secp256k1Rfc6979HmacSha256
    
    public init(seed: [UInt8]) {
        rfc6979HmacSha256 =  Secp256k1Rfc6979HmacSha256(key: seed)
    }
    
    public init() {
        let seed = (0..<16).map() { _ in
            UInt8(UInt16.random(in: 0..<256))
        }
        rfc6979HmacSha256 =  Secp256k1Rfc6979HmacSha256(key: seed)
    }
    
    public func genNonce(bytes32: inout [UInt8]) {
        assert(bytes32.count >= 32)
        rfc6979HmacSha256.generate(rand: &bytes32)
    }
}

struct Secp256k1KeyGenerator {
    var nonceGenerator: Secp256k1NonceGenerator
    
    init() {
        nonceGenerator = Secp256k1DefaultNonceGenerator()
    }
    
    init(_ generator: Secp256k1NonceGenerator) {
        nonceGenerator = generator
    }
    
    mutating func genPrivateKeyWithBytes() -> (Secp256k1PrivateKey, [UInt8]) {
        var bytes = [UInt8](repeating: 0, count: 32)
        var priveKey: Secp256k1PrivateKey? = nil
        var priveKeyBytes: [UInt8] = []
        while priveKey == nil {
            nonceGenerator.genNonce(bytes32: &bytes)
            (priveKeyBytes, priveKey) = (bytes, Secp256k1PrivateKey(bytes32: bytes))
        }
        
        return (priveKey!, priveKeyBytes)
    }
    
    mutating func genPrivateKey() -> Secp256k1PrivateKey {
        return genPrivateKeyWithBytes().0
    }
    
    mutating func genBytes32() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 32)
        nonceGenerator.genNonce(bytes32: &bytes)
        return bytes
    }
    
    mutating func genScalar() -> Secp256k1Scalar {
        let bytes = genBytes32()
        
        var overflow = false
        var scalar = Secp256k1Scalar.zero
        while scalar.isZero() || overflow {
            scalar = Secp256k1Scalar(bytes: bytes, overflowed: &overflow)
        }
        
        return scalar
    }
    
    mutating func genMessage() -> Secp256k1Message {
        return Secp256k1Message(s: genScalar())
    }
}

public struct Secp256k1Message {
    let s: Secp256k1Scalar
    
    init(s: Secp256k1Scalar) {
        self.s = s
    }
    
    public init?(bytes32: [UInt8]) {
        guard bytes32.count >= 32 else {
            return nil
        }
        
        var overflow = false
        s = Secp256k1Scalar(bytes: bytes32, overflowed: &overflow)
    }
    
    public func sign(privateKey: Secp256k1PrivateKey, nonceGenerator: Secp256k1NonceGenerator, maxAttemts: Int = Secp256k1Ecdsa.defaultMaxSignAttempts) -> Secp256k1Ecdsa? {
        var signature: Secp256k1Ecdsa? = nil
        var keyGenerator = Secp256k1KeyGenerator(nonceGenerator)
        var attemptsLeft = maxAttemts
        while signature == nil && attemptsLeft != 0 {
            let nonce = keyGenerator.genScalar()
            signature = Secp256k1Ecdsa(message: self, nonce: nonce, privateKey: privateKey)
            attemptsLeft -= 1
        }
        return signature
    }
    
    public func verify(signature: Secp256k1Ecdsa, publicKey: Secp256k1PublicKey) -> Bool {
        return signature.verify(message: self, publicKey: publicKey)
    }
}

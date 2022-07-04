public struct Secp256k1Edsa {
    static let ecmult = Secp256k1Ecmult()
    
    var sigR: Secp256k1Scalar
    var sigS: Secp256k1Scalar
    
    init?(r: Secp256k1Scalar, s: Secp256k1Scalar) {
        if r.isZero() || s.isZero() || s.isHigherThanHalfP() {
            return nil
        }
        
        sigR = r
        sigS = s
    }
    
    public init?(bytes: [UInt8]) {
        assert(bytes.count >= 64)
        var overflow = false
        sigR = Secp256k1Scalar(bytes: bytes[0..<32], overflowed: &overflow)
        if overflow || sigR.isZero() {
            return nil
        }
        sigS = Secp256k1Scalar(bytes: bytes[32..<64], overflowed: &overflow)
        if overflow || sigS.isZero() || sigS.isHigherThanHalfP() {
            return nil
        }
    }
    
    public func serialize(bytes: inout [UInt8]) {
        assert(bytes.count >= 64)
        sigR.serialize(bytes: &bytes[0..<32])
        sigS.serialize(bytes: &bytes[32..<64])
    }
    
    public init?(message: Secp256k1Scalar, nonce: Secp256k1Scalar, privateKey: Secp256k1PrivateKey) {
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
        sigS = nonceInv * (message + privateKey.privKey * sigR)
        if sigS.isZero() {
            return nil
        }
        
        if sigS.isHigherThanHalfP() {
            sigS.negate()
        }
    }
    
    public func validate(message: Secp256k1Scalar, publicKey: Secp256k1PublicKey) -> Bool {
        let w = Secp256k1Scalar.inv(sigS)
        let u1 = message * w
        let u2 = sigR * w
        
        let xy =  Secp256k1Edsa.ecmult.gen(point: publicKey.pubKey, pn: u2, gn: u1)
        if xy.isInfinity {
            return false
        }
        return xy.isSame(scalarX: sigR)
    }
    
    public static func sign(message: Secp256k1Scalar,  privateKey: Secp256k1PrivateKey, nonceGenerator: NonceGenerator) -> Secp256k1Edsa {
        var signature: Secp256k1Edsa? = nil
        var keyGenerator = KeyGenerator(nonceGenerator)
        
        while signature == nil {
            let nonce = keyGenerator.genScalar()
            signature = Secp256k1Edsa(message: message, nonce: nonce, privateKey: privateKey)
        }
        return signature!
    }
}

public protocol NonceGenerator {
    mutating func genNonce(bytes32: inout [UInt8])
}

public class DefaultNonceGenerator: NonceGenerator {
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

struct KeyGenerator {
    var nonceGenerator: NonceGenerator
    
    init() {
        nonceGenerator = DefaultNonceGenerator()
    }
    
    init(_ generator: NonceGenerator) {
        nonceGenerator = generator
    }
    
    mutating func genPrivateKeyWithBytes() -> (Secp256k1PrivateKey, [UInt8]) {
        var bytes = [UInt8](repeating: 0, count: 32)
        var priveKey: Secp256k1PrivateKey? = nil
        var priveKeyBytes: [UInt8] = []
        while priveKey == nil {
            nonceGenerator.genNonce(bytes32: &bytes)
            (priveKeyBytes, priveKey) = (bytes, Secp256k1PrivateKey(bytes: bytes))
        }
        
        return (priveKey!, priveKeyBytes)
    }
    
    mutating func genPrivateKey() -> Secp256k1PrivateKey {
        return genPrivateKeyWithBytes().0
    }
    
    mutating func genScalar() -> Secp256k1Scalar {
        var bytes = [UInt8](repeating: 0, count: 32)
        nonceGenerator.genNonce(bytes32: &bytes)
        
        var overflow = false
        var scalar = Secp256k1Scalar.zero
        while scalar.isZero() || overflow {
            scalar = Secp256k1Scalar(bytes: bytes, overflowed: &overflow)
        }
        
        return scalar
    }
}

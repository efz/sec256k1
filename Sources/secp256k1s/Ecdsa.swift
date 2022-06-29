struct Secp256k1Edsa {
    static let ecmult = Secp256k1Ecmult()
    
    var sigR: Secp256k1Scalar
    var sigS: Secp256k1Scalar
    
    init(r: Secp256k1Scalar, s: Secp256k1Scalar) {
        sigR = r
        sigS = s
    }
    
    init?(message: Secp256k1Scalar, nonce: Secp256k1Scalar, privateKey: Secp256k1PrivateKey) {
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
    
    func validate(message: Secp256k1Scalar, publicKey: Secp256k1PublicKey) -> Bool {
        let w = Secp256k1Scalar.inv(sigS)
        let u1 = message * w
        let u2 = sigR * w
        
        var xy =  Secp256k1Edsa.ecmult.gen(point: publicKey.pubKey, pn: u2, gn: u1)
        if xy.isInfinity {
            return false
        }
        xy.normalizeJ()
        if xy.isInfinity {
            return false
        }
        var overflow = false
        let xScalar = Secp256k1Scalar(bits64x4: xy.x.d, overflowed: &overflow)
        return sigR == xScalar
    }
}

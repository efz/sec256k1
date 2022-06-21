struct Secp256k1Ecmult {
    static let g = Secp256k1Group(
        x: Secpt256k1Field(words64: [0x59F2815B_16F81798, 0x029BFCDB_2DCE28D9, 0x55A06295_CE870B07, 0x79BE667E_F9DCBBAC]),
        y: Secpt256k1Field(words64: [0x9C47D08F_FB10D4B8, 0xFD17B448_A6855419, 0x5DA4FBFC_0E1108A8, 0x483ADA77_26A3C465]))!
    
    static let gMultTable: [[Secp256k1Group]] = { () -> [[Secp256k1Group]] in
        var res = [[Secp256k1Group]](repeating: [], count: 64)
        var gBase = Secp256k1Ecmult.g
        
        for i in 0..<64 {
            var precj_i0 = Secp256k1Group.infinity
            res[i].append(precj_i0)
            
            for k in 1..<16 {
                var precj_ij = res[i][k-1]
                precj_ij.addAffine2J(gBase)
                precj_ij.normalizeJ()
                res[i].append(precj_ij)
            }
            assert(res[i].count == 16)
            
            for _ in 0..<4 {
                gBase.doubleJ()
            }
            gBase.normalizeJ()
        }
        
        assert({() -> Bool in
            var valid = true
            for i in 0..<64 {
                for k in 0..<16 {
                    valid = valid && (!res[i][k].isInfinity || k == 0) && res[i][k].z.isOne()
                }
            }
            return valid
        }())
        
        return res
    }();
    
    func gen(gn: Secpt256k1Scalar) -> Secp256k1Group {
        var res = Secp256k1Group.infinity
        for i in 0..<64 {
            let idx = gn.getBits(offset: i * 4, count: 4)
            let prec = Secp256k1Ecmult.gMultTable[i][idx]
            res.addAffine2J(prec)
            assert(res.isValidJ())
        }
        assert(!res.isInfinity || gn.isZero())
        assert(res.isValidJ())
        return res
    }
    
    func gen(point p: Secp256k1Group, pn: Secpt256k1Scalar) -> Secp256k1Group {
        var res = Secp256k1Group.infinity
        var dummy = Secp256k1Group.infinity
        var pPow = p
        var mask: UInt64 = 1
        for _ in 0..<Secpt256k1Scalar.wordBitWidth {
            if pn.d.0 & mask != 0 {
                res.addJ(pPow)
            } else {
                dummy.addJ(pPow)
            }
            
            pPow.doubleJ()
            mask = mask << 1
        }
        mask = 1
        for _ in 0..<Secpt256k1Scalar.wordBitWidth {
            if pn.d.1 & mask != 0 {
                res.addJ(pPow)
            } else {
                dummy.addJ(pPow)
            }
            
            pPow.doubleJ()
            mask = mask << 1
        }
        mask = 1
        for _ in 0..<Secpt256k1Scalar.wordBitWidth {
            if pn.d.2 & mask != 0 {
                res.addJ(pPow)
            } else {
                dummy.addJ(pPow)
            }
            
            pPow.doubleJ()
            mask = mask << 1
        }
        mask = 1
        for _ in 0..<Secpt256k1Scalar.wordBitWidth {
            if pn.d.3 & mask != 0 {
                res.addJ(pPow)
            } else {
                dummy.addJ(pPow)
            }
            
            pPow.doubleJ()
            mask = mask << 1
        }
        
        assert(!res.isInfinity || pn.isZero())
        assert(res.isValidJ())
        return res
    }
}

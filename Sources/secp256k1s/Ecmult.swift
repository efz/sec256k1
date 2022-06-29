struct Secp256k1Ecmult {
    static let g = Secp256k1Group(
        x: Secp256k1Field(words64: [0x59F2815B_16F81798, 0x029BFCDB_2DCE28D9, 0x55A06295_CE870B07, 0x79BE667E_F9DCBBAC]),
        y: Secp256k1Field(words64: [0x9C47D08F_FB10D4B8, 0xFD17B448_A6855419, 0x5DA4FBFC_0E1108A8, 0x483ADA77_26A3C465]))!
    
    let gMultTable: [[Secp256k1Group]]
    
    init() {
        var res = [[Secp256k1Group]](repeating: [], count: 64)
        var gBase = Secp256k1Ecmult.g
        
        for i in 0..<64 {
            let precj_i0 = Secp256k1Group.infinity
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
        
        gMultTable = res
    }
    
    func gen(gn: Secp256k1Scalar) -> Secp256k1Group {
        var res = Secp256k1Group.infinity
        for i in 0..<64 {
            let idx = gn.getBits(offset: i * 4, count: 4)
            let prec = gMultTable[i][idx]
            res.addAffine2J(prec)
            assert(res.isValidJ())
        }
        assert(!res.isInfinity || gn.isZero())
        assert(res.isValidJ())
        return res
    }
    
    func gen(point p: Secp256k1Group, pn: Secp256k1Scalar) -> Secp256k1Group {
        var res = Secp256k1Group.infinity
        var prec = [Secp256k1Group](repeating: Secp256k1Group.infinity, count: 16)
        
        if p.isNormalized() {
            for i in 1..<16 {
                prec[i] = prec[i - 1]
                prec[i].addAffine2J(p)
            }
        } else {
            for i in 1..<16 {
                prec[i] = prec[i - 1]
                prec[i].addJ(p)
            }
        }
        
        for shift in stride(from: 60, through: 0, by: -4) {
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            let precIdx = Int(pn.d.3 >> shift & 0xF)
            res.addJ(prec[precIdx])
        }
        
        for shift in stride(from: 60, through: 0, by: -4) {
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            let precIdx = Int(pn.d.2 >> shift & 0xF)
            res.addJ(prec[precIdx])
        }
        
        for shift in stride(from: 60, through: 0, by: -4) {
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            let precIdx = Int(pn.d.1 >> shift & 0xF)
            res.addJ(prec[precIdx])
            
        }
        
        for shift in stride(from: 60, through: 0, by: -4) {
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            res.doubleJ()
            let precIdx = Int(pn.d.0 >> shift & 0xF)
            res.addJ(prec[precIdx])
        }
        
        assert(!res.isInfinity || pn.isZero())
        assert(res.isValidJ())
        return res
    }
    
    func gen(point p: Secp256k1Group, gn: Secp256k1Scalar) -> Secp256k1Group {
        let gpn = gen(gn: gn)
        
        var res = p
        res.addJ(gpn)
        return res
    }
    
    func gen(point p: Secp256k1Group, pn: Secp256k1Scalar, gn: Secp256k1Scalar) -> Secp256k1Group {
        let gpn = gen(gn: gn)
        let ppn = gen(point: p, pn: pn)
        
        var res = gpn
        res.addJ(ppn)
        return res
    }
}

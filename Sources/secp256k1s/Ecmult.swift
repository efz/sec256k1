struct Secp256k1Ecmult {
    static let g = Secp256k1Group(
        x: Secp256k1Field(words64: [0x59F2815B_16F81798, 0x029BFCDB_2DCE28D9, 0x55A06295_CE870B07, 0x79BE667E_F9DCBBAC]),
        y: Secp256k1Field(words64: [0x9C47D08F_FB10D4B8, 0xFD17B448_A6855419, 0x5DA4FBFC_0E1108A8, 0x483ADA77_26A3C465]))!
    
    let gMultTable4BitFull: [[Secp256k1Group]]
    let gMultTable5BitPartial: [Secp256k1Group]
    
    init() {
        // Gen full 4 bit table
        var fullTbl = [[Secp256k1Group]](repeating: [], count: 64)
        var gBase = Secp256k1Ecmult.g
        
        for i in 0..<64 {
            let precj_i0 = Secp256k1Group.infinity
            fullTbl[i].append(precj_i0)
            
            for k in 1..<16 {
                var precj_ij = fullTbl[i][k-1]
                precj_ij.addAffine2J(gBase)
                precj_ij.normalizeJ()
                fullTbl[i].append(precj_ij)
            }
            assert(fullTbl[i].count == 16)
            
            for _ in 0..<4 {
                gBase.doubleJ()
            }
            gBase.normalizeJ()
        }
        
        assert({() -> Bool in
            var valid = true
            for i in 0..<64 {
                for k in 0..<16 {
                    valid = valid && (!fullTbl[i][k].isInfinity || k == 0) && fullTbl[i][k].z.isOne()
                }
            }
            return valid
        }())
        
        gMultTable4BitFull = fullTbl
        
        // Gen partial 8 bit table
        gBase = Secp256k1Ecmult.g
        var partialTbl = [Secp256k1Group](repeating: Secp256k1Group.infinity, count: 32)
        for k in 1..<32 {
            var precj_k = partialTbl[k-1]
            precj_k.addAffine2J(gBase)
            precj_k.normalizeJ()
            partialTbl[k] = precj_k
        }
        
        gMultTable5BitPartial = partialTbl
        
        assert({
            var valid = true
            for i in 0..<16 {
                valid = valid && gMultTable4BitFull[0][i&0xF] == gMultTable5BitPartial[i]
            }
            return valid
        }())
        
    }
    
    func gen(gn: Secp256k1Scalar) -> Secp256k1Group {
        var res = Secp256k1Group.infinity
        for i in 0..<64 {
            let idx = gn.getBits(offset: i * 4, count: 4)
            let prec = gMultTable4BitFull[i][idx]
            res.addAffine2J(prec)
            assert(res.isValidJ())
        }
        assert(!res.isInfinity || gn.isZero())
        assert(res.isValidJ())
        return res
    }
    
    @inline(__always)
    private func gen(point p: Secp256k1Group, _ pn: Secp256k1Scalar, _ prec: [Secp256k1Group]) -> Secp256k1Group {
        var res = Secp256k1Group.infinity
        var shift = 252
        while shift >= 0 {
            let precIdx = pn.getBits(offset: shift, count: 4)
            if precIdx >= 8 {
                res.doubleJ()
                res.doubleJ()
                res.doubleJ()
                res.doubleJ()
                res.addJ(prec[Int(precIdx & 0x7)])
                shift -= 4
            } else {
                res.doubleJ()
                shift -= 1
            }
        }
        assert(shift < 0 && shift >= -4)
        
        let addFunc = p.isNormalized() ? { res.addAffine2J(p) } : { res.addJ(p) }
        
        for i in (0..<shift+4).reversed() {
            res.doubleJ()
            if pn.getBits(offset: i, count: 1) == 1 {
                addFunc()
            }
        }
        return res
    }
    
    func gen(point p: Secp256k1Group, pn: Secp256k1Scalar) -> Secp256k1Group {
        var prec = [Secp256k1Group](repeating: Secp256k1Group.infinity, count: 8)
        
        var p8 = p
        p8.doubleJ()
        p8.doubleJ()
        p8.doubleJ()
        
        prec[0] = p8
        if p.isNormalized() {
            for i in 1..<8 {
                prec[i] = prec[i - 1]
                prec[i].addAffine2J(p)
            }
        } else {
            for i in 1..<8 {
                prec[i] = prec[i - 1]
                prec[i].addJ(p)
            }
        }
        
        let res = gen(point: p, pn, prec)
        
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
        
        var res = Secp256k1Group.infinity
        
        var i = 255
        var pAt = 256
        var gAt = 256
        while i >= 0 {
            res.doubleJ()
            
            if pAt - i >= 4 {
                let precIdx = pn.getBits(offset: i, count: 4)
                if precIdx >= 8 {
                    res.addJ(prec[precIdx])
                    pAt = i
                }
            }
            
            if gAt - i >= 5 {
                let precIdx = gn.getBits(offset: i, count: 5)
                if precIdx >= 16 {
                    res.addAffine2J(gMultTable5BitPartial[precIdx])
                    gAt = i
                }
            }
            
            i -= 1
        }
        if pAt >= 4 {
            pAt = 3
        }
        if gAt >= 5 {
            gAt = 4
        }
        if pAt < 4 {
            let precIdx = pn.getBits(offset: 0, count: pAt)
            res.addJ(prec[precIdx])
        }
        if gAt < 5 {
            let precIdx = gn.getBits(offset: 0, count: gAt)
            res.addAffine2J(gMultTable5BitPartial[precIdx])
        }
        
        assert(!res.isInfinity || pn.isZero())
        assert(res.isValidJ())
        return res
    }
}

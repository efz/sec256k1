typealias Bits64x2 = (UInt64, UInt64)
typealias Bits64x3 = (UInt64, UInt64, UInt64)
typealias Bits64x4 = (UInt64, UInt64, UInt64, UInt64)
typealias Bits64x5 = (UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x6 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x7 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x8 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)

struct Accumulator {
    var c0, c1, c2: UInt64
    
    init() {
        (c0, c1, c2) = (0, 0, 0)
    }
    
    init(_ val: UInt64) {
        (c0, c1, c2) = (val, 0, 0)
    }
    
    mutating func reset (_ val: UInt64) {
        (c0, c1, c2) = (val, 0, 0)
    }
    
    @inline(__always)
    mutating func mulAddFast(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        c1 += hi
        assert(c2 == 0)
    }
    
    @inline(__always)
    mutating func mulAdd(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c1, overflow) = c1.addingReportingOverflow(hi)
        c2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func mulAdd2(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        var hiCopy = hi
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c1, overflow) = c1.addingReportingOverflow(hi)
        c2 += overflow ? 1 : 0
        
        (c0, overflow) = c0.addingReportingOverflow(lo)
        hiCopy += overflow ? 1 : 0
        (c1, overflow) = c1.addingReportingOverflow(hiCopy)
        c2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func sumAdd(_ x: UInt64) {
        var overflow = false
        (c0, overflow) = c0.addingReportingOverflow(x)
        (c1, overflow) = c1.addingReportingOverflow(overflow ? 1 : 0)
        c2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func sumAddFast(_ x: UInt64) {
        var overflow = false
        (c0, overflow) = c0.addingReportingOverflow(x)
        c1 += overflow ? 1 : 0
        assert(c2 == 0)
    }
    
    @inline(__always)
    mutating func extractFast() -> UInt64 {
        defer {
            (c0, c1) = (c1, 0)
            assert(c2 == 0)
        }
        return c0
    }
    
    @inline(__always)
    mutating func extract() -> UInt64 {
        defer {
            (c0, c1, c2) = (c1, c2, 0)
        }
        return c0
    }
    
    func isZero() -> Bool {
        return (c0, c1, c2) == (0, 0, 0)
    }
}

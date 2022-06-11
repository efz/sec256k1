typealias Bits64x2 = (UInt64, UInt64)
typealias Bits64x3 = (UInt64, UInt64, UInt64)
typealias Bits64x4 = (UInt64, UInt64, UInt64, UInt64)
typealias Bits64x5 = (UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x6 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x7 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
typealias Bits64x8 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)

struct Accumulator {
    var c: (UInt64, UInt64, UInt64)
    
    init() {
        c = (0, 0, 0)
    }
    
    init(_ val: UInt64) {
        c = (val, 0, 0)
    }
    
    @inline(__always)
    mutating func reset (_ val: UInt64) {
        c = (val, 0, 0)
    }
    
    @inline(__always)
    mutating func mulAddFast(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        c.1 += hi
        assert(c.2 == 0)
    }
    
    @inline(__always)
    mutating func mulAdd(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c.1, overflow) = c.1.addingReportingOverflow(hi)
        c.2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func mulAdd2(_ x: UInt64, _ y: UInt64) {
        var overflow = false
        var (hi, lo) = x.multipliedFullWidth(by: y)
        var hiCopy = hi
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hi += overflow ? 1 : 0
        (c.1, overflow) = c.1.addingReportingOverflow(hi)
        c.2 += overflow ? 1 : 0
        
        (c.0, overflow) = c.0.addingReportingOverflow(lo)
        hiCopy += overflow ? 1 : 0
        (c.1, overflow) = c.1.addingReportingOverflow(hiCopy)
        c.2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func sumAdd(_ x: UInt64) {
        var overflow = false
        (c.0, overflow) = c.0.addingReportingOverflow(x)
        (c.1, overflow) = c.1.addingReportingOverflow(overflow ? 1 : 0)
        c.2 += overflow ? 1 : 0
    }
    
    @inline(__always)
    mutating func sumAddFast(_ x: UInt64) {
        var overflow = false
        (c.0, overflow) = c.0.addingReportingOverflow(x)
        c.1 += overflow ? 1 : 0
        assert(c.2 == 0)
    }
    
    @inline(__always)
    mutating func extractFast() -> UInt64 {
        defer {
            (c.0, c.1) = (c.1, 0)
            assert(c.2 == 0)
        }
        return c.0
    }
    
    @inline(__always)
    mutating func extract() -> UInt64 {
        defer {
            c = (c.1, c.2, 0)
        }
        return c.0
    }
    
    func isZero() -> Bool {
        return c == (0, 0, 0)
    }
}

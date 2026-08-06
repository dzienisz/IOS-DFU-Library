// `XCTest` is not supported for watchOS Simulator.
#if !os(watchOS)
import XCTest
@testable import NordicDFU

/**
 Tests for the pure Secure DFU object arithmetic. These cover the resume/offset
 edge cases that used to crash `SecureDFUExecutor` (index out of range in
 `createDataObject(_:)` and the resume-range calculation in `sendDataObject(_:from:)`).
 */
class SecureDFUObjectGeometryTests: XCTestCase {

    // MARK: - ranges(dataSize:maxObjectLength:)

    func testRangesFirmwareSmallerThanObject() {
        let ranges = SecureDFUObjectGeometry.ranges(dataSize: 3000, maxObjectLength: 4096)
        XCTAssertEqual(ranges, [0 ..< 3000])
    }

    func testRangesExactObjectSize() {
        let ranges = SecureDFUObjectGeometry.ranges(dataSize: 4096, maxObjectLength: 4096)
        XCTAssertEqual(ranges, [0 ..< 4096])
    }

    func testRangesWithRemainder() {
        let ranges = SecureDFUObjectGeometry.ranges(dataSize: 5000, maxObjectLength: 4096)
        XCTAssertEqual(ranges, [0 ..< 4096, 4096 ..< 5000])
    }

    func testRangesExactMultiple() {
        let ranges = SecureDFUObjectGeometry.ranges(dataSize: 8192, maxObjectLength: 4096)
        XCTAssertEqual(ranges, [0 ..< 4096, 4096 ..< 8192])
    }

    func testRangesAreContiguousAndCoverWholeFirmware() {
        let dataSize = 20_001
        let ranges = SecureDFUObjectGeometry.ranges(dataSize: dataSize, maxObjectLength: 4096)

        XCTAssertEqual(ranges.first?.lowerBound, 0)
        XCTAssertEqual(ranges.last?.upperBound, dataSize)
        for (previous, next) in zip(ranges, ranges.dropFirst()) {
            XCTAssertEqual(previous.upperBound, next.lowerBound, "Ranges must be contiguous")
        }
        XCTAssertEqual(ranges.reduce(0) { $0 + $1.count }, dataSize, "Ranges must cover every byte")
    }

    // MARK: - objectIndex(forOffset:maxObjectLength:objectCount:)

    func testObjectIndexAtStart() {
        // 5000 bytes -> [0..<4096, 4096..<5000], count == 2
        XCTAssertEqual(index(offset: 0, maxLen: 4096, count: 2), 0)
    }

    func testObjectIndexWithinFirstObject() {
        XCTAssertEqual(index(offset: 4095, maxLen: 4096, count: 2), 0)
    }

    func testObjectIndexAtObjectBoundary() {
        XCTAssertEqual(index(offset: 4096, maxLen: 4096, count: 2), 1)
    }

    func testObjectIndexWithinLastObject() {
        XCTAssertEqual(index(offset: 4500, maxLen: 4096, count: 2), 1)
    }

    /// Regression: peripheral reports the whole (non-multiple) firmware as received.
    /// The offset equals `dataSize`, which is contained in no half-open range; the
    /// old search returned `count`, indexing one past the end and crashing.
    func testObjectIndexAtEndOfNonMultipleFirmwareClampsToLastObject() {
        // 5000 bytes -> count == 2. offset == 5000.
        XCTAssertEqual(index(offset: 5000, maxLen: 4096, count: 2), 1)
    }

    /// Regression: whole firmware received when the size is an exact multiple.
    func testObjectIndexAtEndOfExactMultipleFirmwareClampsToLastObject() {
        // 8192 bytes -> count == 2. offset == 8192.
        XCTAssertEqual(index(offset: 8192, maxLen: 4096, count: 2), 1)
    }

    /// Regression: a misbehaving peripheral reporting more bytes than exist must
    /// still yield a valid index rather than crash.
    func testObjectIndexBeyondEndClampsToLastObject() {
        XCTAssertEqual(index(offset: 99_999, maxLen: 4096, count: 2), 1)
    }

    func testObjectIndexNeverExceedsBoundsAcrossWholeFirmware() {
        let dataSize = 5000
        let maxLen = 4096
        let count = SecureDFUObjectGeometry.ranges(dataSize: dataSize, maxObjectLength: maxLen).count
        for offset in 0...dataSize {
            let idx = SecureDFUObjectGeometry.objectIndex(forOffset: offset,
                                                          maxObjectLength: maxLen,
                                                          objectCount: count)
            XCTAssertTrue((0 ..< count).contains(idx), "offset \(offset) produced out-of-bounds index \(idx)")
        }
    }

    // MARK: - resumeRange(of:from:)

    func testResumeRangeReturnsRemainderOfObject() {
        // Resuming object [4096, 8192) from offset 6000 -> [6000, 8192).
        let range = SecureDFUObjectGeometry.resumeRange(of: 4096 ..< 8192, from: 6000)
        XCTAssertEqual(range, 6000 ..< 8192)
    }

    func testResumeRangeFromLastObject() {
        // Last (partial) object [4096, 5000) resumed from 4700 -> [4700, 5000).
        let range = SecureDFUObjectGeometry.resumeRange(of: 4096 ..< 5000, from: 4700)
        XCTAssertEqual(range, 4700 ..< 5000)
    }

    /// The upper bound must not depend on the object's lower bound / any external
    /// offset — only on the object's end. (Guards against the previous
    /// `upperBound - offset + resumeOffset` formulation.)
    func testResumeRangeUpperBoundIsObjectEndRegardlessOfLowerBound() {
        let range = SecureDFUObjectGeometry.resumeRange(of: 12_288 ..< 16_384, from: 15_000)
        XCTAssertEqual(range.upperBound, 16_384)
        XCTAssertEqual(range.lowerBound, 15_000)
    }

    // MARK: - Helpers

    private func index(offset: Int, maxLen: Int, count: Int) -> Int {
        return SecureDFUObjectGeometry.objectIndex(forOffset: offset,
                                                   maxObjectLength: maxLen,
                                                   objectCount: count)
    }
}
#endif

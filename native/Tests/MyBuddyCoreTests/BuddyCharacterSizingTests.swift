import XCTest
@testable import MyBuddyCore

final class BuddyCharacterSizingTests: XCTestCase {
    func testPresetsExposeReadableSizesWithinAllowedRange() {
        let presets = BuddyCharacterSizing.presets

        XCTAssertEqual(presets.map(\.label), ["XS", "S", "M", "L", "XL"])
        XCTAssertEqual(presets.first?.size, 104)
        XCTAssertTrue(presets.contains { $0.size == BuddyGeometry.defaultCharacterSize })

        for preset in presets {
            XCTAssertGreaterThanOrEqual(preset.size, BuddyGeometry.minimumCharacterSize)
            XCTAssertLessThanOrEqual(preset.size, BuddyGeometry.maximumCharacterSize)
        }
    }

    func testStepAdjustmentUsesFixedIncrementAndClampsToBounds() {
        XCTAssertEqual(
            BuddyCharacterSizing.adjustedSize(from: 176, stepCount: 1),
            192
        )
        XCTAssertEqual(
            BuddyCharacterSizing.adjustedSize(from: 176, stepCount: -1),
            160
        )
        XCTAssertEqual(
            BuddyCharacterSizing.adjustedSize(from: 999, stepCount: 1),
            BuddyGeometry.maximumCharacterSize
        )
        XCTAssertEqual(
            BuddyCharacterSizing.adjustedSize(from: 20, stepCount: -1),
            BuddyGeometry.minimumCharacterSize
        )
    }

    func testFindsPresetByIdentifierAndExactSize() {
        XCTAssertEqual(
            BuddyCharacterSizing.preset(id: "medium")?.size,
            BuddyGeometry.defaultCharacterSize
        )
        XCTAssertEqual(
            BuddyCharacterSizing.presetId(exactlyMatchingSize: BuddyGeometry.defaultCharacterSize),
            "medium"
        )
        XCTAssertNil(BuddyCharacterSizing.preset(id: "missing"))
        XCTAssertNil(BuddyCharacterSizing.presetId(exactlyMatchingSize: 177))
    }
}

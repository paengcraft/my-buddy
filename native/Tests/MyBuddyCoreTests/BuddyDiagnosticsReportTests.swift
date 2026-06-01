import XCTest
@testable import MyBuddyCore

final class BuddyDiagnosticsReportTests: XCTestCase {
    func testFormatsDiagnosticsAsCopyablePlainText() {
        let report = BuddyDiagnosticsReport(items: [
            BuddyDiagnosticsItem(label: "App", value: "My Buddy"),
            BuddyDiagnosticsItem(label: "Relay", value: "Relay connected"),
            BuddyDiagnosticsItem(label: "Code", value: "ABCD2345")
        ])

        XCTAssertEqual(
            report.text,
            """
            My Buddy Diagnostics
            App: My Buddy
            Relay: Relay connected
            Code: ABCD2345
            """
        )
    }
}

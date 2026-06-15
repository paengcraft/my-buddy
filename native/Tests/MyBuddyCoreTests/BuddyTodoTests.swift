import XCTest
@testable import MyBuddyCore

final class BuddyTodoTests: XCTestCase {
    func testPreparesTrimmedTodoTextWithinLimit() {
        XCTAssertEqual(BuddyTodoInputPolicy.preparedText("  릴레이 확인  "), "릴레이 확인")
    }

    func testRejectsEmptyAndOversizedTodoText() {
        XCTAssertNil(BuddyTodoInputPolicy.preparedText("   "))
        XCTAssertNil(BuddyTodoInputPolicy.preparedText(String(repeating: "가", count: BuddyTodoInputPolicy.maximumTextLength + 1)))
    }

    func testMergeKeepsLatestUpdatedItem() {
        let older = BuddyTodoItem(
            id: "todo-1",
            text: "초대 코드 정리",
            isDone: false,
            createdAt: 10,
            createdByDeviceId: "me",
            updatedAt: 20,
            updatedByDeviceId: "me"
        )
        let newer = BuddyTodoItem(
            id: "todo-1",
            text: "초대 코드 정리 완료",
            isDone: true,
            createdAt: 10,
            createdByDeviceId: "me",
            updatedAt: 30,
            updatedByDeviceId: "buddy"
        )

        let merged = BuddyTodoSyncPolicy.merged(
            local: BuddyTodoSnapshot(items: [older], deletions: []),
            remote: BuddyTodoSnapshot(items: [newer], deletions: [])
        )

        XCTAssertEqual(merged.items, [newer])
        XCTAssertTrue(merged.deletions.isEmpty)
    }

    func testNewerDeletionRemovesItemButKeepsDeletionRecord() {
        let item = BuddyTodoItem(
            id: "todo-1",
            text: "삭제될 일",
            isDone: false,
            createdAt: 10,
            createdByDeviceId: "me",
            updatedAt: 20,
            updatedByDeviceId: "me"
        )
        let deletion = BuddyTodoDeletionRecord(
            id: "todo-1",
            deletedAt: 30,
            deletedByDeviceId: "buddy"
        )

        let merged = BuddyTodoSyncPolicy.merged(
            local: BuddyTodoSnapshot(items: [item], deletions: []),
            remote: BuddyTodoSnapshot(items: [], deletions: [deletion])
        )

        XCTAssertTrue(merged.items.isEmpty)
        XCTAssertEqual(merged.deletions, [deletion])
    }

    func testUpdateAfterDeletionRestoresItemAndDropsDeletionRecord() {
        let deletion = BuddyTodoDeletionRecord(
            id: "todo-1",
            deletedAt: 30,
            deletedByDeviceId: "me"
        )
        let restored = BuddyTodoItem(
            id: "todo-1",
            text: "다시 살릴 일",
            isDone: false,
            createdAt: 10,
            createdByDeviceId: "buddy",
            updatedAt: 40,
            updatedByDeviceId: "buddy"
        )

        let merged = BuddyTodoSyncPolicy.merged(
            local: BuddyTodoSnapshot(items: [], deletions: [deletion]),
            remote: BuddyTodoSnapshot(items: [restored], deletions: [])
        )

        XCTAssertEqual(merged.items, [restored])
        XCTAssertTrue(merged.deletions.isEmpty)
    }
}

import XCTest

final class BuildAppScriptSourceTests: XCTestCase {
    func testBuildScriptDoesNotCopyResourceBundleToAppRoot() throws {
        let source = try String(
            contentsOfFile: "scripts/build_app.sh",
            encoding: .utf8
        )

        XCTAssertFalse(
            source.contains("cp -R \"$ROOT_DIR/.build/release/MyBuddyNative_MyBuddyApp.bundle\" \"$APP_DIR/\""),
            "macOS app bundles should keep resources under Contents/Resources; root-level files make signing invalid."
        )
    }

    func testBuildScriptSignsAppBeforeCreatingDmg() throws {
        let source = try String(
            contentsOfFile: "scripts/build_app.sh",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("codesign --force --deep --sign"))
        XCTAssertLessThan(
            try XCTUnwrap(source.range(of: "codesign --force --deep --sign")?.lowerBound),
            try XCTUnwrap(source.range(of: "hdiutil create")?.lowerBound),
            "The app bundle should be signed before it is packaged into a DMG."
        )
    }

    func testBuildScriptUsesNativeIconPathOnly() throws {
        let source = try String(
            contentsOfFile: "scripts/build_app.sh",
            encoding: .utf8
        )

        XCTAssertFalse(
            source.contains("$ROOT_DIR/../"),
            "The native build should not depend on removed prototype files."
        )
        XCTAssertTrue(
            source.contains("$ROOT_DIR/Resources/icon.icns"),
            "The app icon should live under native/Resources so the native package is self-contained."
        )
    }
}

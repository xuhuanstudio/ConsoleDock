import ConsoleDockCore
import XCTest

final class ConsoleDockCoreTests: XCTestCase {
    override func tearDown() {
        CDKConsoleDock.stop()
        super.tearDown()
    }

    func testDefaultConfigurationValues() {
        let configuration = CDKConfiguration.default()

        XCTAssertEqual(configuration.maximumEntries, 2_000)
        XCTAssertTrue(configuration.captureStandardOutput)
        XCTAssertTrue(configuration.captureStandardError)
        XCTAssertTrue(configuration.showsFloatingButton)
        XCTAssertFalse(configuration.allowsReleaseBuilds)
    }

    func testStartStopLifecycle() {
        let result = CDKConsoleDock.start(with: .default())

        XCTAssertEqual(result, .started)
        XCTAssertTrue(CDKConsoleDock.isRunning())

        CDKConsoleDock.stop()

        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testRepeatedStartAndStopAreStable() {
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .started)
        XCTAssertEqual(CDKConsoleDock.start(with: .default()), .alreadyRunning)

        CDKConsoleDock.stop()
        CDKConsoleDock.stop()

        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testInvalidConfigurationFailsWithoutStarting() {
        let configuration = CDKConfiguration.default()
        configuration.maximumEntries = 0

        XCTAssertEqual(CDKConsoleDock.start(with: configuration), .failed)
        XCTAssertFalse(CDKConsoleDock.isRunning())
    }

    func testInvalidConfigurationPopulatesNSError() {
        let configuration = CDKConfiguration.default()
        configuration.maximumEntries = 0
        var error: NSError?

        let result = CDKConsoleDock.start(with: configuration, error: &error)

        XCTAssertEqual(result, .failed)
        XCTAssertEqual(error?.domain, "CDKConsoleDockErrorDomain")
        XCTAssertEqual(error?.code, 1)
        XCTAssertEqual(error?.localizedDescription, "maximumEntries must be greater than zero")
        XCTAssertFalse(CDKConsoleDock.isRunning())
    }
}

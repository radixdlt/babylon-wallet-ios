@_exported @testable import EngineToolkit
@_exported import Foundation
@_exported import XCTest

class TestCase: XCTestCase {
	var sut = EngineToolkit()
	var debugPrint = false

	override func setUp() {
		super.setUp()
		continueAfterFailure = false
		EngineToolkit._debugPrint = debugPrint
	}

	override func tearDown() {
		EngineToolkit._debugPrint = false
	}
}

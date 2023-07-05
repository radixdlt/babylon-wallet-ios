@testable import EngineToolkit
import TestingPrelude

class TestCase: TestingPrelude.TestCase {
	var sut = RadixEngine.instance
	var debugPrint = false

	override func setUp() {
		super.setUp()
		continueAfterFailure = false
		RadixEngine._debugPrint = debugPrint
	}

	override func tearDown() {
		RadixEngine._debugPrint = false
	}
}

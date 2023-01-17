import Prelude

public extension NSError {
	static func testValue(domain: String = "Test") -> NSError {
		NSError(domain: domain, code: 1)
	}
}

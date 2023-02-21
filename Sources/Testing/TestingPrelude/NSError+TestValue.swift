import Prelude

extension NSError {
	public static func testValue(domain: String = "Test") -> NSError {
		NSError(domain: domain, code: 1)
	}
}

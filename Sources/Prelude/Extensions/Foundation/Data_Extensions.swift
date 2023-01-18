import Foundation

#if DEBUG
// https://gist.github.com/cprovatas/5c9f51813bc784ef1d7fcbfb89de74fe
public extension Data {
	/// NSString gives us a nice sanitized debugDescription
	var prettyPrintedJSONString: NSString? {
		guard
			let object = try? JSONSerialization.jsonObject(with: self, options: []),
			let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
			let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
		else { return nil }

		return prettyPrintedString
	}
}
#endif // DEBUG

public extension Data {
	var bytes: [UInt8] {
		[UInt8](self)
	}
}

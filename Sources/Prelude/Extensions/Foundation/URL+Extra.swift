import Foundation

extension URL {
	public var httpsURL: Self? {
		var absoluteString = self.absoluteString
		if let separator = absoluteString.range(of: "://") {
			absoluteString.removeSubrange(absoluteString.startIndex ..< separator.upperBound)
		}
		let httpsString = "https://" + absoluteString
		return .init(string: httpsString)
	}
}

import UIKit

public extension PasteboardClient {
	static var live: Self {
		let pasteboard = UIPasteboard.general
		return Self(
			copyString: { aString in
				pasteboard.string = aString
			},
			getString: {
				pasteboard.string
			}
		)
	}
}

#if os(iOS)
import UIKit
let pasteboard = UIPasteboard.general
#elseif os(macOS)
import AppKit
let pasteboard = NSPasteboard.general
#endif

public extension PasteboardClient {
	static var live: Self {
		print("tralala")

		return Self(
			copyString: { aString in
				#if os(iOS)
				pasteboard.string = aString
				#elseif os(macOS)
				pasteboard.setString(aString, forType: .string)
				#endif
			},
			getString: {
				#if os(iOS)
				pasteboard.string
				#elseif os(macOS)
				pasteboard.string(forType: .string)
				#endif
			}
		)
	}
}

#if os(iOS)
import UIKit
public typealias Pasteboard = UIPasteboard
#elseif os(macOS)
import AppKit
public typealias Pasteboard = NSPasteboard
#endif

public extension PasteboardClient {
	static func live(pasteboard: Pasteboard = .general) -> Self {
		Self(
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

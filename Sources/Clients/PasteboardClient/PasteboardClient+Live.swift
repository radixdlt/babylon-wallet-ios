#if os(iOS)
import UIKit
public typealias Pasteboard = UIPasteboard
#elseif os(macOS)
import AppKit
public typealias Pasteboard = NSPasteboard
#endif
import Prelude

// MARK: - PasteboardClient + DependencyKey
extension PasteboardClient: DependencyKey {
	public typealias Value = PasteboardClient
	public static let liveValue = Self.live()

	static func live(pasteboard: Pasteboard = .general) -> Self {
		#if os(macOS)
		// https://stackoverflow.com/a/71927867
		pasteboard.declareTypes([.string], owner: nil)
		#endif
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

#if os(iOS)
import UIKit
public typealias Pasteboard = UIPasteboard
#elseif os(macOS)
import AppKit
public typealias Pasteboard = NSPasteboard
#endif
import Dependencies

// MARK: - PasteboardClient + DependencyKey
extension PasteboardClient: DependencyKey {
	public static let liveValue: Self = {
		let pasteboard = Pasteboard.general
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
	}()
}

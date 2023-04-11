import SwiftUI

#if os(iOS)
extension UIKeyboardType: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue == rhs.rawValue
	}
}
#endif

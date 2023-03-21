import SwiftUI

extension UIKeyboardType: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue == rhs.rawValue
	}
}

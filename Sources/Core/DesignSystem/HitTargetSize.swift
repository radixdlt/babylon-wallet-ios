import SwiftUI

// MARK: - HitTargetSize
public enum HitTargetSize: CGFloat {
	case small = 44

	public var frame: CGSize {
		switch self {
		case .small:
			return .init(width: rawValue, height: rawValue)
		}
	}
}

public extension View {
	@inlinable
	func frame(_ size: HitTargetSize) -> some View {
		frame(width: size.frame.width, height: size.frame.height)
	}
}

import SwiftUI

// MARK: - HitTargetSize
public enum HitTargetSize: CGFloat {
	/// 28
	case verySmall = 28

	/// 44
	case small = 44

	/// 64
	case medium = 64

	public var frame: CGSize {
		.init(width: rawValue, height: rawValue)
	}
}

public extension View {
	@inlinable
	func frame(_ size: HitTargetSize) -> some View {
		frame(width: size.frame.width, height: size.frame.height)
	}
}

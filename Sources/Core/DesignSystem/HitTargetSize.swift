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

extension View {
	@inlinable
	public func frame(_ size: HitTargetSize, alignment: Alignment = .center) -> some View {
		frame(width: size.frame.width, height: size.frame.height, alignment: alignment)
	}
}

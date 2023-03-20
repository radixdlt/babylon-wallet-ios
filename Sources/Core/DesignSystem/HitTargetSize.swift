import SwiftUI

// MARK: - HitTargetSize
public enum HitTargetSize: CGFloat {
	/// 24
	case smallest = 24

	/// 28
	case verySmall = 28

	/// 34
	case smaller = 34

	/// 44
	case small = 44

	/// 64
	case medium = 64

	/// 104
	case veryLarge = 104

	public var frame: CGSize {
		.init(width: rawValue, height: rawValue)
	}

	public var cornerRadius: CGFloat {
		switch self {
		case .smallest:
			return .small3
		case .verySmall:
			return .small3
		case .smaller:
			return .small3
		case .small:
			return .small2
		case .medium:
			return .small1
		case .veryLarge:
			return .medium3
		}
	}
}

extension View {
	@inlinable
	public func frame(_ size: HitTargetSize, alignment: Alignment = .center) -> some View {
		frame(width: size.frame.width, height: size.frame.height, alignment: alignment)
	}
}

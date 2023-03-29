import SwiftUI

// MARK: - HitTargetSize
public enum HitTargetSize: CGFloat {
	/// 28
	case verySmall = 28

	/// 44
	case small = 44

	/// 64
	case medium = 64

	/// 104
	case veryLarge = 104

	/// 200
	case huge = 200

	public var frame: CGSize {
		.init(width: rawValue, height: rawValue)
	}

	public var cornerRadius: CGFloat {
		switch self {
		case .verySmall:
			return .small3
		case .small:
			return .small2
		case .medium:
			return .small1
		case .veryLarge:
			return .medium3
		case .huge:
			return .huge
		}
	}
}

extension View {
	@inlinable
	public func frame(_ size: HitTargetSize, alignment: Alignment = .center) -> some View {
		frame(width: size.frame.width, height: size.frame.height, alignment: alignment)
	}
}

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

	public var frame: CGSize {
		.init(width: rawValue, height: rawValue)
	}

	// TODO: • figure out remaining corner radii
	public var cornerRadius: CGFloat {
		switch self {
		case .verySmall:
			fatalError()
		case .small:
			return .small2
		case .medium:
			fatalError()
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

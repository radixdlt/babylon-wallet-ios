import SwiftUI

// MARK: - HitTargetSize
public enum HitTargetSize: CGFloat {
	/// 16
	case tiny = 16

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

	/// 140
	case huge = 140

	/// 200
	case veryHuge = 200

	public var frame: CGSize {
		.init(width: rawValue, height: rawValue)
	}

	public var cornerRadius: CGFloat {
		switch self {
		case .tiny:
			return .small3
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
		case .huge:
			return .medium2
		case .veryHuge:
			return .medium1
		}
	}
}

extension View {
	@inlinable
	public func frame(_ size: HitTargetSize, alignment: Alignment = .center) -> some View {
		frame(width: size.frame.width, height: size.frame.height, alignment: alignment)
	}
}

// MARK: - Screen
@MainActor
public enum Screen {
	#if os(iOS)
	public static let pixelScale: CGFloat = {
		let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		guard let screen = scene?.windows.first?.screen else { return 2 }
		return screen.scale
	}()
	#else
	public static let pixelScale: CGFloat = 2
	#endif
}

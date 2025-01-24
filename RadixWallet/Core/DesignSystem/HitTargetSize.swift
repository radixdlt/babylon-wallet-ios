// MARK: - HitTargetSize
public enum HitTargetSize: CGFloat, Sendable {
	/// 18
	case icon = 18

	/// 24
	case smallest = 24

	/// 28
	case verySmall = 28

	/// 34
	case smaller = 34

	/// 40
	case slightlySmaller = 40

	/// 44
	case small = 44

	/// 50
	case smallish = 50

	/// 64
	case medium = 64

	/// 80
	case large = 80

	/// 104
	case veryLarge = 104

	/// 140
	case huge = 140

	/// 200
	case veryHuge = 200

	public var frame: CGSize {
		.init(width: rawValue, height: rawValue)
	}

	var cornerRadius: CGFloat {
		switch self {
		case .icon:
			.small3
		case .smallest:
			.small3
		case .verySmall:
			.small3
		case .smaller:
			.small3
		case .slightlySmaller:
			.small2
		case .small:
			.small2
		case .smallish:
			.small2
		case .medium:
			.small1
		case .large:
			.medium3
		case .veryLarge:
			.medium3
		case .huge:
			.medium2
		case .veryHuge:
			.medium1
		}
	}
}

extension View {
	@inlinable
	public func frame(_ size: HitTargetSize, alignment: Alignment = .center) -> some View {
		frame(width: size.frame.width, height: size.frame.height, alignment: alignment)
	}

	@inlinable
	public func frame(_ size: CGFloat, alignment: Alignment = .center) -> some View {
		frame(width: size, height: size, alignment: alignment)
	}
}

// MARK: - Screen
@MainActor
enum Screen {
	static let pixelScale: CGFloat = {
		let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		guard let screen = scene?.windows.first?.screen else { return 2 }
		return screen.scale
	}()
}

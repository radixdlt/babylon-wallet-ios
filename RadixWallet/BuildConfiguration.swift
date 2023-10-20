
public enum BuildConfiguration: Int, Sendable, Hashable, Comparable, CustomStringConvertible {
	case dev = 1
	case alpha = 2
	case preAlpha = 3
	case beta = 4
	case release = 5

	public static var current: Self? {
		#if BETA
		return .beta
		#elseif ALPHA
		return .alpha
		#elseif DEV
		return .dev
		#elseif PREALPHA
		return .preAlpha
		#elseif RELEASE
		return .release
		#else
		return nil
		#endif
	}

	public var description: String {
		switch self {
		case .dev: "DEV"
		case .alpha: "ALPHA"
		case .preAlpha: "PREALPHA"
		case .beta: "BETA"
		case .release: "RELEASE"
		}
	}

	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}

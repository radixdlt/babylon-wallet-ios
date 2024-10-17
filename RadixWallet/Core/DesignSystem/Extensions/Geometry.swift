
extension CGSize {
	static func + (lhs: Self, rhs: Self) -> Self {
		.init(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
	}

	static func - (lhs: Self, rhs: Self) -> Self {
		.init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
	}

	static func * (lhs: CGFloat, rhs: Self) -> Self {
		.init(width: lhs * rhs.width, height: lhs * rhs.height)
	}
}

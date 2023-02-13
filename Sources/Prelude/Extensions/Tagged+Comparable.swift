import Tagged

extension Tagged where RawValue: Comparable {
	public static func >= (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue >= rhs
	}

	public static func <= (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue <= rhs
	}

	public static func > (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue > rhs
	}

	public static func < (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue < rhs
	}

	public static func >= (lhs: RawValue, rhs: Self) -> Bool {
		lhs >= rhs.rawValue
	}

	public static func <= (lhs: RawValue, rhs: Self) -> Bool {
		lhs <= rhs.rawValue
	}

	public static func > (lhs: RawValue, rhs: Self) -> Bool {
		lhs > rhs.rawValue
	}

	public static func < (lhs: RawValue, rhs: Self) -> Bool {
		lhs < rhs.rawValue
	}
}

extension Tagged where RawValue: Equatable {
	public static func == (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue == rhs
	}

	public static func == (lhs: RawValue, rhs: Self) -> Bool {
		lhs == rhs.rawValue
	}
}

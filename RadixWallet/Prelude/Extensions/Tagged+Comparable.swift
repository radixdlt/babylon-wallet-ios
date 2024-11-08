
extension Tagged where RawValue: Comparable {
	static func >= (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue >= rhs
	}

	static func <= (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue <= rhs
	}

	static func > (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue > rhs
	}

	static func < (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue < rhs
	}

	static func >= (lhs: RawValue, rhs: Self) -> Bool {
		lhs >= rhs.rawValue
	}

	static func <= (lhs: RawValue, rhs: Self) -> Bool {
		lhs <= rhs.rawValue
	}

	static func > (lhs: RawValue, rhs: Self) -> Bool {
		lhs > rhs.rawValue
	}

	static func < (lhs: RawValue, rhs: Self) -> Bool {
		lhs < rhs.rawValue
	}
}

extension Tagged where RawValue: Equatable {
	static func == (lhs: Self, rhs: RawValue) -> Bool {
		lhs.rawValue == rhs
	}

	static func == (lhs: RawValue, rhs: Self) -> Bool {
		lhs == rhs.rawValue
	}
}

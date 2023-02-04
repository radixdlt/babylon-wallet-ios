import Prelude

public typealias Grid = CGFloat

private extension Grid {
	static let unit: Self = 4
}

public extension Grid {
	/// 40
	static let large1 = unit * 10

	/// 32
	static let large2 = unit * 8

	/// 28
	static let large3 = unit * 7

	/// 24
	static let medium1 = unit * 6

	/// 20
	static let medium2 = unit * 5

	/// 16
	static let medium3 = unit * 4

	/// 12
	static let small1 = unit * 3

	/// 8
	static let small2 = unit * 2

	/// 4
	static let small3 = unit * 1
}

public extension CGFloat {
	/// 50
	static let standardButtonHeight: Self = 50

	/// 75
	static let largeButtonHeight: Self = 75
	
	/// 60
	static let navBarHeight: Self = 66
}

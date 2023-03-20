import Prelude

public typealias Grid = CGFloat

extension Grid {
	fileprivate static let unit: Self = 4
}

extension Grid {
	/// 40
	public static let large1 = unit * 10

	/// 32
	public static let large2 = unit * 8

	/// 28
	public static let large3 = unit * 7

	/// 24
	public static let medium1 = unit * 6

	/// 20
	public static let medium2 = unit * 5

	/// 16
	public static let medium3 = unit * 4

	/// 12
	public static let small1 = unit * 3

	/// 8
	public static let small2 = unit * 2

	/// 4
	public static let small3 = unit * 1
}

extension CGFloat {
	/// 50
	public static let navigationBarHeight: Self = 50

	/// 50
	public static let standardButtonHeight: Self = 50

	/// 32
	public static let toolbatButtonHeight: Self = 32

	/// 250
	public static let standardButtonWidth: Self = 250

	/// 75
	public static let largeButtonHeight: Self = 75
}

extension CGSize {
	/// 38 x 4
	public static let sheetDragHandleSize: Self = .init(width: 38, height: 4)
}

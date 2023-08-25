import Prelude

public typealias Grid = CGFloat

extension Grid {
	fileprivate static let unit: Self = 4
}

extension Grid {
	/// 72
	public static let huge1 = unit * 18

	/// 60
	public static let huge2 = unit * 15

	/// 48
	public static let huge3 = unit * 12

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
	/// 40
	public static let guaranteeAccountLabelHeight: Self = 40

	/// 50
	public static let navigationBarHeight: Self = 50

	/// 50
	public static let approveSliderHeight: Self = 50

	/// 50
	public static let standardButtonHeight: Self = 50

	/// 32
	public static let toolbarButtonHeight: Self = 32

	/// 250
	public static let standardButtonWidth: Self = 250

	/// 72
	public static let settingsRowHeight: Self = 72

	/// 75
	public static let largeButtonHeight: Self = 75

	/// 275
	public static let smallDetent: Self = 275

	/// 150
	public static let imagePlaceholderHeight: Self = 150
}

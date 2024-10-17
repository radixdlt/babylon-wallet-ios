
typealias Grid = CGFloat

extension Grid {
	fileprivate static let unit: Self = 4
}

extension Grid {
	/// 72
	static let huge1 = unit * 18

	/// 60
	static let huge2 = unit * 15

	/// 48
	static let huge3 = unit * 12

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

extension CGFloat {
	/// 2
	static let assetDividerHeight: Self = 2

	/// 40
	static let guaranteeAccountLabelHeight: Self = 40

	/// 50
	static let navigationBarHeight: Self = 50

	/// 50
	static let approveSliderHeight: Self = 50

	/// 50
	static let standardButtonHeight: Self = 50

	/// 32
	static let toolbarButtonHeight: Self = 32

	/// 250
	static let standardButtonWidth: Self = 250

	/// 72
	static let plainListRowMinHeight: Self = 72

	/// 75
	static let largeButtonHeight: Self = 75

	/// 275
	static let smallDetent: Self = 275

	/// 150
	static let imagePlaceholderHeight: Self = 150
}

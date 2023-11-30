import Foundation

// MARK: - PickerStyleRadixSegmentedViewModifier
@MainActor
struct PickerStyleRadixSegmentedViewModifier: ViewModifier {
	init() {
		let blue = UIColor(Color.app.blue2)
		let white = UIColor(Color.app.white)
		let appearance = UISegmentedControl.appearance()
		appearance.selectedSegmentTintColor = blue

		// NORMAL
		appearance.setTitleTextAttributes([.font: FontConvertible.Font.app.segmentedControlNormal], for: .normal)
		appearance.setTitleTextAttributes([.foregroundColor: blue], for: .normal)

		// SELECTED
		appearance.setTitleTextAttributes([.font: FontConvertible.Font.app.segmentedControlSelected], for: .selected)
		appearance.setTitleTextAttributes([.foregroundColor: white], for: .selected)
	}

	func body(content: Content) -> some View {
		content
			.pickerStyle(.segmented)
	}
}

extension View {
	@MainActor
	public func pickerStyleRadixSegmented() -> some View {
		modifier(PickerStyleRadixSegmentedViewModifier())
	}
}

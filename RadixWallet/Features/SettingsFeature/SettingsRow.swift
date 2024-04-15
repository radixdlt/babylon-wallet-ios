import SwiftUI

// MARK: - SettingsRowModel
struct SettingsRowModel<Feature: FeatureReducer>: Identifiable {
	let id: String
	let rowViewState: PlainListRow<AssetIcon>.ViewState
	let action: Feature.ViewAction

	public init(
		title: String,
		subtitle: String? = nil,
		hint: Hint.ViewState? = nil,
		icon: AssetIcon.Content,
		action: Feature.ViewAction
	) {
		self.id = title
		self.rowViewState = .init(icon, rowCoreViewState: .init(kind: .settings, title: title, subtitle: subtitle, hint: hint))
		self.action = action
	}
}

// MARK: - SettingsRow
struct SettingsRow<Feature: FeatureReducer>: View {
	let row: SettingsRowModel<Feature>
	let action: () -> Void

	var body: some View {
		PlainListRow(viewState: row.rowViewState)
			.tappable(action)
			.withSeparator
	}
}

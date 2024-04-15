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

// MARK: - SettingsRowKind
enum SettingsRowKind<Feature: FeatureReducer>: Identifiable {
	case model(SettingsRowModel<Feature>)
	case separator(String)

	static var separator: Self {
		.separator(UUID().uuidString)
	}

	var id: String {
		switch self {
		case let .model(model):
			model.id
		case let .separator(id):
			id
		}
	}

	@ViewBuilder
	func build(viewStore: ViewStore<Feature.ViewState, Feature.ViewAction>) -> some View {
		switch self {
		case let .model(model):
			PlainListRow(viewState: model.rowViewState)
				.tappable {
					viewStore.send(model.action)
				}
				.withSeparator

		case .separator:
			Rectangle()
				.fill(Color.clear)
				.frame(maxWidth: .infinity)
				.frame(height: .large3)
		}
	}
}

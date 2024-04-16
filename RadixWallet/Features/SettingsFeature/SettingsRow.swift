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

// MARK: - AbstractSettingsRow
enum AbstractSettingsRow<Feature: FeatureReducer>: Identifiable {
	case model(SettingsRowModel<Feature>)
	case custom(AnyView, String)
	case separator(String)
	case header(title: String, id: String)

	static var separator: Self {
		.separator(UUID().uuidString)
	}

	static func header(_ title: String) -> Self {
		.header(title: title, id: UUID().uuidString)
	}

	static func custom(_ view: AnyView) -> Self {
		.custom(view, UUID().uuidString)
	}

	var id: String {
		switch self {
		case let .model(model):
			model.id
		case let .custom(_, id):
			id
		case let .separator(id):
			id
		case let .header(_, id):
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

		case let .custom(content, _):
			content

		case .separator:
			Rectangle()
				.fill(Color.clear)
				.frame(maxWidth: .infinity)
				.frame(height: .large3)

		case let .header(title, _):
			HStack(spacing: .zero) {
				Text(title)
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
				Spacer()
			}
			.padding(.medium3)
		}
	}
}

import SwiftUI

// MARK: - SettingsRowModel
struct SettingsRowModel<Feature: FeatureReducer>: Identifiable {
	let id: String
	let rowViewState: PlainListRow<AssetIcon>.ViewState
	let action: Feature.ViewAction

	public init(
		title: String,
		subtitle: String? = nil,
		detail: String? = nil,
		hints: [Hint.ViewState] = [],
		icon: AssetIcon.Content,
		accessory: ImageAsset? = AssetResource.chevronRight,
		action: Feature.ViewAction
	) {
		self.id = title
		self.rowViewState = .init(icon, rowCoreViewState: .init(kind: .settings, title: title, subtitle: subtitle, detail: detail, hints: hints), accessory: accessory)
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
	case custom(AnyView)
	case separator
	case header(String)

	var id: String {
		switch self {
		case let .model(model):
			model.id
		case .custom:
			"custom"
		case .separator:
			"separator"
		case let .header(value):
			value
		}
	}

	@ViewBuilder
	func build(viewStore: ViewStoreOf<Feature>) -> some View {
		switch self {
		case let .model(model):
			PlainListRow(viewState: model.rowViewState)
				.tappable {
					viewStore.send(model.action)
				}
				.withSeparator

		case let .custom(content):
			content

		case .separator:
			Rectangle()
				.fill(Color.clear)
				.frame(maxWidth: .infinity)
				.frame(height: .large3)

		case let .header(title):
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

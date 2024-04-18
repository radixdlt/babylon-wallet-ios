import SwiftUI

// MARK: - SettingsRow
enum SettingsRow<Feature: FeatureReducer> {
	/// A standard tappable row with the details specified on the `Model`
	case model(Model)

	/// A custom row with its own UI. Useful, for example, when we want a `ToggleView` between other rows.
	case custom(AnyView, id: String)

	/// A small row acting as a section header with the provided title.
	case header(String)

	/// Similar to the `.header`, but with no title/
	case separator

	@ViewBuilder
	func build(viewStore: ViewStoreOf<Feature>) -> some View {
		switch self {
		case let .model(model):
			PlainListRow(viewState: model.rowViewState)
				.tappable {
					viewStore.send(model.action)
				}
				.withSeparator

		case let .custom(content, _):
			content

		case let .header(title):
			HStack(spacing: .zero) {
				Text(title)
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
				Spacer()
			}
			.padding(.medium3)

		case .separator:
			Rectangle()
				.fill(Color.clear)
				.frame(maxWidth: .infinity)
				.frame(height: .large3)
		}
	}
}

// MARK: SettingsRow.Model
extension SettingsRow {
	struct Model: Identifiable {
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
}

// MARK: Identifiable
extension SettingsRow: Identifiable {
	var id: String {
		switch self {
		case let .model(model):
			model.id
		case let .custom(_, id):
			id
		case .separator:
			"separator"
		case let .header(value):
			value
		}
	}
}

// MARK: - Helper
extension SettingsRow {
	static func model(
		title: String,
		subtitle: String? = nil,
		detail: String? = nil,
		hints: [Hint.ViewState] = [],
		icon: AssetIcon.Content,
		accessory: ImageAsset? = AssetResource.chevronRight,
		action: Feature.ViewAction
	) -> Self {
		.model(
			.init(
				title: title,
				subtitle: subtitle,
				detail: detail,
				hints: hints,
				icon: icon,
				accessory: accessory,
				action: action
			)
		)
	}
}

import SwiftUI

// MARK: - SettingsRow
struct SettingsRow<Feature: FeatureReducer>: View {
	let kind: Kind
	let store: StoreOf<Feature>

	var body: some View {
		switch kind {
		case let .model(model):
			PlainListRow(viewState: model.rowViewState)
				.tappable {
					store.send(.view(model.action))
				}
				.withSeparator

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

// MARK: SettingsRow.Kind
extension SettingsRow {
	enum Kind: Identifiable {
		/// A standard tappable row with the details specified on the `Model`
		case model(Model)

		/// A small row acting as a section header with the provided title.
		case header(String)

		/// Similar to the `.header`, but with no title.
		case separator

		var id: String {
			switch self {
			case let .model(model):
				model.id
			case .separator:
				"separator"
			case let .header(value):
				value
			}
		}
	}
}

// MARK: - SettingsRow.Kind.Model
extension SettingsRow.Kind {
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
			self.rowViewState = .init(
				icon,
				rowCoreViewState: .init(context: .settings, title: title, subtitle: subtitle, detail: detail),
				accessory: accessory,
				hints: hints
			)
			self.action = action
		}
	}
}

// MARK: - Helper
extension SettingsRow.Kind {
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

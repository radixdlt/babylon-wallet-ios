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

		case let .toggle(model):
			ToggleView(
				icon: model.icon,
				title: model.title,
				subtitle: model.subtitle,
				minHeight: model.minHeight,
				isOn: model.isOn
			)
			.padding(.horizontal, .medium3)
			.padding(.vertical, .medium1)
			.background(Color.app.white)
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
	enum Kind {
		/// A standard tappable row with the details specified on the `Model`
		case model(Model)

		/// A non-tappable row with a toggle, with details specified in the `ToggleModel`
		case toggle(ToggleModel)

		/// A small row acting as a section header with the provided title.
		case header(String)

		/// Similar to the `.header`, but with no title.
		case separator
	}
}

// MARK: - SettingsRow.Kind.Model
extension SettingsRow.Kind {
	struct Model: Identifiable {
		let id: String
		let rowViewState: PlainListRow<AssetIcon, Image>.ViewState
		let action: Feature.ViewAction

		public init(
			title: String,
			subtitle: String? = nil,
			detail: String? = nil,
			hints: [Hint.ViewState] = [],
			icon: AssetIcon.Content,
			accessory: ImageResource? = .chevronRight,
			action: Feature.ViewAction
		) {
			self.id = title
			self.rowViewState = .init(
				icon,
				rowCoreViewState: .init(title: title, subtitle: subtitle, detail: detail),
				accessory: accessory,
				hints: hints
			)
			self.action = action
		}
	}

	struct ToggleModel: Identifiable {
		let id: String
		let icon: ImageAsset?
		let title: String
		let subtitle: String
		let minHeight: CGFloat
		let isOn: Binding<Bool>

		init(
			icon: ImageAsset? = nil,
			title: String,
			subtitle: String,
			minHeight: CGFloat = .largeButtonHeight,
			isOn: Binding<Bool>
		) {
			self.id = title
			self.icon = icon
			self.title = title
			self.subtitle = subtitle
			self.minHeight = minHeight
			self.isOn = isOn
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
		accessory: ImageResource? = .chevronRight,
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

	static func toggleModel(
		icon: ImageAsset?,
		title: String,
		subtitle: String,
		minHeight: CGFloat,
		isOn: Binding<Bool>
	) -> Self {
		.toggle(
			.init(
				icon: icon,
				title: title,
				subtitle: subtitle,
				minHeight: minHeight,
				isOn: isOn
			)
		)
	}
}

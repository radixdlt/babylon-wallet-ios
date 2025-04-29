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
				.background(Color.primaryBackground)

		case let .disabled(model):
			PlainListRow(viewState: model.rowViewState)
				.withSeparator
				.background(Color.primaryBackground)

		case let .toggle(model):
			ToggleView(
				context: .settings,
				icon: model.icon,
				title: model.title,
				subtitle: model.subtitle,
				minHeight: model.minHeight,
				isOn: model.isOn
			)
			.padding(.horizontal, .medium3)
			.padding(.vertical, .medium1)
			.background(Color.primaryBackground)
			.foregroundStyle(Color.primaryText)
			.withSeparator

		case let .header(title):
			HStack(spacing: .zero) {
				Text(title)
					.textStyle(.body1Link)
					.foregroundColor(Color.secondaryText)
				Spacer()
			}
			.padding(.medium3)
			.background(Color.secondaryBackground)

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

		/// A disabled row with the details specified on the `DisabledModel`
		case disabled(DisabledModel)

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
		let rowViewState: PlainListRow<AssetIcon, Image, StackedHints>.ViewState
		let action: Feature.ViewAction

		init(
			isError: Bool = false,
			title: String,
			subtitle: String? = nil,
			detail: String? = nil,
			markdown: String? = nil,
			hints: [Hint.ViewState] = [],
			icon: AssetIcon.Content,
			accessory: ImageResource? = .chevronRight,
			action: Feature.ViewAction
		) {
			self.id = title
			self.rowViewState = .init(
				icon,
				rowCoreViewState: .init(context: .settings(isError: isError), title: title, subtitle: subtitle, detail: detail, markdown: markdown),
				accessory: accessory,
				hints: hints
			)
			self.action = action
		}
	}

	struct DisabledModel: Identifiable {
		let id: String
		let rowViewState: PlainListRow<AssetIcon, Image, AnyView>.ViewState

		init(
			title: String,
			subtitle: String? = nil,
			icon: AssetIcon.Content,
			@ViewBuilder bottom: () -> AnyView
		) {
			self.id = title
			self.rowViewState = .init(
				icon,
				rowCoreViewState: .init(context: .settings, title: title, subtitle: subtitle),
				isDisabled: true,
				bottom: bottom
			)
		}
	}

	struct ToggleModel: Identifiable {
		let id: String
		let icon: ImageResource?
		let title: String
		let subtitle: String?
		let minHeight: CGFloat
		let isOn: Binding<Bool>

		init(
			icon: ImageResource? = nil,
			title: String,
			subtitle: String?,
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
		isError: Bool = false,
		title: String,
		subtitle: String? = nil,
		detail: String? = nil,
		markdown: String? = nil,
		hints: [Hint.ViewState] = [],
		icon: AssetIcon.Content,
		accessory: ImageResource? = .chevronRight,
		action: Feature.ViewAction
	) -> Self {
		.model(
			.init(
				isError: isError,
				title: title,
				subtitle: subtitle,
				detail: detail,
				markdown: markdown,
				hints: hints,
				icon: icon,
				accessory: accessory,
				action: action
			)
		)
	}

	static func disabled(
		title: String,
		subtitle: String? = nil,
		icon: AssetIcon.Content,
		@ViewBuilder bottom: () -> AnyView
	) -> Self {
		.disabled(
			.init(
				title: title,
				subtitle: subtitle,
				icon: icon,
				bottom: bottom
			)
		)
	}

	static func toggleModel(
		icon: ImageResource?,
		title: String,
		subtitle: String? = nil,
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

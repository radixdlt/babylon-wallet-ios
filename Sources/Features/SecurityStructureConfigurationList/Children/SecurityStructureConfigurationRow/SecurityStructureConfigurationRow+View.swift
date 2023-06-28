import FeaturePrelude

extension SecurityStructureConfigurationRow.State {
	var viewState: SecurityStructureConfigurationRow.ViewState {
		.init(
			label: configReference.metadata.label,
			createdOn: configReference.metadata.createdOn,
			lastUpdatedOn: configReference.metadata.lastUpdatedOn
		)
	}
}

// MARK: - SecurityStructureConfigurationRow.View
extension SecurityStructureConfigurationRow {
	public struct ViewState: Equatable {
		let label: String
		let createdOn: Date
		let lastUpdatedOn: Date
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigurationRow>

		public init(store: StoreOf<SecurityStructureConfigurationRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				SecurityStructureConfigurationRowView(
					isSelected: nil, // not select**able**
					label: viewStore.label,
					createdOn: viewStore.createdOn,
					lastUpdatedOn: viewStore.lastUpdatedOn,
					action: { viewStore.send(.displayDetails) }
				)
			}
		}
	}
}

// MARK: - SecurityStructureConfigurationRowView
public struct SecurityStructureConfigurationRowView: SwiftUI.View {
	let isSelected: Bool?
	let label: String
	let createdOn: Date
	let lastUpdatedOn: Date
	let action: () -> Void
	public var body: some SwiftUI.View {
		Card(.app.gray5, action: action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(label)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
						.padding(.bottom, .small1)

					// FIXME: Strings
					LabelledDate(label: "Created", date: createdOn)
						.padding(.bottom, .small3)

					LabelledDate(label: "Updated", date: lastUpdatedOn)
						.padding(.bottom, .small3)
				}

				if let isSelected {
					RadioButton(
						appearance: .light,
						state: isSelected ? .selected : .unselected
					)
				} else {
					Image(asset: AssetResource.chevronRight)
				}
			}
			.foregroundColor(.app.gray1)
			.padding(.horizontal, .large3)
			.padding(.vertical, .medium1)
		}
	}
}

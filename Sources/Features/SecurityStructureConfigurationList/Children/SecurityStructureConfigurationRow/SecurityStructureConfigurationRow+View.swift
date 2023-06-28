import FeaturePrelude

extension SecurityStructureConfigurationRow.State {
	var viewState: SecurityStructureConfigurationRow.ViewState {
		.init(
			metadata: configReference.metadata
		)
	}
}

// MARK: - SecurityStructureConfigurationRow.View
extension SecurityStructureConfigurationRow {
	public struct ViewState: Equatable {
		let metadata: SecurityStructureMetadata
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
					metadata: viewStore.metadata,
					action: { viewStore.send(.displayDetails) }
				)
			}
		}
	}
}

// MARK: - SecurityStructureConfigurationRowView
public struct SecurityStructureConfigurationRowView: SwiftUI.View {
	let isSelected: Bool?
	let metadata: SecurityStructureMetadata
	let action: () -> Void
	public var body: some SwiftUI.View {
		Card(.app.gray5, action: action) {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(metadata.label)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
						.padding(.bottom, .small1)

					// FIXME: Strings
					LabelledDate(label: "Created", date: metadata.createdOn)
						.padding(.bottom, .small3)

					LabelledDate(label: "Updated", date: metadata.lastUpdatedOn)
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

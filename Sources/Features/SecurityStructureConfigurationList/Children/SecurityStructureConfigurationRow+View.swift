import FeaturePrelude

extension SecurityStructureConfigurationRow.State {
	var viewStore: SecurityStructureConfigurationRow.viewStore {
		.init(label: config.label.rawValue, createdOn: config.created)
	}
}

// MARK: - SecurityStructureConfigurationRow.View
extension SecurityStructureConfigurationRow {
	public struct viewStore: Equatable {
		let label: String
		let createdOn: Date
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigurationRow>

		public init(store: StoreOf<SecurityStructureConfigurationRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewStore, send: { .view($0) }) { viewStore in
				Card(.app.gray5, action: { viewStore.send(.displayDetails) }) {
					HStack {
						VStack(alignment: .leading, spacing: 0) {
							Text(viewStore.label)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)
								.padding(.bottom, .small1)

							LabelledDate(label: "Created", date: viewStore.createdOn)
								.padding(.bottom, .small3)
						}

						Image(asset: AssetResource.chevronRight)
					}
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .large3)
					.padding(.vertical, .medium1)
				}
			}
		}
	}
}

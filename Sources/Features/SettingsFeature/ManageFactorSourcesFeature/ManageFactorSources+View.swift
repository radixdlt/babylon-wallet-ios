import FeaturePrelude

extension ManageFactorSources.State {
	var viewState: ManageFactorSources.ViewState {
		.init(factorSources: self.factorSources)
	}
}

// MARK: - ManageFactorSources.View
extension ManageFactorSources {
	public struct ViewState: Equatable {
		public let factorSources: FactorSources?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageFactorSources>

		public init(store: StoreOf<ManageFactorSources>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in

				VStack(alignment: .leading) {
					if let factorSources = viewStore.factorSources {
						ForEach(factorSources) {
							FactorSourceView(factorSource: $0)
						}
					}
					Button("Import Olympia factor source") {
						viewStore.send(.importOlympiaFactorSourceButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding([.horizontal, .bottom], .medium1)
				.onAppear { viewStore.send(.appeared) }
				.navigationTitle("Factor Sources")
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ManageFactorSources.Destinations.State.importOlympiaFactorSource,
					action: ManageFactorSources.Destinations.Action.importOlympiaFactorSource,
					content: { ImportOlympiaFactorSource.View(store: $0) }
				)
			}
		}
	}
}

// MARK: - FactorSourceView
public struct FactorSourceView: SwiftUI.View {
	public let factorSource: FactorSource
}

extension FactorSourceView {
	public var body: some View {
		VStack(alignment: .leading) {
			Text("Factor Source")
				.fontWeight(.heavy)
			#if os(macOS)
				.font(.title)
			#endif // os(macOS)

			InfoPair(heading: "Kind", item: factorSource.kind.rawValue)
			InfoPair(heading: "Hint", item: factorSource.hint.rawValue)
			InfoPair(heading: "Added on", item: factorSource.addedOn.ISO8601Format())
			InfoPair(heading: "ID", item: String(factorSource.id.hexCodable.hex().mask(showLast: 6)))

			if let deviceStore = factorSource.storage?.forDevice {
				ForEach(deviceStore.nextDerivationIndicesPerNetwork.perNetwork) { nextIndices in
					InfoPair(heading: "NetworkID", item: nextIndices.networkID)
					InfoPair(heading: "Next index for account", item: nextIndices.nextForEntity(kind: .account))
					InfoPair(heading: "Next index for persona", item: nextIndices.nextForEntity(kind: .identity))
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ManageFactorSources_Preview
struct ManageFactorSources_Preview: PreviewProvider {
	static var previews: some View {
		ManageFactorSources.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageFactorSources()
			)
		)
	}
}

extension ManageFactorSources.State {
	public static let previewValue = Self()
}
#endif

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
						ScrollView(showsIndicators: false) {
							VStack(alignment: .leading, spacing: .medium2) {
								ForEach(factorSources) {
									FactorSourceView(factorSource: $0)
								}
							}
						}
					}
					Button("Import Olympia factor source") {
						viewStore.send(.importOlympiaFactorSourceButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding([.horizontal, .bottom], .medium1)
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
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
struct FactorSourceView: SwiftUI.View {
	let factorSource: FactorSource
}

extension FactorSourceView {
	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			VPair(heading: "Kind", item: factorSource.kind)
			VPair(heading: "Hint", item: factorSource.hint)
			VPair(heading: "Added on", item: factorSource.addedOn.ISO8601Format())
			VPair(heading: "ID", item: String(factorSource.id.hexCodable.hex().mask(showLast: 6)))
		}
		.border(Color.app.gray1, width: 2)
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

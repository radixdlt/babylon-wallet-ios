import AddLedgerFactorSourceFeature
import FeaturePrelude
import ImportMnemonicFeature

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
					Button("Import Olympia mnemonic") {
						viewStore.send(.importOlympiaMnemonicButtonTapped)
					}
					.buttonStyle(.primaryRectangular)

					Button("Add Ledger hardware wallet") {
						viewStore.send(.addLedgerButtonTapped)
					}
					.buttonStyle(.primaryRectangular)

					Button("Add `.offDevice` mnemonic") {
						viewStore.send(.addOffDeviceMnemonicButtonTapped)
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
					state: /ManageFactorSources.Destinations.State.importMnemonic,
					action: ManageFactorSources.Destinations.Action.importMnemonic,
					content: { importMnemonicStore in
						NavigationView {
							// We depend on `.toolbar` to display buttons on top of
							// keyboard. And they are not displayed if we are not
							// inside a NavigationView
							ImportMnemonic.View(store: importMnemonicStore)
						}
					}
				)
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ManageFactorSources.Destinations.State.addLedger,
					action: ManageFactorSources.Destinations.Action.addLedger,
					content: { AddLedgerFactorSource.View(store: $0) }
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
			VPair(heading: "Added on", item: factorSource.addedOn.ISO8601Format())
			VPair(heading: "ID", item: String(factorSource.id.description.mask(showLast: 6)))
			if factorSource.isFlaggedForDeletion {
				Text("🚩🗑️ flagged as deleted")
			}
		}
		.padding()
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

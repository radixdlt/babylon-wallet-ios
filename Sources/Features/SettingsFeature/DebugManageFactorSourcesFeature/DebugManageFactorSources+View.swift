import AddLedgerFactorSourceFeature
import FeaturePrelude
import ImportMnemonicFeature

extension DebugManageFactorSources.State {
	var viewState: DebugManageFactorSources.ViewState {
		.init(factorSources: self.factorSources)
	}
}

// MARK: - DebugManageFactorSources.View
extension DebugManageFactorSources {
	public struct ViewState: Equatable {
		public let factorSources: FactorSources?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugManageFactorSources>

		public init(store: StoreOf<DebugManageFactorSources>) {
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
					state: /DebugManageFactorSources.Destinations.State.importMnemonic,
					action: DebugManageFactorSources.Destinations.Action.importMnemonic,
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
					state: /DebugManageFactorSources.Destinations.State.addLedger,
					action: DebugManageFactorSources.Destinations.Action.addLedger,
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

struct DebugManageFactorSources_Preview: PreviewProvider {
	static var previews: some View {
		DebugManageFactorSources.View(
			store: .init(
				initialState: .previewValue,
				reducer: DebugManageFactorSources()
			)
		)
	}
}

extension DebugManageFactorSources.State {
	public static let previewValue = Self()
}
#endif

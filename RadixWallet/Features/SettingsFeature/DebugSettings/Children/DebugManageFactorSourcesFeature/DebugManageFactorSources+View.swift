import ComposableArchitecture
import Sargon
import SwiftUI

extension DebugManageFactorSources.State {
	var viewState: DebugManageFactorSources.ViewState {
		.init(factorSources: self.factorSources)
	}
}

// MARK: - DebugManageFactorSources.View
extension DebugManageFactorSources {
	struct ViewState: Equatable {
		let factorSources: FactorSources?
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DebugManageFactorSources>

		init(store: StoreOf<DebugManageFactorSources>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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
				}
				.padding([.horizontal, .bottom], .medium1)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
				.radixToolbar(title: "Factor Sources")
			}
			.destinations(with: store)
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
			VPair(heading: "Kind", item: factorSource.factorSourceKind)
			VPair(heading: "Added on", item: factorSource.addedOn.ISO8601Format())
			VPair(heading: "ID", item: String(factorSource.id.description.mask(showLast: 6)))
			if factorSource.isFlaggedForDeletion {
				Text("🚩🗑️ flagged as deleted")
			}
		}
		.padding()
		.border(Color.primaryText, width: 2)
	}
}

private extension StoreOf<DebugManageFactorSources> {
	var destination: PresentationStoreOf<DebugManageFactorSources.Destination> {
		func scopeState(state: State) -> PresentationState<DebugManageFactorSources.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DebugManageFactorSources>) -> some View {
		let destinationStore = store.destination
		return importMnemonic(with: destinationStore)
			.addLedger(with: destinationStore)
	}

	private func importMnemonic(with destinationStore: PresentationStoreOf<DebugManageFactorSources.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /DebugManageFactorSources.Destination.State.importMnemonic,
			action: DebugManageFactorSources.Destination.Action.importMnemonic,
			content: {
				// We depend on `.toolbar` to display buttons on top of
				// keyboard. And they are not displayed if we are not
				// inside a NavigationView
				ImportMnemonic.View(store: $0)
					.inNavigationView
			}
		)
	}

	private func addLedger(with destinationStore: PresentationStoreOf<DebugManageFactorSources.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /DebugManageFactorSources.Destination.State.addLedger,
			action: DebugManageFactorSources.Destination.Action.addLedger,
			content: { AddLedgerFactorSource.View(store: $0) }
		)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct DebugManageFactorSources_Preview: PreviewProvider {
	static var previews: some View {
		DebugManageFactorSources.View(
			store: .init(
				initialState: .previewValue,
				reducer: DebugManageFactorSources.init
			)
		)
	}
}

extension DebugManageFactorSources.State {
	static let previewValue = Self()
}
#endif

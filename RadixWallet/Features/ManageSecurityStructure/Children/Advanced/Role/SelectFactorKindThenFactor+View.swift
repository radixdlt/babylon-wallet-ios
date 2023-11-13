import ComposableArchitecture
import SwiftUI
extension SelectFactorKindThenFactor.State {
	var viewState: SelectFactorKindThenFactor.ViewState {
		.init(role: role)
	}
}

// MARK: - SelectFactorKindThenFactor.View
extension SelectFactorKindThenFactor {
	public struct ViewState: Equatable {
		let role: SecurityStructureRole
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectFactorKindThenFactor>

		public init(store: StoreOf<SelectFactorKindThenFactor>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .small3) {
						ForEach(FactorSourceKind.allCases) { kind in
							VStack(spacing: 0) {
								let isEnabled = kind.supports(role: viewStore.role)
								Button(kind.display) {
									viewStore.send(.selected(kind))
								}
								.controlState(isEnabled ? .enabled : .disabled)
								.buttonStyle(.primaryRectangular)
								if !isEnabled {
									Text("Not supported")
								}
							}
							.padding()
						}
					}
				}
				.navigationTitle("Select Factor kind")
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<SelectFactorKindThenFactor> {
	var destination: PresentationStoreOf<SelectFactorKindThenFactor.Destination> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SelectFactorKindThenFactor>) -> some View {
		let destinationStore = store.destination
		return factorSourceOfKind(with: destinationStore)
			.selectLedger(with: destinationStore)
	}

	private func factorSourceOfKind(with destinationStore: PresentationStoreOf<SelectFactorKindThenFactor.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /SelectFactorKindThenFactor.Destination.State.factorSourceOfKind,
			action: SelectFactorKindThenFactor.Destination.Action.factorSourceOfKind,
			content: { FactorSourcesOfKindList<FactorSource>.View(store: $0) }
		)
	}

	private func selectLedger(with destinationStore: PresentationStoreOf<SelectFactorKindThenFactor.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /SelectFactorKindThenFactor.Destination.State.selectLedger,
			action: SelectFactorKindThenFactor.Destination.Action.selectLedger,
			content: { LedgerHardwareDevices.View(store: $0) }
		)
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
//// MARK: - SelectFactorKindThenFactor_Preview
// struct SelectFactorKindThenFactor_Preview: PreviewProvider {
//	static var previews: some View {
//		SelectFactorKindThenFactor.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SelectFactorKindThenFactor.init
//			)
//		)
//	}
// }
//
// extension SelectFactorKindThenFactor.State {
//	public static let previewValue = Self()
// }
// #endif

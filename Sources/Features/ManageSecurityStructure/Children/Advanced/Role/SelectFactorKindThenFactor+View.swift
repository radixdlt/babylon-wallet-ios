import FeaturePrelude
import LedgerHardwareDevicesFeature

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
					VStack(spacing: .large3) {
						ForEach(FactorSourceKind.allCases) { kind in
							VStack(spacing: 0) {
								let isEnabled = kind.supports(role: viewStore.role)
								Button(kind.selectedFactorDisplay) {
									viewStore.send(.selected(kind))
								}
								.disabled(!isEnabled)
								.buttonStyle(.borderedProminent)
								if !isEnabled {
									Text("Not supported")
								}
							}
						}
					}
				}
				.navigationTitle("Select Factor kind")
				.sheet(
					store: store.scope(
						state: \.$factorSourceOfKind,
						action: { .child(.factorSourceOfKind($0)) }
					),
					content: { FactorSourcesOfKindList<FactorSource>.View(store: $0) }
				)
				.sheet(
					store: store.scope(
						state: \.$selectLedger,
						action: { .child(.selectLedger($0)) }
					),
					content: { LedgerHardwareDevices.View(store: $0) }
				)
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SelectFactorKindThenFactor_Preview
// struct SelectFactorKindThenFactor_Preview: PreviewProvider {
//	static var previews: some View {
//		SelectFactorKindThenFactor.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SelectFactorKindThenFactor()
//			)
//		)
//	}
// }
//
// extension SelectFactorKindThenFactor.State {
//	public static let previewValue = Self()
// }
// #endif

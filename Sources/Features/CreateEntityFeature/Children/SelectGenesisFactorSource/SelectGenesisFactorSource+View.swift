import Cryptography
import FeaturePrelude

// MARK: - SelectGenesisFactorSource.View
extension SelectGenesisFactorSource {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectGenesisFactorSource>

		public init(store: StoreOf<SelectGenesisFactorSource>) {
			self.store = store
		}
	}
}

extension SelectGenesisFactorSource.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				// FIXME: appStore submission: implement this screen with a picker
				VStack {
					Picker(
						"Curve",
						selection: viewStore.binding(
							get: \.selectedCurve,
							send: { .selectedCurve($0) }
						)
					) {
						Text("Heh")
					}

					Spacer()
					Button("Confirm OnDevice factor source") {
						viewStore.send(.confirmOnDeviceFactorSource)
					}
					Spacer()
				}
			}
		}
	}
}

// MARK: - SelectGenesisFactorSource.View.ViewState
extension SelectGenesisFactorSource.View {
	struct ViewState: Equatable {
		let curves: [Slip10Curve]
		let selectedCurve: Slip10Curve
		init(state: SelectGenesisFactorSource.State) {
			// TODO: implement
			selectedCurve = state.curve
			curves = Array(Set(state.factorSources.flatMap(\.parameters.supportedCurves.elements)))
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SelectGenesisFactorSource_Preview
struct SelectGenesisFactorSource_Preview: PreviewProvider {
	static var previews: some View {
		SelectGenesisFactorSource.View(
			store: .init(
				initialState: .previewValue,
				reducer: SelectGenesisFactorSource()
			)
		)
	}
}
#endif

import Cryptography
import FeaturePrelude

extension SelectGenesisFactorSource.State {
	var viewState: SelectGenesisFactorSource.ViewState {
		.init(
			// TODO: implement
			curves: Array(Set(factorSources.flatMap(\.parameters.supportedCurves.elements))),
			selectedCurve: curve
		)
	}
}

// MARK: - SelectGenesisFactorSource.View
extension SelectGenesisFactorSource {
	public struct ViewState: Equatable {
		let curves: [Slip10Curve]
		let selectedCurve: Slip10Curve
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectGenesisFactorSource>

		public init(store: StoreOf<SelectGenesisFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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

import Cryptography
import FeaturePrelude

extension SelectGenesisFactorSource.State {
	var viewState: SelectGenesisFactorSource.ViewState {
//		.init(
//			// TODO: implement
//			curves: Array(Set(factorSources.flatMap(\.parameters.supportedCurves.elements))),
//			selectedCurve: curve
//		)
		.init(factorSources: factorSources, selectedFactorSource: selectedFactorSource, selectedCurve: self.selectedCurve)
	}
}

// MARK: - SelectGenesisFactorSource.View
extension SelectGenesisFactorSource {
	public struct ViewState: Equatable {
		let factorSources: FactorSources
		let selectedFactorSource: FactorSource
		let selectedCurve: Slip10Curve
		var supportedCurves: [Slip10Curve] { selectedFactorSource.parameters.supportedCurves.rawValue.elements }
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
					VStack {
						Picker(
							"Factor Source",
							selection: viewStore.binding(
								get: \.selectedFactorSource,
								send: { .selectedFactorSource($0) }
							)
						) {
							ForEach(viewStore.factorSources, id: \.self) { factorSource in
								Text("\(factorSource.hint.rawValue) \(factorSource.supportsOlympia ? "(Olympia)" : "")").tag(factorSource)
							}
						}

						if viewStore.supportedCurves.count > 1 {
							Picker(
								"Curve",
								selection: viewStore.binding(
									get: \.selectedCurve,
									send: { .selectedCurve($0) }
								)
							) {
								ForEach(viewStore.supportedCurves, id: \.self) { curve in
									Text("\(String(describing: curve))").tag(curve.rawValue)
								}
							}
						}

						Spacer()
						Button("Confirm OnDevice factor source") {
							viewStore.send(.confirmOnDeviceFactorSource)
						}
						.buttonStyle(.primaryRectangular)
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

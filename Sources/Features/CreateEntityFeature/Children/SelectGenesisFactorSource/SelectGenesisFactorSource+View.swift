import Cryptography
import FeaturePrelude

extension SelectGenesisFactorSource.State {
	var viewState: SelectGenesisFactorSource.ViewState {
//		.init(
//			// TODO: implement
//			curves: Array(Set(factorSources.flatMap(\.parameters.supportedCurves.elements))),
//			selectedCurve: curve
//		)
		.init(factorSources: factorSources, selectedFactorSource: selectedFactorSource)
	}
}

// MARK: - SelectGenesisFactorSource.View
extension SelectGenesisFactorSource {
	public struct ViewState: Equatable {
//		let curves: [Slip10Curve]
//		let selectedCurve: Slip10Curve
		let factorSources: FactorSources
		let selectedFactorSource: FactorSource
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
						Text("Derive accounts using...")
						Picker(
							"Factor Source",
							selection: viewStore.binding(
								get: \.selectedFactorSource,
								send: { .selectedFactorSource($0) }
							)
						) {
							ForEach(viewStore.factorSources, id: \.id) { factorSource in
								//                                FactorSourceView(factorSource: factorSource)
								Text("\(factorSource.hint.rawValue) \(factorSource.supportsOlympia ? "(Olympia)" : "")")
							}
						}

//						Picker(
//							"Curve",
//							selection: viewStore.binding(
//								get: \.selectedCurve,
//								send: { .selectedCurve($0) }
//							)
//						) {
//							Text("Heh")
//						}

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

// MARK: - FactorSourceView
struct FactorSourceView: SwiftUI.View {
	let factorSource: FactorSource
}

extension FactorSourceView {
	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			InfoPair(heading: "Kind", item: factorSource.kind)
			InfoPair(heading: "Hint", item: factorSource.hint)
			InfoPair(heading: "Added on", item: factorSource.addedOn.ISO8601Format())
			InfoPair(heading: "ID", item: String(factorSource.id.hexCodable.hex().mask(showLast: 6)))
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

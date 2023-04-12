import FeaturePrelude

extension AddLedgerNanoFactorSource.State {
	var viewState: AddLedgerNanoFactorSource.ViewState {
		.init(links: links, selectedLink: selectedLink)
	}
}

// MARK: - AddLedgerNanoFactorSource.View
extension AddLedgerNanoFactorSource {
	public struct ViewState: Equatable {
		let links: IdentifiedArrayOf<P2PLink>
		let selectedLink: P2PLink?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddLedgerNanoFactorSource>

		public init(store: StoreOf<AddLedgerNanoFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
//			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
//				VStack {
//
			//                    Picker(
			//                        "Link",
			//                        selection: viewStore.binding(
			//                            get: \.selectedLink,
			//                            send: { .selectedLink($0) }
			//                        )
			//                    ) {
			//                        ForEach(viewStore.supportedCurves, id: \.self) { curve in
			//                            Text("\(String(describing: curve))").tag(curve.rawValue)
			//                        }
			//                    }
//
//					Button("Send Add Ledger Request") {
//						viewStore.send(.sendAddLedgerRequestButtonTapped)
//					}
//					.buttonStyle(.primaryRectangular)
//				}
			//                .onAppear { viewStore.send(.appeared) }
//				.padding(.horizontal, .medium3)
			//                .task {
			//                    await ViewStore(store.stateless).send(.view(.task)).finish()
			//                }
//			}
			Text("IMPL ME")
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AddLedgerNanoFactorSource_Preview
struct AddLedgerNanoFactorSource_Preview: PreviewProvider {
	static var previews: some View {
		AddLedgerNanoFactorSource.View(
			store: .init(
				initialState: .previewValue,
				reducer: AddLedgerNanoFactorSource()
			)
		)
	}
}

extension AddLedgerNanoFactorSource.State {
	public static let previewValue = Self()
}
#endif

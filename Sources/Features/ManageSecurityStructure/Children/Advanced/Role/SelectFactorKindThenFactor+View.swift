import FeaturePrelude

extension SelectFactorKindThenFactor.State {
	var viewState: SelectFactorKindThenFactor.ViewState {
		.init()
	}
}

// MARK: - SelectFactorKindThenFactor.View
extension SelectFactorKindThenFactor {
	public struct ViewState: Equatable {
		// TODO: declare some properties
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
					VStack(spacing: .medium1) {
						Text("Select Factor kind")
							.font(.app.body1Header)

						ForEach(FactorSourceKind.allCases) { kind in
							Button(kind.selectedFactorDisplay) {
								viewStore.send(.selected(kind))
							}
							.buttonStyle(.borderedProminent)
						}
					}
				}
				.sheet(
					store: store.scope(
						state: \.$factorSourceOfKind,
						action: { .child(.factorSourceOfKind($0)) }
					),
					content: { FactorSourcesOfKindList<FactorSource>.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SelectFactorKindThenFactor_Preview
struct SelectFactorKindThenFactor_Preview: PreviewProvider {
	static var previews: some View {
		SelectFactorKindThenFactor.View(
			store: .init(
				initialState: .previewValue,
				reducer: SelectFactorKindThenFactor()
			)
		)
	}
}

extension SelectFactorKindThenFactor.State {
	public static let previewValue = Self()
}
#endif

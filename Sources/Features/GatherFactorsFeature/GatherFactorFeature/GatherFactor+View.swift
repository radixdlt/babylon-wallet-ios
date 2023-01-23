import FeaturePrelude

// MARK: - GatherFactor.View
public extension GatherFactor {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<GatherFactor>

		public init(store: StoreOf<GatherFactor>) {
			self.store = store
		}
	}
}

public extension GatherFactor.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(spacing: 40) {
				Text("Kind: \(viewStore.kind)")
				Text("ID: \(viewStore.id)")
				Text("Created: \(viewStore.createdOn)")

				Button("Mock result") {
					viewStore.send(.mockResultButtonTapped)
				}
				.buttonStyle(.primaryRectangular)
			}
		}
	}
}

// MARK: - GatherFactor.View.ViewState
extension GatherFactor.View {
	struct ViewState: Equatable {
		public var kind: String
		public var id: String
		public var createdOn: String
		init(state: GatherFactor.State) {
			let source = state.factorSource.any()
			kind = String(describing: source.factorSourceKind)
			id = source.factorSourceID.description
			createdOn = source.creationDate.ISO8601Format()
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - GatherFactor_Preview
struct GatherFactor_Preview: PreviewProvider {
	static var previews: some View {
		GatherFactor.View(
			store: .init(
				initialState: .previewValue,
				reducer: GatherFactor()
			)
		)
	}
}
#endif

import FeaturePrelude

extension AddTrustedContactFactorSource.State {
	var viewState: AddTrustedContactFactorSource.ViewState {
		.init()
	}
}

// MARK: - AddTrustedContactFactorSource.View
extension AddTrustedContactFactorSource {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddTrustedContactFactorSource>

		public init(store: StoreOf<AddTrustedContactFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: AddTrustedContactFactorSource")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AddTrustedContactFactorSource_Preview
struct AddTrustedContactFactorSource_Preview: PreviewProvider {
	static var previews: some View {
		AddTrustedContactFactorSource.View(
			store: .init(
				initialState: .previewValue,
				reducer: AddTrustedContactFactorSource()
			)
		)
	}
}

extension AddTrustedContactFactorSource.State {
	public static let previewValue = Self()
}
#endif

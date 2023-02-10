import FeaturePrelude

// MARK: - ___VARIABLE_featureName___.View
public extension ___VARIABLE_featureName___ {
	struct ViewState: Equatable {
		public init(state: ___VARIABLE_featureName___.State) {
			// TODO: implement
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<___VARIABLE_featureName___>

		public init(store: StoreOf<___VARIABLE_featureName___>) {
			self.store = store
		}

		public var body: some View {
			WithViewStore(
				store,
				observe: ___VARIABLE_featureName___.ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				// TODO: implement
				Text("Implement: ___VARIABLE_featureName___")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ___VARIABLE_featureName____Preview
struct ___VARIABLE_featureName____Preview: PreviewProvider {
	static var previews: some View {
		___VARIABLE_featureName___.View(
			store: .init(
				initialState: .previewValue,
				reducer: ___VARIABLE_featureName___()
			)
		)
	}
}

public extension ___VARIABLE_featureName___.State {
	static let previewValue = Self()
}
#endif

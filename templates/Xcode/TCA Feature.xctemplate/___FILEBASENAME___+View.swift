import ComposableArchitecture
import SwiftUI

// MARK: - ___VARIABLE_featureName___.View
public extension ___VARIABLE_featureName___ {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<___VARIABLE_featureName___>

		public init(store: StoreOf<___VARIABLE_featureName___>) {
			self.store = store
		}
	}
}

public extension ___VARIABLE_featureName___.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
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

// MARK: - ___VARIABLE_featureName___.View.ViewState
extension ___VARIABLE_featureName___.View {
	struct ViewState: Equatable {
		init(state: ___VARIABLE_featureName___.State) {
			// TODO: implement
		}
	}
}

#if DEBUG

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
#endif

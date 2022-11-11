import ComposableArchitecture
import SwiftUI

// MARK: - ___VARIABLE_moduleName___.View
public extension ___VARIABLE_moduleName___ {
	struct View: SwiftUI.View {
		private let store: StoreOf<___VARIABLE_moduleName___>

		public init(store: StoreOf<___VARIABLE_moduleName___>) {
			self.store = store
		}
	}
}

public extension ___VARIABLE_moduleName___.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: (/___VARIABLE_moduleName___.Action.view).embed
		) { _ in
			// TODO: implement
			Text("Implement: ___VARIABLE_moduleName___")
				.background(Color.yellow)
				.foregroundColor(.red)
		}
	}
}

// MARK: - ___VARIABLE_moduleName___.View.ViewState
extension ___VARIABLE_moduleName___.View {
	struct ViewState: Equatable {
		init(state: ___VARIABLE_moduleName___.State) {
			// TODO: implement
		}
	}
}

// MARK: - ___VARIABLE_moduleName____Preview
struct ___VARIABLE_moduleName____Preview: PreviewProvider {
	static var previews: some View {
		___VARIABLE_moduleName___.View(
			store: .init(
				initialState: .placeholder,
				reducer: ___VARIABLE_moduleName___()
			)
		)
	}
}

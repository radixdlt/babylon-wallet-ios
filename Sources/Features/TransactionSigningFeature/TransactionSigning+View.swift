import ComposableArchitecture
import SwiftUI

// MARK: - TransactionSigning.View
public extension TransactionSigning {
	struct View: SwiftUI.View {
		private let store: StoreOf<TransactionSigning>

		public init(store: StoreOf<TransactionSigning>) {
			self.store = store
		}
	}
}

public extension TransactionSigning.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: TransactionSigning.Action.init
		) { _ in
			// TODO: implement
			Text("Implement: TransactionSigning")
				.background(Color.yellow)
				.foregroundColor(.red)
		}
	}
}

// MARK: - TransactionSigning.View.ViewAction
extension TransactionSigning.View {
	enum ViewAction: Equatable {}
}

extension TransactionSigning.Action {
	init(action: TransactionSigning.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - TransactionSigning.View.ViewState
extension TransactionSigning.View {
	struct ViewState: Equatable {
		init(state _: TransactionSigning.State) {
			// TODO: implement
		}
	}
}

// MARK: - TransactionSigning_Preview
struct TransactionSigning_Preview: PreviewProvider {
	static var previews: some View {
		TransactionSigning.View(
			store: .init(
				initialState: .placeholder,
				reducer: TransactionSigning()
			)
		)
	}
}

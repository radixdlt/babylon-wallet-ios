import ComposableArchitecture
import DesignSystem
import EngineToolkit
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
			observe: ViewState.init
		) { viewStore in
			VStack(spacing: 20) {
				Text(viewStore.state.transactionManifestDescription)
					.padding()
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
					.multilineTextAlignment(.leading)
					.background(Color(white: 0.9))
				PrimaryButton(title: "Sign Transaction") {
					viewStore.send(.signTransaction)
				}
			}
			.padding()
		}
	}
}

// MARK: - TransactionSigning.View.ViewState
extension TransactionSigning.View {
	struct ViewState: Equatable {
		let transactionManifestDescription: String

		init(state: TransactionSigning.State) {
			transactionManifestDescription = state.transactionManifest.description
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

import Common
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
				NavigationBar("Confirm transaction", style: .back) {
					viewStore.send(.delegate(.dismissView))
				}
				ScrollView([.horizontal, .vertical], showsIndicators: false) {
					Text(viewStore.state.manifest)
						.padding()
						.font(.system(size: 13, design: .monospaced))
						.lineLimit(viewStore.state.numberOfLines)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
						.multilineTextAlignment(.leading)
				}
				.background(Color(white: 0.9))
				PrimaryButton(title: "Sign Transaction") {
					viewStore.send(.view(.signTransaction))
				}
			}
			.padding([.horizontal, .bottom])
		}
	}
}

// MARK: - TransactionSigning.View.ViewState
extension TransactionSigning.View {
	struct ViewState: Equatable {
		let manifest: String
		let numberOfLines: Int

		init(state: TransactionSigning.State) {
			let manifest = state.transactionManifest.description
			self.manifest = manifest
			numberOfLines = manifest.lines()
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

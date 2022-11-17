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
			observe: ViewState.init,
			send: { .view($0) }
		) { viewStore in
			Screen(title: "Sign TX", navBarActionStyle: .close, action: { viewStore.send(.closeButtonTapped) }) {
				ZStack {
					VStack(spacing: 20) {
						ScrollView([.vertical], showsIndicators: false) {
							Text(viewStore.state.manifest)
								.padding()
								.font(.system(size: 13, design: .monospaced))
								.frame(maxHeight: .infinity, alignment: .topLeading)
						}
						.background(Color(white: 0.9))

						PrimaryButton(
							title: "Sign Transaction",
							isEnabled: viewStore.isSignButtonEnabled
						) {
							viewStore.send(.signTransactionButtonTapped)
						}
					}
					.padding([.horizontal, .bottom])

					if viewStore.isShowingLoader {
						LoadingView()
					}
				}
			}
		}
	}
}

// MARK: - TransactionSigning.View.ViewState
extension TransactionSigning.View {
	struct ViewState: Equatable {
		let manifest: String
		let numberOfLines: Int
		let isShowingLoader: Bool
		let isSignButtonEnabled: Bool

		init(state: TransactionSigning.State) {
			let manifest = state.transactionManifest.toString(preamble: "", blobOutputFormat: .includeBlobsByByteCountOnly, blobPreamble: "\n\nBLOBS:\n", networkID: .primary)
			self.manifest = manifest
			numberOfLines = manifest.lines()
			isShowingLoader = state.isSigningTX
			isSignButtonEnabled = !state.isSigningTX
		}
	}
}

#if DEBUG

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
#endif // DEBUG

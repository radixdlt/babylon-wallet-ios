import Common
import ComposableArchitecture
import DesignSystem
import EngineToolkit
import Resources
import SwiftUI

// MARK: - TransactionSigning.View
public extension TransactionSigning {
	@MainActor
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
			ForceFullScreen {
				VStack {
					NavigationBar(
						titleText: L10n.TransactionSigning.title,
						leadingItem: CloseButton {
							viewStore.send(.closeButtonTapped)
						}
					)
					ForceFullScreen {
						VStack(spacing: 20) {
							ScrollView([.vertical], showsIndicators: false) {
								if let manifest = viewStore.manifest {
									Text(manifest)
										.padding()
										.font(.system(size: 13, design: .monospaced))
										.frame(maxHeight: .infinity, alignment: .topLeading)
								}
							}
							.background(Color(white: 0.9))

							Button(L10n.TransactionSigning.signTransactionButtonTitle) {
								viewStore.send(.signTransactionButtonTapped)
							}
							.buttonStyle(.primaryRectangular)
							.enabled(viewStore.isSignButtonEnabled)
						}
						.padding([.horizontal, .bottom])
					}
					Spacer()
				}
				.loadingState {
					if viewStore.manifest == nil {
						return LoadingState(context: .global(text: L10n.TransactionSigning.preparingTransactionLoadingText))
					} else if viewStore.isShowingLoader {
						return LoadingState(context: .global(text: L10n.TransactionSigning.signingAndSubmittingTransactionLoadingText))
					} else {
						return nil
					}
				}
				.onAppear {
					viewStore.send(.didAppear)
				}
			}
		}
	}
}

// MARK: - TransactionSigning.View.ViewState
extension TransactionSigning.View {
	struct ViewState: Equatable {
		let manifest: String?
		let isShowingLoader: Bool
		let isSignButtonEnabled: Bool

		init(state: TransactionSigning.State) {
			manifest = state.transactionWithLockFeeString
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

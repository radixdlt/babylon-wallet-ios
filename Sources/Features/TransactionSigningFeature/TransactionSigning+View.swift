import Common
import ComposableArchitecture
import DesignSystem
import EngineToolkit
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
						ZStack {
							VStack(spacing: 20) {
								if let manifest = viewStore.manifest {
									ScrollView([.vertical], showsIndicators: false) {
										Text(manifest)
											.padding()
											.font(.system(size: 13, design: .monospaced))
											.frame(maxHeight: .infinity, alignment: .topLeading)
									}
									.background(Color(white: 0.9))

									Button(L10n.TransactionSigning.signTransactionButtonTitle) {
										viewStore.send(.signTransactionButtonTapped)
									}
									.buttonStyle(.primaryRectangular)
									.enabled(viewStore.isSignButtonEnabled)
								} else {
									LoadingView()
								}
							}
							.padding([.horizontal, .bottom])

							if viewStore.isShowingLoader {
								LoadingView()
							}
						}
					}
					Spacer()
				}
				.onAppear {
					viewStore.send(.didAppear)
				}
			}
		}
	}
}

private extension TransactionSigning.View {
	@ViewBuilder
	func sign(
		manifest: String,
		viewStore: ViewStore<ViewState, TransactionSigning.Action.ViewAction>
	) -> some View {}
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

import FeaturePrelude

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
								.controlState(viewStore.signButtonState)
							}
						}
						.padding([.horizontal, .bottom])
					}
					.controlState(viewStore.viewControlState)
					Spacer()
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
		let signButtonState: ControlState
		let viewControlState: ControlState

		init(state: TransactionSigning.State) {
			manifest = state.transactionWithLockFeeString
			isShowingLoader = state.isSigningTX

			signButtonState = {
				if !state.isSigningTX {
					return .enabled
				} else {
					return .disabled
				}
			}()

			viewControlState = {
				if state.transactionWithLockFeeString == nil {
					return .loading(.global(text: L10n.TransactionSigning.preparingTransactionLoadingText))
				} else if state.isSigningTX {
					return .loading(.global(text: L10n.TransactionSigning.signingAndSubmittingTransactionLoadingText))
				} else {
					return .enabled
				}
			}()
		}
	}
}

#if DEBUG

// MARK: - TransactionSigning_Preview
struct TransactionSigning_Preview: PreviewProvider {
	static var previews: some View {
		TransactionSigning.View(
			store: .init(
				initialState: .previewValue,
				reducer: TransactionSigning()
			)
		)
	}
}
#endif // DEBUG

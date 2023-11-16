extension ConfirmSkippingBDFS.State {
	var viewState: ConfirmSkippingBDFS.ViewState {
		.init(flashScrollIndicators: flashScrollIndicators)
	}
}

// MARK: - ConfirmSkippingBDFS.View
extension ConfirmSkippingBDFS {
	public struct ViewState: Equatable {
		let flashScrollIndicators: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ConfirmSkippingBDFS>

		public init(store: StoreOf<ConfirmSkippingBDFS>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					// FIXME: Strings
					Text("No Main Seed Phrase?")
						.textStyle(.sheetTitle)
						.padding(.horizontal, -.small2)

					ScrollView(.vertical, showsIndicators: true) {
						Text("The Radix Wallet always uses a single main “Babylon” seed phrase to generate new Personas and new Accounts (when not using a Ledger device).\n\nIf you do not have access to your previous main seed phrase, you can skip entering it for now. The Radix Wallet will create a new one, which will be used for new Personas and Accounts.\n\nYour old Accounts and Personas will still be listed, but you will have to enter their original seed phrase to use them. Alternatively, you can hide them if you no longer are interested in using them.")
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.leading)
					}
					.conditionalModifier {
						if #available(iOS 17, *) {
							$0.scrollIndicatorsFlash(trigger: viewStore.flashScrollIndicators)
						} else {
							$0
						}
					}

					// FIXME: Strings
					Button("Skip Main Seed Phrase Entry") {
						store.send(.view(.confirmTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
				.padding(.horizontal, .large3)
				.padding(.bottom, .medium2)
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						BackButton {
							store.send(.view(.backButtonTapped))
						}
					}
				}
			}
		}
	}
}

extension View {
	func conditionalModifier(@ViewBuilder _ closure: (Self) -> some View) -> some View {
		closure(self)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ConfirmSkippingBDFS_Preview
struct ConfirmSkippingBDFS_Preview: PreviewProvider {
	static var previews: some View {
		ConfirmSkippingBDFS.View(
			store: .init(
				initialState: .previewValue,
				reducer: ConfirmSkippingBDFS.init
			)
		)
	}
}

extension ConfirmSkippingBDFS.State {
	public static let previewValue = Self()
}
#endif

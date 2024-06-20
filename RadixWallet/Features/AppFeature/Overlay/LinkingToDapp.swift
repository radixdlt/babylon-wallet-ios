import Foundation

// MARK: - LinkingToDapp
struct LinkingToDapp: FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable, Equatable {
		let dAppMetadata: DappMetadata

		init(dAppMetadata: DappMetadata) {
			self.dAppMetadata = dAppMetadata
		}
	}

	enum ViewAction: Sendable, Equatable {
		case continueTapped
		case cancel
	}

	enum DelegateAction: Sendable, Equatable {
		case continueFlow(DappMetadata)
		case cancel
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.send(.delegate(.continueFlow(state.dAppMetadata)))
		case .cancel:
			.send(.delegate(.cancel))
		}
	}
}

// MARK: LinkingToDapp.View
extension LinkingToDapp {
	struct View: SwiftUI.View {
		let store: StoreOf<LinkingToDapp>

		var body: some SwiftUI.View {
			VStack(spacing: .medium1) {
				CloseButton {
					store.send(.view(.cancel))
				}
				.flushedLeft

				VStack(spacing: .medium3) {
					Thumbnail(.dapp, url: store.dAppMetadata.thumbnail, size: .medium)

					Text("Have you come from a genuine website?")
						.foregroundColor(.app.gray1)
						.lineSpacing(0)
						.textStyle(.sheetTitle)

					Text("Before you connect to **\(store.dAppMetadata.name)**, you should be confident the site is safe.")
						.foregroundColor(.app.gray1)
						.textStyle(.body1Regular)
				}
				.multilineTextAlignment(.center)
				.padding(.bottom, .small2)

				VStack {
					Text("- Check the website address to see if it matches what you are expecting")
					Text("- If you came from a social media ad, make sure it's legitimate")
				}
				.textStyle(.body1Regular)
				.padding()
				.background(.app.gray3)

				Spacer()
			}
			.padding(.horizontal, .medium1)
			.padding(.vertical, .medium1)
			.background(.app.background)
			.footer {
				Button(L10n.DAppRequest.Login.continue) {
					store.send(.view(.continueTapped))
				}
				.buttonStyle(.primaryRectangular)
			}
		}
	}
}

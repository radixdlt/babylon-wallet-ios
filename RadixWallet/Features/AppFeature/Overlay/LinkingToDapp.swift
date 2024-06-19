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
		case continueFlow
		case cancel
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.send(.delegate(.continueFlow))
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
			CloseButton {
				store.send(.view(.cancel))
			}
			.flushedLeft

			VStack(spacing: .medium1) {
				DappHeader(
					thumbnail: store.dAppMetadata.thumbnail,
					title: "Verifying dApp",
					subtitle: "\(store.dAppMetadata.name) is requesting verification"
				)

				Text("**\(store.dAppMetadata.name)** from **\(store.dAppMetadata.origin)** wants to make requests to your Radix Wallet. Click Continue to confirm the identity of this dApp and proceed with the request.")
					.textStyle(.body1HighImportance)

				Spacer()

				Button(L10n.DAppRequest.Login.continue) {
					store.send(.view(.continueTapped))
				}
				.buttonStyle(.primaryRectangular)
			}
			.padding(.horizontal, .medium1)
			.padding(.vertical, .medium1)
		}
	}
}

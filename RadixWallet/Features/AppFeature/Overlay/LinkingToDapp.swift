import Foundation

// MARK: - LinkingToDapp
struct LinkingToDapp: FeatureReducer {
	struct State: Sendable, Hashable {
		let dismissDelay: Double
		let cancellationId = UUID()

		var timer: Double
		var autoDismissEnabled: Bool
		var autoDismissSelection: Bool
		let dAppMetadata: DappMetadata

		init(dismissDelay: Double, autoDismissEnabled: Bool, dAppMetadata: DappMetadata) {
			self.dismissDelay = dismissDelay
			self.timer = dismissDelay
			self.dAppMetadata = dAppMetadata
			self.autoDismissEnabled = autoDismissEnabled
			self.autoDismissSelection = false
		}
	}

	enum ViewAction: Sendable, Equatable {
		case cancel
		case task
		case continueTapped
		case autoDismissEnabled(Bool)
	}

	enum DelegateAction: Sendable, Equatable {
		case cancel
		case continueFlow
	}

	enum InternalAction: Sendable, Equatable {
		case timerTick
	}

	@Dependency(\.continuousClock) var continuousClock
	var userDefaults = UserDefaults.Dependency.radix

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .none

		case .continueTapped:
			userDefaults.setDappLinkingAutoContinueEnabled(state.autoDismissSelection)
			return .concatenate(.cancel(id: state.cancellationId), .send(.delegate(.continueFlow)))

		case let .autoDismissEnabled(value):
			state.autoDismissSelection = value
			return .none

		case .cancel:
			return .concatenate(.cancel(id: state.cancellationId), .send(.delegate(.cancel)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .timerTick:
			state.timer -= 0.1
			if state.timer < 0 {
				return .concatenate(.cancel(id: state.cancellationId), .send(.delegate(.continueFlow)))
			}
			return .none
		}
	}
}

// MARK: LinkingToDapp.View
extension LinkingToDapp {
	struct View: SwiftUI.View {
		let store: StoreOf<LinkingToDapp>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				CloseButton {
					viewStore.send(.cancel)
				}
				.flushedLeft

				VStack(spacing: .medium1) {
					DappHeader(
						thumbnail: viewStore.dAppMetadata.thumbnail,
						title: "Verifying dApp",
						subtitle: "\(viewStore.dAppMetadata.name) is requesting verification"
					)

					Text("**\(viewStore.dAppMetadata.name)** from **\(viewStore.dAppMetadata.origin.absoluteString)** wants to make requests to your Radix Wallet. Click Continue to confirm the identity of this dApp and proceed with the request.")
						.textStyle(.body1HighImportance)

					Spacer()

					Button(L10n.DAppRequest.Login.continue) {
						viewStore.send(.continueTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.horizontal, .medium1)
				.padding(.vertical, .medium1)
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}
	}
}

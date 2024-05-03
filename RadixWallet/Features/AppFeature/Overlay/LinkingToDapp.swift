import Foundation

// MARK: - LinkingToDapp
struct LinkingToDapp: FeatureReducer {
	struct State: Sendable, Hashable {
		let dismissDelay: Double
		let cancellationId = UUID()

		var timer: Double
		let dAppMetadata: DappMetadata

		init(dismissDelay: Double, dAppMetadata: DappMetadata) {
			self.dismissDelay = dismissDelay
			self.timer = dismissDelay
			self.dAppMetadata = dAppMetadata
		}
	}

	enum ViewAction: Sendable {
		case task
		case continueTapped
	}

	enum DelegateAction: Sendable {
		case dismiss
	}

	enum InternalAction: Sendable {
		case timerTick
	}

	@Dependency(\.continuousClock) var continuousClock

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { [dismissDelay = state.dismissDelay] send in
				for await tick in continuousClock.timer(interval: .milliseconds(100)) {
					await send(.internal(.timerTick))
				}
			}
			.cancellable(id: state.cancellationId, cancelInFlight: true)

		case .continueTapped:
			.concatenate(.cancel(id: state.cancellationId), .send(.delegate(.dismiss)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .timerTick:
			state.timer -= 0.1
			if state.timer < 0 {
				return .concatenate(.cancel(id: state.cancellationId), .send(.delegate(.dismiss)))
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
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .medium1) {
					DappHeader(
						thumbnail: viewStore.dAppMetadata.thumbnail,
						title: "Verifying dApp",
						subtitle: "\(viewStore.dAppMetadata.name) is requesting verification"
					)

					Text("**\(viewStore.dAppMetadata.name)** wants to make requests to your Radix Wallet. Click Continue to verify the identity of this dApp and proceed with the request.")
						.textStyle(.body1HighImportance)

					Spacer()
				}
				.padding(.horizontal, .medium1)
				.padding(.vertical, .medium1)
				.footer {
					Button(L10n.DAppRequest.Login.continue) {
						store.send(.view(.continueTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

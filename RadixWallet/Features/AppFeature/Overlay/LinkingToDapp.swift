import Foundation

// MARK: - LinkingToDapp
public struct LinkingToDapp: FeatureReducer {
	public struct State: Sendable, Hashable {
		let dismissDelay: Double
		fileprivate let cancellationId = UUID()

		var timer: Double
		var autoDismissEnabled: Bool
		var autoDismissSelection: Bool
		let dAppMetadata: DappMetadata
		let returnUrl: URL

		init(dismissDelay: Double, autoDismissEnabled: Bool, dAppMetadata: DappMetadata, returnUrl: URL) {
			self.dismissDelay = dismissDelay
			self.timer = dismissDelay
			self.dAppMetadata = dAppMetadata
			self.autoDismissEnabled = autoDismissEnabled
			self.autoDismissSelection = false
			self.returnUrl = returnUrl
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case cancel
		case task
		case continueTapped
		case autoDismissEnabled(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case cancel
		case continueFlow(URL)
	}

	public enum InternalAction: Sendable, Equatable {
		case timerTick
	}

	@Dependency(\.continuousClock) var continuousClock
	@Dependency(\.userDefaults) var userDefaults

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			guard state.autoDismissEnabled else {
				return .none
			}
			return .run { send in
				for await tick in continuousClock.timer(interval: .milliseconds(100)) {
					await send(.internal(.timerTick))
				}
			}
			.cancellable(id: state.cancellationId, cancelInFlight: true)

		case .continueTapped:
			userDefaults.setDappLinkingAutoContinueEnabled(state.autoDismissSelection)
			return .concatenate(.cancel(id: state.cancellationId), .send(.delegate(.continueFlow(state.returnUrl))))

		case let .autoDismissEnabled(value):
			state.autoDismissSelection = value
			return .none

		case .cancel:
			return .concatenate(.cancel(id: state.cancellationId), .send(.delegate(.cancel)))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .timerTick:
			state.timer -= 0.1
			if state.timer < 0 {
				return .concatenate(.cancel(id: state.cancellationId), .send(.delegate(.continueFlow(state.returnUrl))))
			}
			return .none
		}
	}
}

// MARK: LinkingToDapp.View
extension LinkingToDapp {
	public struct View: SwiftUI.View {
		let store: StoreOf<LinkingToDapp>

		public var body: some SwiftUI.View {
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

					Text("**\(viewStore.dAppMetadata.name)** wants to make requests to your Radix Wallet. Click Continue to verify the identity of this dApp and proceed with the request.")
						.textStyle(.body1HighImportance)

					Spacer()

					if !viewStore.autoDismissEnabled {
						ToggleView(
							title: "Auto Confirm",
							subtitle: "Auto confirm next dApp verification requests",
							isOn: viewStore.binding(
								get: \.autoDismissSelection,
								send: { .autoDismissEnabled($0) }
							)
						)
						.textStyle(.body1HighImportance)

						Button(L10n.DAppRequest.Login.continue) {
							viewStore.send(.continueTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
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

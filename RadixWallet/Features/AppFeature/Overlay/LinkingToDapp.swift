import Foundation

// MARK: - LinkingToDapp
struct LinkingToDapp: FeatureReducer {
	struct State: Sendable, Hashable {
		let dismissDelay: Double
		let cancellationId = UUID()

		var timer: Double

		init(dismissDelay: Double) {
			self.dismissDelay = dismissDelay
			self.timer = dismissDelay
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
					Spacer()
					Text("Linking to dApp")
						.textStyle(.sheetTitle)
						.padding(.bottom, .medium1)

					Spacer()
					ProgressView("Current dApp Link delay is \(viewStore.dismissDelay) seconds", value: viewStore.timer, total: viewStore.dismissDelay)
						.textStyle(.body1HighImportance)

					Button("Link on action") {
						store.send(.view(.continueTapped))
					}
					.buttonStyle(.primaryRectangular)
					Spacer()
				}
				.padding()
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
			}
		}
	}
}

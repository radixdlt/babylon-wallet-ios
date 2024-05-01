import Foundation

// MARK: - DappLinkingDelay
public struct DappLinkingDelay: FeatureReducer {
	public struct State: Hashable, Sendable {
		public var delayInSeconds: Double
	}

	public enum ViewAction: Equatable, Sendable {
		case delayChanged(Double)
		case saveTapped
	}

	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .delayChanged(double):
			state.delayInSeconds = double
			return .none
		case .saveTapped:
			userDefaults.setDappLinkingDelay(state.delayInSeconds)
			overlayWindowClient.scheduleHUD(.copied)
			return .none
		}
	}
}

// MARK: DappLinkingDelay.View
extension DappLinkingDelay {
	public struct View: SwiftUI.View {
		let store: StoreOf<DappLinkingDelay>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack {
					Text("Select Time: \(viewStore.delayInSeconds, specifier: "%.2f") seconds")
						.padding()

					Slider(
						value: Binding(
							get: { viewStore.delayInSeconds },
							set: { store.send(.view(.delayChanged($0))) }
						),
						in: 0 ... 120,
						step: 0.1
					)
					.padding()

					Button("Confirm") {
						store.send(.view(.saveTapped))
					}
					.buttonStyle(.primaryRectangular)
					.padding()
					.cornerRadius(8)
				}
				.padding()
			}
		}
	}
}

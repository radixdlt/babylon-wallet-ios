import Foundation

// MARK: - DappLinkingDelay
public struct DappLinkingDelay: FeatureReducer {
	public struct State: Hashable, Sendable {
		public var isEnabled: Bool = false
		public var delayInSeconds: Double = 1.0
	}

	public enum ViewAction: Equatable, Sendable {
		case task
		case isEnabled(Bool)
		case delayChanged(Double)
		case saveTapped
	}

	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.isEnabled = userDefaults.getDappLinkingAutoContinueEnabled()
			state.delayInSeconds = userDefaults.getDappLinkingDelay()
			return .none
		case let .isEnabled(value):
			state.isEnabled = value
			return .none
		case let .delayChanged(double):
			state.delayInSeconds = double
			return .none
		case .saveTapped:
			userDefaults.setDappLinkingAutoContinueEnabled(state.isEnabled)
			userDefaults.setDappLinkingDelay(state.delayInSeconds)
			overlayWindowClient.scheduleHUD(.init(text: "Saved"))
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
					Toggle(isOn: .init(
						get: { viewStore.isEnabled },
						set: { viewStore.send(.isEnabled($0)) }
					), label: {
						Text("Automatically verify dApps")
					})

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
			.task {
				store.send(.view(.task))
			}
		}
	}
}

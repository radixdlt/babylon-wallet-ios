import FeaturePrelude
import GatewaysClient
import NetworkSwitchingClient

// MARK: - AddNewGateway
public struct AddNewGateway: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Field: String, Sendable, Hashable {
			case gatewayURL
		}

		var focusedField: Field?
		var inputtedURL: String = ""
		var errorText: String?
		var addGatewayButtonState: ControlState = .disabled

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case addNewGatewayButtonTapped
		case textFieldFocused(State.Field?)
		case textFieldChanged(String)
	}

	public enum InternalAction: Sendable, Equatable {
		case focusTextField(State.Field?)
		case gatewayValidationResult(TaskResult<Gateway?>)
		case addGatewayResult(TaskResult<EquatableVoid>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient
	@Dependency(\.gatewaysClient) var gatewaysClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.focusTextField(.gatewayURL)))
			}

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case .addNewGatewayButtonTapped:
			guard let url = URL(string: state.inputtedURL) else { return .none }
			state.addGatewayButtonState = .loading(.local)
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.validateGatewayURL(url)
				}
				return .internal(.gatewayValidationResult(result))
			}

		case let .textFieldFocused(focus):
			return .run { send in
				await send(.internal(.focusTextField(focus)))
			}

		case let .textFieldChanged(inputtedURL):
			state.inputtedURL = inputtedURL
			state.errorText = nil
			let url = URL(string: inputtedURL)
			state.addGatewayButtonState = url != nil ? .enabled : .disabled
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case let .gatewayValidationResult(.success(gateway)):
			guard let gateway = gateway else {
				state.errorText = L10n.GatewaySettings.AddNewGateway.Error.noGatewayFound
				return .none
			}

			return .task {
				let result = await TaskResult {
					let _ = try await gatewaysClient.addGateway(gateway)
					return EquatableVoid()
				}
				return .internal(.addGatewayResult(result))
			}

		case let .gatewayValidationResult(.failure(error)):
			return handle(error, state: &state)

		case .addGatewayResult(.success):
			return .send(.delegate(.dismiss))

		case let .addGatewayResult(.failure(error)):
			return handle(error, state: &state)
		}
	}
}

private extension AddNewGateway {
	func handle(_ error: Error, state: inout State) -> EffectTask<Action> {
		state.errorText = error.legibleLocalizedDescription.capitalized
		state.addGatewayButtonState = .disabled
		errorQueue.schedule(error)
		return .none
	}
}

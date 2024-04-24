import ComposableArchitecture
import SwiftUI

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
		case addGatewayResult(TaskResult<EqVoid>)
		case showDuplicateURLError
		case validateNewGateway(URL)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient
	@Dependency(\.gatewaysClient) var gatewaysClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.focusTextField(.gatewayURL)))
			}

		case .closeButtonTapped:
			return .send(.delegate(.dismiss))

		case .addNewGatewayButtonTapped:
			guard let url = URL(string: state.inputtedURL)?.httpsURL else { return .none }

			return .run { send in
				let gateways = await gatewaysClient.getAllGateways()
				let duplicate = gateways.first(where: { $0.url == url })
				if let _ = duplicate {
					await send(.internal(.showDuplicateURLError))
				} else {
					await send(.internal(.validateNewGateway(url)))
				}
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case let .gatewayValidationResult(.success(gateway)):
			guard let gateway else {
				state.errorText = L10n.Gateways.AddNewGateway.errorNoGatewayFound
				return .none
			}

			return .run { send in
				let result = await TaskResult {
					let _ = try await gatewaysClient.addGateway(gateway)
					return EqVoid.instance
				}
				await send(.internal(.addGatewayResult(result)))
			}

		case let .gatewayValidationResult(.failure(error)):
			return handle(error, state: &state)

		case .addGatewayResult(.success):
			return .send(.delegate(.dismiss))

		case let .addGatewayResult(.failure(error)):
			return handle(error, state: &state)

		case .showDuplicateURLError:
			state.errorText = L10n.Gateways.AddNewGateway.errorDuplicateURL
			return .none

		case let .validateNewGateway(url):
			state.addGatewayButtonState = .loading(.local)
			return .run { send in
				let result = await TaskResult {
					try await networkSwitchingClient.validateGatewayURL(url)
				}
				await send(.internal(.gatewayValidationResult(result)))
			}
		}
	}
}

private extension AddNewGateway {
	func handle(_ error: Error, state: inout State) -> Effect<Action> {
		state.errorText = L10n.Gateways.AddNewGateway.errorNoGatewayFound
		state.addGatewayButtonState = .disabled
		errorQueue.schedule(error)
		return .none
	}
}

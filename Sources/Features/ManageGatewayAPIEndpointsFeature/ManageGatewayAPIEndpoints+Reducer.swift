import CreateEntityFeature
import FeaturePrelude
import GatewayAPI
import NetworkSwitchingClient

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Field: String, Sendable, Hashable {
			case gatewayURL
		}

		@PresentationState
		public var destination: Destinations.State?

		public var urlString: String
		public var currentGateway: Gateway?
		public var isValidatingEndpoint: Bool
		public var isSwitchToButtonEnabled: Bool

		public var validatedNewGatewayToSwitchTo: Gateway?
		public var focusedField: Field?

		var controlState: ControlState {
			if isValidatingEndpoint {
				return .loading(.local)
			} else if isSwitchToButtonEnabled {
				return .enabled
			} else {
				return .disabled
			}
		}

		public init(
			urlString: String = "",
			currentGateway: Gateway? = nil,
			validatedNewGatewayToSwitchTo: Gateway? = nil,
			isSwitchToButtonEnabled: Bool = false,
			isValidatingEndpoint: Bool = false
		) {
			self.urlString = urlString
			self.currentGateway = currentGateway
			self.validatedNewGatewayToSwitchTo = validatedNewGatewayToSwitchTo
			self.isSwitchToButtonEnabled = isSwitchToButtonEnabled
			self.isValidatingEndpoint = isValidatingEndpoint
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case urlStringChanged(String)
		case switchToButtonTapped
		case focusTextField(ManageGatewayAPIEndpoints.State.Field?)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadGatewayResult(TaskResult<Gateway>)
		/// Nil if no change was needed
		case gatewayValidationResult(TaskResult<Gateway?>)
		case hasAccountsResult(TaskResult<Bool>)
		case createAccountOnNetworkBeforeSwitchingToIt(Gateway)
		case switchToResult(TaskResult<Gateway>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationActionOf<ManageGatewayAPIEndpoints.Destinations>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case networkChanged
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .task {
				let result = await TaskResult {
					await networkSwitchingClient.getCurrentGateway()
				}
				return .internal(.loadGatewayResult(result))
			}

		case let .urlStringChanged(urlString):
			state.urlString = urlString
			let maybeURL = URL(string: urlString)
			state.isSwitchToButtonEnabled = maybeURL != nil && !(state.currentGateway?.url == maybeURL)
			return .none

		case .switchToButtonTapped:
			assert(state.isSwitchToButtonEnabled)
			guard let url = URL(string: state.urlString) else {
				return .none
			}
			state.isValidatingEndpoint = true
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.validateGatewayURL(url)
				}
				return .internal(.gatewayValidationResult(result))
			}

		case let .focusTextField(focus):
			state.focusedField = focus
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadGatewayResult(.success(currentGateway)):
			state.currentGateway = currentGateway
			#if DEBUG
			// convenient when testing
			state.urlString = currentGateway.url.absoluteString
			#endif
			return .none

		case let .loadGatewayResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .gatewayValidationResult(.failure(error)):
			state.isValidatingEndpoint = false
			errorQueue.schedule(error)
			return .none

		case let .gatewayValidationResult(.success(maybeNew)):
			state.isValidatingEndpoint = false
			guard let new = maybeNew else {
				return .none
			}
			state.validatedNewGatewayToSwitchTo = new
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.hasAccountOnNetwork(new)
				}
				return .internal(.hasAccountsResult(result))
			}
		case let .hasAccountsResult(.success(hasAccountsOnNetwork)):
			guard let new = state.validatedNewGatewayToSwitchTo else {
				// weird state... should not happen.
				return .none
			}
			return .task {
				if hasAccountsOnNetwork {
					let result = await TaskResult {
						try await networkSwitchingClient.switchTo(new)
					}
					return .internal(.switchToResult(result))
				} else {
					return .internal(.createAccountOnNetworkBeforeSwitchingToIt(new))
				}
			}

		case let .hasAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return skipSwitching(state: &state)

		case let .createAccountOnNetworkBeforeSwitchingToIt(newGateway):
			state.destination = .createAccount(
				.init(config: .init(
					purpose: .firstAccountOnNewNetwork(newGateway.network.id)
				))
			)
			return .none

		case let .switchToResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case .switchToResult(.success):
			return .send(.delegate(.networkChanged))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.createAccount(.delegate(.dismiss)))):
			return skipSwitching(state: &state)

		case .destination(.presented(.createAccount(.delegate(.completed)))):
			state.destination = nil
			guard let new = state.validatedNewGatewayToSwitchTo else {
				// weird state... should not happen.
				return .none
			}
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.switchTo(new)
				}
				return .internal(.switchToResult(result))
			}

		default:
			return .none
		}
	}

	func skipSwitching(state: inout State) -> EffectTask<Action> {
		state.destination = nil
		state.validatedNewGatewayToSwitchTo = nil
		return .none
	}
}

import CreateEntityFeature
import FeaturePrelude
import GatewaysClient
import NetworkSwitchingClient

// MARK: - GatewaySettings
public struct GatewaySettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var gatewayList: GatewayList.State

		@PresentationState var removeGatewayAlert: AlertState<ViewAction.RemoveGatewayAction>?
		@PresentationState var destination: Destinations.State?
		var currentGateway: Gateway?
		var validatedNewGatewayToSwitchTo: Gateway?
		var gatewayForRemoval: Gateway?
		var isPopoverPresented = false

		public init(
			gatewayList: GatewayList.State = .init(gateways: [])
		) {
			self.gatewayList = gatewayList
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case removeGateway(PresentationAction<RemoveGatewayAction>)
		case addGatewayButtonTapped
		case popoverButtonTapped
		case popoverStateChanged(Bool)

		public enum RemoveGatewayAction: Sendable, Hashable {
			case removeButtonTapped(GatewayRow.State)
			case cancelButtonTapped
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case presentGateways(all: [Gateway], current: Gateway)
		case hasAccountsResult(TaskResult<Bool>)
		case createAccountOnNetworkBeforeSwitchingToIt(Gateway)
		case switchToGatewayResult(TaskResult<Gateway>)
		case removeGateway(Gateway)
	}

	public enum ChildAction: Sendable, Equatable {
		case gatewayList(GatewayList.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case networkChanged
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewGateway(AddNewGateway.State)
			case createAccount(CreateAccountCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case addNewGateway(AddNewGateway.Action)
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewGateway, action: /Action.addNewGateway) {
				AddNewGateway()
			}

			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	public enum Error: String, LocalizedError, Sendable, Hashable {
		case errorRemovingGateway
		public var errorDescription: String? {
			switch self {
			case .errorRemovingGateway: return "Error removing gateway"
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.continuousClock) var clock

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.gatewayList, action: /Action.child .. ChildAction.gatewayList) {
			GatewayList()
		}

		Reduce(core)
			.ifLet(\.$removeGatewayAlert, action: /Action.view .. ViewAction.removeGateway)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadGateways(&state)

		case let .removeGateway(.presented(action)):
			switch action {
			case let .removeButtonTapped(gateway):
				guard let currentGateway = state.currentGateway else { return .none }

				switch gateway.gateway {
				case currentGateway:
					guard let firstPredefined = state.gatewayList.gateways.first(where: { !$0.canBeDeleted })?.gateway else {
						return .none
					}

					state.gatewayForRemoval = gateway.gateway
					return switchToGateway(&state, gateway: firstPredefined)

				default:
					return removeGateway(gateway.gateway)
						.concatenate(with: loadGateways(&state, needsDelay: true))
				}

			case .cancelButtonTapped:
				return .none
			}

		case .addGatewayButtonTapped:
			state.destination = .addNewGateway(AddNewGateway.State())
			return .none

		case .popoverButtonTapped:
			state.isPopoverPresented = true
			return .none

		case let .popoverStateChanged(value):
			state.isPopoverPresented = value
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .presentGateways(all: gateways, current: current):
			state.currentGateway = current
			state.gatewayList = .init(gateways: .init(
				uniqueElements: gateways.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: current.id == $0.id,
						canBeDeleted: $0.id != Gateway.nebunet.id
					)
				}
				.sorted(by: { !$0.canBeDeleted && $1.canBeDeleted })
			))
			return .none

		case let .hasAccountsResult(.success(hasAccountsOnNetwork)):
			guard let newGateway = state.validatedNewGatewayToSwitchTo else {
				// weird state, should not happen
				return .none
			}
			return .task {
				if hasAccountsOnNetwork {
					let result = await TaskResult {
						try await networkSwitchingClient.switchTo(newGateway)
					}
					return .internal(.switchToGatewayResult(result))
				} else {
					return .internal(.createAccountOnNetworkBeforeSwitchingToIt(newGateway))
				}
			}

		case let .hasAccountsResult(.failure(error)):
			errorQueue.schedule(error)
			return skipSwitching(&state)

		case let .createAccountOnNetworkBeforeSwitchingToIt(gateway):
			state.destination = .createAccount(
				.init(config: .init(
					purpose: .firstAccountOnNewNetwork(gateway.network.id)
				))
			)
			return .none

		case let .switchToGatewayResult(.success(gateway)):
			state.gatewayList.gateways.forEach {
				state.gatewayList.gateways[id: $0.id]?.isSelected = $0.id == gateway.id
			}

			if let gatewayForRemoval = state.gatewayForRemoval {
				state.gatewayForRemoval = nil
				return .run { send in
					await send(.internal(.removeGateway(gatewayForRemoval)))
					await send(.delegate(.networkChanged))
				}
			} else {
				return .send(.delegate(.networkChanged))
			}

		case let .switchToGatewayResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .removeGateway(gateway):
			return .fireAndForget {
				try await gatewaysClient.removeGateway(gateway)
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .gatewayList(.delegate(action)):
			switch action {
			case let .removeGateway(gateway):
				state.removeGatewayAlert = .init(
					title: { TextState(L10n.GatewaySettings.RemoveGatewayAlert.title) },
					actions: {
						ButtonState(role: .cancel, action: .cancelButtonTapped) {
							TextState(L10n.GatewaySettings.RemoveGatewayAlert.cancelButtonTitle)
						}
						ButtonState(action: .removeButtonTapped(gateway)) {
							TextState(L10n.GatewaySettings.RemoveGatewayAlert.removeButtonTitle)
						}
					},
					message: { TextState(L10n.GatewaySettings.RemoveGatewayAlert.message) }
				)
				return .none

			case let .switchToGateway(gateway):
				return switchToGateway(&state, gateway: gateway)
			}

		case .destination(.presented(.addNewGateway(.delegate(.dismiss)))):
			state.destination = nil
			return loadGateways(&state)

		case .destination(.presented(.createAccount(.delegate(.dismiss)))):
			return skipSwitching(&state)

		case .destination(.presented(.createAccount(.delegate(.completed)))):
			state.destination = nil
			guard let newGateway = state.validatedNewGatewayToSwitchTo else {
				// weird state, should not happen
				return .none
			}
			return .task {
				let result = await TaskResult {
					try await networkSwitchingClient.switchTo(newGateway)
				}
				return .internal(.switchToGatewayResult(result))
			}

		default:
			return .none
		}
	}
}

private extension GatewaySettings {
	func loadGateways(_ state: inout State, needsDelay: Bool = false) -> EffectTask<Action> {
		.run { send in
			if needsDelay {
				try await clock.sleep(for: .seconds(0.1))
			}
			let gateways = await gatewaysClient.getAllGateways()
			let current = await gatewaysClient.getCurrentGateway()
			await send(.internal(.presentGateways(
				all: gateways.rawValue.elements,
				current: current
			)))
		}
	}

	func skipSwitching(_ state: inout State) -> EffectTask<Action> {
		state.destination = nil
		state.validatedNewGatewayToSwitchTo = nil
		return .none
	}

	func switchToGateway(_ state: inout State, gateway: Gateway) -> EffectTask<Action> {
		guard
			let current = state.currentGateway,
			current.id != gateway.id
		else {
			return .none
		}

		state.validatedNewGatewayToSwitchTo = gateway
		return .task {
			let result = await TaskResult {
				try await networkSwitchingClient.hasAccountOnNetwork(gateway)
			}
			return .internal(.hasAccountsResult(result))
		}
	}

	func removeGateway(_ gateway: Gateway) -> EffectTask<Action> {
		.run { send in
			await send(.internal(.removeGateway(gateway)))
		}
	}
}

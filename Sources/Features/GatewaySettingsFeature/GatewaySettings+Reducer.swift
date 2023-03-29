import CreateEntityFeature
import FeaturePrelude
import GatewaysClient
import NetworkSwitchingClient

// MARK: - GatewaySettings
public struct GatewaySettings: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var gatewayList: GatewayList.State
		var currentGateway: Radix.Gateway?
		var validatedNewGatewayToSwitchTo: Radix.Gateway?
		var gatewayForRemoval: Radix.Gateway?

		@PresentationState var removeGatewayAlert: AlertState<ViewAction.RemoveGatewayAction>?
		@PresentationState var destination: Destinations.State?

		public init(
			gatewayList: GatewayList.State = .init(gateways: [])
		) {
			self.gatewayList = gatewayList
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case removeGateway(PresentationAction<RemoveGatewayAction>)
		case addGatewayButtonTapped
		case popoverButtonTapped

		public enum RemoveGatewayAction: Sendable, Hashable {
			case removeButtonTapped(GatewayRow.State)
			case cancelButtonTapped
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case gatewaysLoadedResult(TaskResult<Gateways>)
		case hasAccountsResult(TaskResult<Bool>)
		case createAccountOnNetworkBeforeSwitchingToIt(Radix.Gateway)
		case switchToGatewayResult(TaskResult<Radix.Gateway>)
	}

	public enum ChildAction: Sendable, Equatable {
		case gatewayList(GatewayList.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewGateway(AddNewGateway.State)
			case createAccount(CreateAccountCoordinator.State)
			case slideUpPanel(SlideUpPanel.State)
		}

		public enum Action: Sendable, Equatable {
			case addNewGateway(AddNewGateway.Action)
			case createAccount(CreateAccountCoordinator.Action)
			case slideUpPanel(SlideUpPanel.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewGateway, action: /Action.addNewGateway) {
				AddNewGateway()
			}

			Scope(state: /State.createAccount, action: /Action.createAccount) {
				CreateAccountCoordinator()
			}

			Scope(state: /State.slideUpPanel, action: /Action.slideUpPanel) {
				SlideUpPanel()
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
		case .task:
			return .run { send in
				for try await gateways in await gatewaysClient.gatewaysValues() {
					guard !Task.isCancelled else { return }
					await send(.internal(.gatewaysLoadedResult(.success(gateways))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

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
					return .run { _ in
						try await gatewaysClient.removeGateway(gateway.gateway)
					}
				}

			case .cancelButtonTapped:
				return .none
			}

		case .addGatewayButtonTapped:
			state.destination = .addNewGateway(AddNewGateway.State())
			return .none

		case .popoverButtonTapped:
			state.destination = .slideUpPanel(
				.init(
					title: L10n.GatewaySettings.WhatIsAGateway.title,
					explanation: L10n.GatewaySettings.WhatIsAGateway.explanation
				)
			)
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .gatewaysLoadedResult(.success(gateways)):
			state.currentGateway = gateways.current
			state.gatewayList = .init(gateways: .init(
				uniqueElements: gateways.all.elements.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: gateways.current.id == $0.id,
						canBeDeleted: !$0.isDefault
					)
				}
				.sorted(by: { !$0.canBeDeleted && $1.canBeDeleted })
			))
			return .none

		case let .gatewaysLoadedResult(.failure(error)):
			errorQueue.schedule(error)
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
				), displayIntroduction: { _ in
					false
				})
			)
			return .none

		case let .switchToGatewayResult(.success(gateway)):
			state.currentGateway = gateway
			state.gatewayList.gateways.forEach {
				state.gatewayList.gateways[id: $0.id]?.isSelected = $0.id == gateway.id
			}

			if let gatewayForRemoval = state.gatewayForRemoval {
				state.gatewayForRemoval = nil
				return .run { _ in
					try await gatewaysClient.removeGateway(gatewayForRemoval)
				}
			} else {
				return .none
			}

		case let .switchToGatewayResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
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
			return .none

		case .destination(.presented(.createAccount(.delegate(.dismissed)))):
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

		case .destination(.presented(.slideUpPanel(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}

private extension GatewaySettings {
	func skipSwitching(_ state: inout State) -> EffectTask<Action> {
		state.destination = nil
		state.validatedNewGatewayToSwitchTo = nil
		return .none
	}

	func switchToGateway(_ state: inout State, gateway: Radix.Gateway) -> EffectTask<Action> {
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
}

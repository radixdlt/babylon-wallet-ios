import CreateAccountFeature
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

	public struct Destinations: Sendable, Reducer {
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

		public var body: some ReducerOf<Self> {
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

	public var body: some ReducerOf<Self> {
		Scope(state: \.gatewayList, action: /Action.child .. ChildAction.gatewayList) {
			GatewayList()
		}

		Reduce(core)
			.ifLet(\.$removeGatewayAlert, action: /Action.view .. ViewAction.removeGateway)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
			case let .removeButtonTapped(gatewayState):
				guard gatewayState.gateway != .mainnet else {
					assertionFailure("Incorrect implementation, should be impossible to remove mainnet.")
					return .none
				}
				guard let currentGateway = state.currentGateway else { return .none }

				switch gatewayState.gateway {
				case currentGateway:

					// FIXME: Mainnet simply once mainnet is online....
					let containsMainnet = state.gatewayList.gateways.map(\.gateway).contains(.mainnet)
					let newCurrent: Radix.Gateway? = {
						if containsMainnet {
							return Radix.Gateway.mainnet
						} else {
							return Radix.Gateway.default
						}
					}()

					guard let newCurrent else {
						return .none
					}

					state.gatewayForRemoval = gatewayState.gateway
					return switchToGateway(&state, gateway: newCurrent)

				default:
					return .run { _ in
						try await gatewaysClient.removeGateway(gatewayState.gateway)
					}
				}

			case .cancelButtonTapped:
				return .none
			}

		case .addGatewayButtonTapped:
			state.destination = .addNewGateway(AddNewGateway.State())
			return .none

		case .popoverButtonTapped:
//			state.destination = .slideUpPanel(
//				.init(
//					title: L10n.Gateways.WhatIsAGateway.title,
//					explanation: L10n.Gateways.WhatIsAGateway.explanation
//				)
//			)
			// FIXME: display what is a gateway once we have copy
			loggerGlobal.warning("What is A gateway tutorial slide up panel skipped, since no copy.")
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .gatewaysLoadedResult(.success(gateways)):
			let containsMainnet = gateways.all.contains(Radix.Gateway.mainnet)
			func canBeDeleted(_ gateway: Radix.Gateway) -> Bool {
				guard gateways.all.count > 1 else {
					return false
				}
				if containsMainnet {
					return gateway != .mainnet
				} else {
					return gateway != .default
				}
			}
			state.currentGateway = gateways.current
			state.gatewayList = .init(gateways: .init(
				uniqueElements: gateways.all.elements.map {
					GatewayRow.State(
						gateway: $0,
						isSelected: gateways.current.id == $0.id,
						canBeDeleted: canBeDeleted($0)
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
			return .run { send in
				if hasAccountsOnNetwork {
					let result = await TaskResult {
						try await networkSwitchingClient.switchTo(newGateway)
					}
					await send(.internal(.switchToGatewayResult(result)))
				} else {
					await send(.internal(.createAccountOnNetworkBeforeSwitchingToIt(newGateway)))
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .gatewayList(.delegate(action)):
			switch action {
			case let .removeGateway(gateway):
				state.removeGatewayAlert = .removeGateway(row: gateway)
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
			return .run { send in
				let result = await TaskResult {
					try await networkSwitchingClient.switchTo(newGateway)
				}
				await send(.internal(.switchToGatewayResult(result)))
			}

		case .destination(.presented(.slideUpPanel(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}

extension AlertState<GatewaySettings.ViewAction.RemoveGatewayAction> {
	// FIXME: This should probably take an ID and not GatewayRow.State
	static func removeGateway(row: GatewayRow.State) -> AlertState {
		AlertState {
			TextState(L10n.Gateways.RemoveGatewayAlert.title)
		} actions: {
			ButtonState(role: .cancel, action: .cancelButtonTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .removeButtonTapped(row)) {
				TextState(L10n.Common.remove)
			}
		} message: {
			TextState(L10n.Gateways.RemoveGatewayAlert.message)
		}
	}
}

private extension GatewaySettings {
	func skipSwitching(_ state: inout State) -> Effect<Action> {
		state.destination = nil
		state.validatedNewGatewayToSwitchTo = nil
		return .none
	}

	func switchToGateway(_ state: inout State, gateway: Radix.Gateway) -> Effect<Action> {
		guard
			let current = state.currentGateway,
			current.id != gateway.id
		else {
			return .none
		}

		state.validatedNewGatewayToSwitchTo = gateway
		return .run { send in
			let result = await TaskResult {
				try await networkSwitchingClient.hasAccountOnNetwork(gateway)
			}
			await send(.internal(.hasAccountsResult(result)))
		}
	}
}

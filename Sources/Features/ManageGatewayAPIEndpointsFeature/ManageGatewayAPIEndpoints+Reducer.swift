import ComposableArchitecture
import CreateAccountFeature
import ErrorQueue
import Foundation
import GatewayAPI
import ProfileClient
import UserDefaultsClient

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.networkSwitchingClient) var networkSwitchingClient
	@Dependency(\.profileClient) var profileClient

	public init() {}
}

public extension ManageGatewayAPIEndpoints {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.createAccount, action: /Action.createAccount) {
				CreateAccount()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.didAppear)):
			return .run { send in
				await send(.internal(.system(.loadNetworkAndGatewayResult(
					TaskResult {
						await networkSwitchingClient.getNetworkAndGateway()
					}
				))))
			}

		case let .internal(.system(.loadNetworkAndGatewayResult(.success(currentNetworkAndGateway)))):
			state.currentNetworkAndGateway = currentNetworkAndGateway
			let url = currentNetworkAndGateway.gatewayAPIEndpointURL
			state.url = url
			state.urlString = url.absoluteString
			return .none

		case let .internal(.system(.loadNetworkAndGatewayResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case let .internal(.view(.urlStringChanged(urlString))):
			state.urlString = urlString
			state.url = URL(string: urlString)
			return .none

		case .internal(.view(.switchToButtonTapped)):
			guard let url = state.url else {
				return .none
			}
			state.isValidatingEndpoint = true
			return .run { send in
				await send(.internal(.system(.gatewayValidationResult(
					TaskResult {
						try await networkSwitchingClient.validateGatewayURL(url)
					}
				))))
			}

		case let .internal(.system(.gatewayValidationResult(.failure(error)))):
			state.isValidatingEndpoint = false
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.gatewayValidationResult(.success(maybeNew)))):
			state.isValidatingEndpoint = false
			guard let new = maybeNew else {
				return .none
			}
			state.validatedNewNetworkAndGatewayToSwitchTo = new
			return .run { send in
				await send(.internal(.system(.hasAccountsResult(
					TaskResult {
						try await networkSwitchingClient.hasAccountOnNetwork(new)
					}
				))))
			}
		case let .internal(.system(.hasAccountsResult(.success(hasAccountsOnNetwork)))):
			guard let new = state.validatedNewNetworkAndGatewayToSwitchTo else {
				fatalError()
				// weird state... should not happen.
				return .none
			}
			return .run { send in
				if hasAccountsOnNetwork {
					await send(.internal(.system(.switchToResult(
						TaskResult {
							try await networkSwitchingClient.switchTo(new)
						}
					))))
				} else {
					await send(.internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(new))))
				}
			}

		case let .internal(.system(.hasAccountsResult(.failure(error)))):
			errorQueue.schedule(error)
			state.validatedNewNetworkAndGatewayToSwitchTo = nil
			return .none

		case let .internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(newNetwork))):
			state.createAccount = CreateAccount.State(
				onNetworkWithID: newNetwork.network.id,
				shouldCreateProfile: false,
				numberOfExistingAccounts: 0
			)
			return .none

		case let .internal(.system(.switchToResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.switchToResult(.success(_)))):
			return .run { send in
				await send(.delegate(.networkChanged))
			}

		case .createAccount(.delegate(.dismissCreateAccount)):
			state.createAccount = nil
			state.validatedNewNetworkAndGatewayToSwitchTo = nil
			return .none

		case let .createAccount(.delegate(.createdNewAccount(_))):
			state.createAccount = nil
			guard let new = state.validatedNewNetworkAndGatewayToSwitchTo else {
				fatalError()
				// weird state... should not happen.
				return .none
			}
			return .run { send in
				await send(.internal(.system(.switchToResult(
					TaskResult {
						try await networkSwitchingClient.switchTo(new)
					}
				))))
			}

		case .createAccount(.delegate(.failedToCreateNewAccount)):
			state.createAccount = nil
			state.validatedNewNetworkAndGatewayToSwitchTo = nil
			return .none

		case .createAccount:
			return .none

		case .delegate:
			return .none
		}
	}
}

// MARK: - NetworkSwitchingClient
public struct NetworkSwitchingClient: Sendable, DependencyKey {
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var validateGatewayURL: ValidateGatewayURL
	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var switchTo: SwitchTo
}

public extension DependencyValues {
	var networkSwitchingClient: NetworkSwitchingClient {
		get { self[NetworkSwitchingClient.self] }
		set { self[NetworkSwitchingClient.self] = newValue }
	}
}

public extension NetworkSwitchingClient {
	typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway
	typealias ValidateGatewayURL = @Sendable (URL) async throws -> AppPreferences.NetworkAndGateway?
	typealias HasAccountOnNetwork = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Bool
	typealias SwitchTo = @Sendable (AppPreferences.NetworkAndGateway) async throws -> AppPreferences.NetworkAndGateway

	static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.profileClient) var profileClient

		let getNetworkAndGateway: GetNetworkAndGateway = {
			await profileClient.getNetworkAndGateway()
		}

		let validateGatewayURL: ValidateGatewayURL = { newURL -> AppPreferences.NetworkAndGateway? in
			let currentURL = await getNetworkAndGateway().gatewayAPIEndpointURL
			print("Current: \(currentURL.absoluteString)")
			print("newURL: \(newURL.absoluteString)")
			guard newURL != currentURL else {
				return nil
			}
			let name = try await gatewayAPIClient.getNameOfNetwork(newURL)
			// FIXME: mainnet: also compare `NetworkID` from lookup with NetworkID from `getNetworkInformation` call
			// once it returns networkID!
			let network = try Network.lookupBy(name: name)

			let networkAndGateway = AppPreferences.NetworkAndGateway(
				network: network,
				gatewayAPIEndpointURL: newURL
			)

			return networkAndGateway
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { networkAndGateway in
			try await profileClient.hasAccountOnNetwork(networkAndGateway.network.id)
		}

		let switchTo: SwitchTo = { networkAndGateway in
			guard try await hasAccountOnNetwork(networkAndGateway) else {
				throw NoAccountOnNetwork()
			}

			try await profileClient.setNetworkAndGateway(networkAndGateway)
			return networkAndGateway
		}

		return Self(
			getNetworkAndGateway: getNetworkAndGateway,
			validateGatewayURL: validateGatewayURL,
			hasAccountOnNetwork: hasAccountOnNetwork,
			switchTo: switchTo
		)
	}()
}

// MARK: - NoAccountOnNetwork
struct NoAccountOnNetwork: Swift.Error {}

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

	public init() {}
}

public extension ManageGatewayAPIEndpoints {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
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
				let hasAccountOnNetwork = await networkSwitchingClient.hasAccountOnNetwork(new)
				if hasAccountOnNetwork {
					await send(.internal(.system(.switchToResult(
						TaskResult {
							try await networkSwitchingClient.switchTo(new)
						}
					))))
				} else {
					await send(.internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(new))))
				}
			}

		case let .internal(.system(.createAccountOnNetworkBeforeSwitchingToIt(newNetwork))):
			//            state.createAccount = CreateAccount.State
			fatalError()

		case let .internal(.system(.switchToResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.switchToResult(.success(onNetwork)))):
			return .run { send in
				await send(.delegate(.networkChanged(onNetwork)))
			}

		case .createAccount:
			fatalError()

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
	typealias ValidateGatewayURL = @Sendable (URL) async throws -> AppPreferences.NetworkAndGateway
	typealias HasAccountOnNetwork = @Sendable (AppPreferences.NetworkAndGateway) async -> Bool
	typealias SwitchTo = @Sendable (AppPreferences.NetworkAndGateway) async throws -> OnNetwork

	static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.profileClient) var profileClient

		let getNetworkAndGateway: GetNetworkAndGateway = {
			await profileClient.getNetworkAndGateway()
		}

		let validateGatewayURL: ValidateGatewayURL = { _ in
			fatalError()
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { _ in
			false
		}

		let switchTo: SwitchTo = { url in
			guard await hasAccountOnNetwork(url) else {
				throw NoAccountOnNetwork()
			}
			fatalError()
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

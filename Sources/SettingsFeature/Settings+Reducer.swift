import ComposableArchitecture
import GatewayAPI
import Profile
import ProfileClient

// MARK: - Settings
public struct Settings: ReducerProtocol {
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	public init() {}
}

public extension Settings {
	func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
		switch action {
		case .internal(.system(.viewDidAppear)):
			return .run { send in
				await send(.internal(.system(.loadRDXLedgerEpoch)))
			}

		case .internal(.system(.loadRDXLedgerEpoch)):
			return .run { [gatewayAPIClient] send in
				await send(.internal(.system(.fetchEpochResult(TaskResult {
					try await gatewayAPIClient.getEpoch()
				}))))
			}

		case let .internal(.system(.fetchEpochResult(.success(epoch)))):
			state.currentEpoch = epoch
			return .none

		case let .internal(.system(.fetchEpochResult(.failure(error)))):
			print("Failed to fetch epoch: \(String(describing: error))")
			return .none

		case .internal(.user(.dismissSettings)):
			return .run { send in
				await send(.coordinate(.dismissSettings))
			}

		case .internal(.user(.deleteProfileAndFactorSources)):
			return .run { send in
				await send(.coordinate(.deleteProfileAndFactorSources))
			}

		#if DEBUG
		case .internal(.user(.debugInspectProfile)):

			return .run { [profileClient] send in
				guard
					let snapshot = try? profileClient.extractProfileSnapshot(),
					let profile = try? Profile(snapshot: snapshot)
				else {
					return
				}
				await send(.internal(.system(.profileToDebugLoaded(profile))))
			}
		case let .internal(.system(.profileToDebugLoaded(profile))):
			state.profileToInspect = profile
			return .none

		case let .internal(.user(.setDebugProfileSheet(isPresented))):
			precondition(!isPresented)
			state.profileToInspect = nil
			return .none
		#endif // DEBUG

		case .coordinate:
			return .none
		}
	}
}

import ComposableArchitecture
import Sargon

// MARK: - SignalingServersSettings
struct SignalingServersSettings: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		var current: P2PTransportProfile? = nil
		var others: [P2PTransportProfile] = []

		@Presents
		var destination: Destination.State?
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Equatable {
		case task
		case addProfileButtonTapped
		case rowTapped(String)
	}

	enum InternalAction: Equatable {
		case profilesLoaded(TaskResult<SavedP2PTransportProfiles>)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case details(SignalingServerDetails.State)
		}

		@CasePathable
		enum Action: Equatable {
			case details(SignalingServerDetails.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.details, action: \.details) {
				SignalingServerDetails()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pTransportProfilesClient) var p2pTransportProfilesClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let result = await TaskResult {
					try await p2pTransportProfilesClient.getProfiles()
				}
				await send(.internal(.profilesLoaded(result)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .addProfileButtonTapped:
			state.destination = .details(.create)
			return .none

		case let .rowTapped(id):
			guard state.current?.signalingServer == id || state.others.contains(where: { $0.signalingServer == id }) else {
				return .none
			}
			state.destination = .details(.edit(id: id))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .profilesLoaded(.success(profiles)):
			let current = profiles.current
			let others = profiles.all.filter { $0.signalingServer != profiles.current.signalingServer }

			guard state.current != current || state.others != others else {
				return .none
			}

			state.current = current
			state.others = others
			return .none

		case let .profilesLoaded(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .details(.delegate(.updated)):
			.send(.view(.task))

		default:
			.none
		}
	}
}

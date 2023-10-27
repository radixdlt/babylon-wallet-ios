// MARK: - AccountAndPersonaHiding
public struct AccountAndPersonaHiding: FeatureReducer {
	public struct State: Hashable, Sendable {
		public var hiddenEntitiesStats: EntitiesVisibilityClient.HiddenEntitiesStats?

		@PresentationState
		public var confirmUnhideAllAlert: AlertState<ViewAction.ConfirmUnhideAllAlert>?
	}

	public enum ViewAction: Hashable, Sendable {
		case task
		case unhideAllTapped

		case confirmUnhideAllAlert(PresentationAction<ConfirmUnhideAllAlert>)

		public enum ConfirmUnhideAllAlert: Hashable, Sendable {
			case confirmTapped
			case cancelTapped
		}
	}

	public enum InternalAction: Hashable, Sendable {
		case hiddenEntitesStatsLoaded(EntitiesVisibilityClient.HiddenEntitiesStats)
		case didUnhideAllEntities
	}

	@Dependency(\.entitiesVisibilityClient) var entitiesVisibilityClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.errorQueue) var errorQueue

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let hiddenEntitiesStats = try await entitiesVisibilityClient.getHiddenEntitiesStats()
				await send(.internal(.hiddenEntitesStatsLoaded(hiddenEntitiesStats)))
			}
		case .unhideAllTapped:
			state.confirmUnhideAllAlert = .init(
				title: .init(L10n.AppSettings.EntityHiding.unhideAllSection),
				message: .init(L10n.AppSettings.EntityHiding.unhideAllConfirmation),
				buttons: [
					.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
					.default(.init(L10n.Common.continue), action: .send(.confirmTapped)),
				]
			)
			return .none

		case let .confirmUnhideAllAlert(action):
			defer {
				state.confirmUnhideAllAlert = nil
			}

			switch action {
			case .presented(.confirmTapped):
				return .run { send in
					try await entitiesVisibilityClient.unhideAllEntities()
					overlayWindowClient.scheduleHUD(.updated)
					await send(.internal(.didUnhideAllEntities))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			case .presented(.cancelTapped):
				return .none
			case .dismiss:
				return .none
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .hiddenEntitesStatsLoaded(stats):
			state.hiddenEntitiesStats = stats
			return .none
		case .didUnhideAllEntities:
			state.hiddenEntitiesStats = .init(hiddenAccountsCount: 0, hiddenPersonasCount: 0)
			return .none
		}
	}
}

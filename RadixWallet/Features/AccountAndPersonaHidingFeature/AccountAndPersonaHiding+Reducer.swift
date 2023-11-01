// MARK: - AccountAndPersonaHiding
public struct AccountAndPersonaHiding: FeatureReducer {
	public struct State: Hashable, Sendable {
		public var hiddenEntityCounts: EntitiesVisibilityClient.HiddenEntityCounts?

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
		case hiddenEntityCountsLoaded(EntitiesVisibilityClient.HiddenEntityCounts)
		case didUnhideAllEntities
	}

	@Dependency(\.entitiesVisibilityClient) var entitiesVisibilityClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.errorQueue) var errorQueue

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let counts = try await entitiesVisibilityClient.getHiddenEntityCounts()
				await send(.internal(.hiddenEntityCountsLoaded(counts)))
			}
		case .unhideAllTapped:
			state.confirmUnhideAllAlert = .init(
				title: .init(L10n.AppSettings.EntityHiding.unhideAllSection),
				message: .init(L10n.AppSettings.EntityHiding.unhideAllConfirmation),
				buttons: [
					.default(.init(L10n.Common.continue), action: .send(.confirmTapped)),
					.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
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
					overlayWindowClient.scheduleHUD(.updatedAccount)
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
		case let .hiddenEntityCountsLoaded(counts):
			state.hiddenEntityCounts = counts
			return .none
		case .didUnhideAllEntities:
			state.hiddenEntityCounts = .init(hiddenAccountsCount: 0, hiddenPersonasCount: 0)
			return .none
		}
	}
}

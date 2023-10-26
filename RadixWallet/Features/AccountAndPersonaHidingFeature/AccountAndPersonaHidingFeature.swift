import Foundation

// MARK: - AccountAndPersonaHiding
public struct AccountAndPersonaHiding: FeatureReducer {
	@Dependency(\.entitiesVisibilityClient) var entitiesVisibilityClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

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

		case .confirmUnhideAllAlert(.presented(.confirmTapped)):
			return .run { send in
				try await entitiesVisibilityClient.unhideAllEntities()
				overlayWindowClient.scheduleHUD(.updated)
				await send(.internal(.didUnhideAllEntities))
			}
		case .confirmUnhideAllAlert:
			return .none
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

extension AccountAndPersonaHiding.State {
	var viewState: AccountAndPersonaHiding.ViewState {
		.init(
			hiddenAccountsCount: hiddenEntitiesStats?.hiddenAccountsCount ?? 0,
			hiddenPersonasCount: hiddenEntitiesStats?.hiddenPersonasCount ?? 0
		)
	}
}

extension AccountAndPersonaHiding {
	public struct ViewState: Equatable {
		public let hiddenAccountsCount: Int
		public let hiddenPersonasCount: Int

		public var hiddenAccountsText: String {
			if hiddenAccountsCount == 1 {
				L10n.AppSettings.EntityHiding.hiddenAccount(1)
			} else {
				L10n.AppSettings.EntityHiding.hiddenAccounts(hiddenAccountsCount)
			}
		}

		public var hiddenPersonasText: String {
			if hiddenPersonasCount == 1 {
				L10n.AppSettings.EntityHiding.hiddenPersona(1)
			} else {
				L10n.AppSettings.EntityHiding.hiddenPersonas(hiddenPersonasCount)
			}
		}

		public var unhideAllButtonControlState: ControlState {
			if hiddenAccountsCount > 0 || hiddenPersonasCount > 0 {
				.enabled
			} else {
				.disabled
			}
		}
	}

	public struct View: SwiftUI.View {
		public let store: StoreOf<AccountAndPersonaHiding>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				List {
					Section {
						VStack(alignment: .leading, spacing: .zero) {
							Text(viewStore.hiddenAccountsText)
							Text(viewStore.hiddenPersonasText)
						}
						.foregroundColor(.app.gray2)
						.textStyle(.body1Header)
						.listRowSeparator(.hidden)
						.listRowBackground(Color.clear)
						.centered
					} header: {
						Text(L10n.AppSettings.EntityHiding.info)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Regular)
							.textCase(nil)
					}

					Section {
						Button(L10n.AppSettings.EntityHiding.unhideAllButton) {
							viewStore.send(.view(.unhideAllTapped))
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
						.controlState(viewStore.unhideAllButtonControlState)
					} header: {
						Text(L10n.AppSettings.EntityHiding.unhideAllSection)
							.foregroundColor(.app.gray2)
							.textStyle(.body1HighImportance)
							.textCase(nil)
					}
				}
				.listStyle(.grouped)
				.background(.app.background)
				.task { @MainActor in
					await viewStore.send(.view(.task)).finish()
				}
				.alert(
					store: store.scope(
						state: \.$confirmUnhideAllAlert,
						action: { .view(.confirmUnhideAllAlert($0)) }
					)
				)
			}
			.navigationTitle(L10n.AppSettings.EntityHiding.title)
			.toolbarBackground(.app.background, for: .navigationBar)
			.toolbarBackground(.visible, for: .navigationBar)
		}
	}
}

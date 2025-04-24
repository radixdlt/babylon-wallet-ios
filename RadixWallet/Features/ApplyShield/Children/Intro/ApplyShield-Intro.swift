extension ApplyShield {
	@Reducer
	struct Intro: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let shieldID: SecurityStructureId
			var shieldName: DisplayName?
			var hasEnoughXRD: Loadable<Bool> = .idle
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case onFirstAppear
			case startApplyingButtonTapped
			case skipButtonTapped
		}

		enum InternalAction: Sendable, Equatable {
			case setShieldName(DisplayName)
			case setHasEnoughXRD(Bool)
		}

		enum DelegateAction: Sendable, Equatable {
			case started
			case skipped
		}

		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.errorQueue) var errorQueue

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .onFirstAppear:
				setShieldNameEffect(shieldID: state.shieldID)
					.merge(with: checkXRDBalanceEffect(state: &state))
			case .startApplyingButtonTapped:
				.send(.delegate(.started))
			case .skipButtonTapped:
				.send(.delegate(.skipped))
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .setShieldName(name):
				state.shieldName = name
				return .none
			case let .setHasEnoughXRD(hasEnoughXRD):
				state.hasEnoughXRD = .success(hasEnoughXRD)
				return .none
			}
		}

		private func setShieldNameEffect(shieldID: SecurityStructureId) -> Effect<Action> {
			.run { send in
				let shield = try SargonOs.shared.securityStructureOfFactorSourceIdsBySecurityStructureId(shieldId: shieldID)
				await send(.internal(.setShieldName(shield.metadata.displayName)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}

		// TODO: replace this whole function with a call to Sargon
		private func checkXRDBalanceEffect(state: inout State) -> Effect<Action> {
			state.hasEnoughXRD = .loading
			return .run { send in
				let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
				let entities = try await onLedgerEntitiesClient.getAccounts(accounts.map(\.address), cachingStrategy: .forceUpdate)
				let hasEnoughXRD = entities.contains { entity in
					let xrdBalance = entity.fungibleResources.xrdResource?.amount.exactAmount?.nominalAmount ?? 0
					let hasEnoughXRD = xrdBalance >= 10 // TODO: define a constant in Sargon
					return hasEnoughXRD
				}

				await send(.internal(.setHasEnoughXRD(hasEnoughXRD)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}
}

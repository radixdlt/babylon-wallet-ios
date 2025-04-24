// MARK: - InteractionReview.Sections
extension InteractionReview {
	struct Sections: Sendable, FeatureReducer {
		typealias Common = InteractionReview

		struct State: Sendable, Hashable {
			let kind: InteractionReview.Kind

			var withdrawals: Accounts.State? = nil
			var dAppsUsed: InteractionReviewDappsUsed.State? = nil
			var deposits: Accounts.State? = nil
			var accountDeletion: Accounts.State? = nil

			var contributingToPools: InteractionReviewPools.State? = nil
			var redeemingFromPools: InteractionReviewPools.State? = nil

			var stakingToValidators: InteractionReview.ValidatorsState? = nil
			var unstakingFromValidators: InteractionReview.ValidatorsState? = nil
			var claimingFromValidators: InteractionReview.ValidatorsState? = nil

			var accountDepositSetting: InteractionReview.DepositSettingState? = nil
			var accountDepositExceptions: InteractionReview.DepositExceptionsState? = nil

			// The proofs are set here (within the resolve logic) but may be rendered and handled by the parent view, in the case they are placed outside the Sections (TransactionReview).
			var proofs: Proofs.State? = nil

			@PresentationState
			var destination: Destination.State? = nil
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case appeared
			case expandableItemToggled(ExpandableItem)

			enum ExpandableItem: Sendable, Equatable {
				case dAppsUsed, contributingToPools, redeemingFromPools, stakingToValidators, unstakingFromValidators, claimingFromValidators
			}
		}

		enum InternalAction: Sendable, Equatable {
			case parent(ParentAction)
			case setSections(Common.SectionsData?)

			enum ParentAction: Sendable, Equatable {
				case resolveExecutionSummary(ExecutionSummary, NetworkID)
				case resolveManifestSummary(ManifestSummary, NetworkID)
				case showResourceDetails(OnLedgerEntity.Resource, KnownResourceBalance.Details)
			}
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case withdrawals(Common.Accounts.Action)
			case deposits(Common.Accounts.Action)
			case accountDeletion(Common.Accounts.Action)
			case dAppsUsed(InteractionReviewDappsUsed.Action)
			case contributingToPools(InteractionReviewPools.Action)
			case redeemingFromPools(InteractionReviewPools.Action)
			case proofs(Common.Proofs.Action)
		}

		enum DelegateAction: Sendable, Hashable {
			case failedToResolveSections
			case showCustomizeGuarantees([TransactionReviewGuarantee.State])
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case dApp(DappDetails.State)
				case fungibleTokenDetails(FungibleTokenDetails.State)
				case nonFungibleTokenDetails(NonFungibleTokenDetails.State)
				case poolUnitDetails(PoolUnitDetails.State)
				case lsuDetails(LSUDetails.State)
				case unknownDappComponents(Common.UnknownDappComponents.State)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case dApp(DappDetails.Action)
				case fungibleTokenDetails(FungibleTokenDetails.Action)
				case nonFungibleTokenDetails(NonFungibleTokenDetails.Action)
				case lsuDetails(LSUDetails.Action)
				case poolUnitDetails(PoolUnitDetails.Action)
				case unknownDappComponents(Common.UnknownDappComponents.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.dApp, action: \.dApp) {
					DappDetails()
				}
				Scope(state: \.fungibleTokenDetails, action: \.fungibleTokenDetails) {
					FungibleTokenDetails()
				}
				Scope(state: \.nonFungibleTokenDetails, action: \.nonFungibleTokenDetails) {
					NonFungibleTokenDetails()
				}
				Scope(state: \.poolUnitDetails, action: \.poolUnitDetails) {
					PoolUnitDetails()
				}
				Scope(state: \.lsuDetails, action: \.lsuDetails) {
					LSUDetails()
				}
				Scope(state: \.unknownDappComponents, action: \.unknownDappComponents) {
					Common.UnknownDappComponents()
				}
			}
		}

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.personasClient) var personasClient
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		var body: some ReducerOf<Self> {
			Reduce(core)
				.ifLet(\.withdrawals, action: \.child.withdrawals) {
					Common.Accounts()
				}
				.ifLet(\.deposits, action: \.child.deposits) {
					Common.Accounts()
				}
				.ifLet(\.dAppsUsed, action: \.child.dAppsUsed) {
					InteractionReviewDappsUsed()
				}
				.ifLet(\.contributingToPools, action: \.child.contributingToPools) {
					InteractionReviewPools()
				}
				.ifLet(\.redeemingFromPools, action: \.child.redeemingFromPools) {
					InteractionReviewPools()
				}
				.ifLet(\.proofs, action: \.child.proofs) {
					Common.Proofs()
				}
				.ifLet(destinationPath, action: /Action.destination) {
					Destination()
				}
		}

		private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .appeared:
				return .none

			case let .expandableItemToggled(item):
				switch item {
				case .dAppsUsed:
					state.dAppsUsed?.isExpanded.toggle()
				case .contributingToPools:
					state.contributingToPools?.isExpanded.toggle()
				case .redeemingFromPools:
					state.redeemingFromPools?.isExpanded.toggle()
				case .stakingToValidators:
					state.stakingToValidators?.isExpanded.toggle()
				case .unstakingFromValidators:
					state.unstakingFromValidators?.isExpanded.toggle()
				case .claimingFromValidators:
					state.claimingFromValidators?.isExpanded.toggle()
				}
				return .none
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .parent(action):
				return reduce(into: &state, parentAction: action)

			case let .setSections(sections):
				guard let sections else {
					return .send(.delegate(.failedToResolveSections))
				}
				state.withdrawals = sections.withdrawals
				state.dAppsUsed = sections.dAppsUsed
				state.contributingToPools = sections.contributingToPools
				state.redeemingFromPools = sections.redeemingFromPools
				state.stakingToValidators = sections.stakingToValidators
				state.unstakingFromValidators = sections.unstakingFromValidators
				state.claimingFromValidators = sections.claimingFromValidators
				state.deposits = sections.deposits
				state.accountDepositSetting = sections.accountDepositSetting
				state.accountDepositExceptions = sections.accountDepositExceptions
				state.proofs = sections.proofs
				state.accountDeletion = sections.accountDeletion
				return .none
			}
		}

		func reduce(into state: inout State, parentAction: InternalAction.ParentAction) -> Effect<Action> {
			switch parentAction {
			case let .resolveExecutionSummary(executionSummary, networkID):
				.run { send in
					let sections = try await sections(for: executionSummary, networkID: networkID)
					await send(.internal(.setSections(sections)))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}

			case let .resolveManifestSummary(manifestSummary, networkID):
				.run { send in
					let sections = try await sections(for: manifestSummary, networkID: networkID)
					await send(.internal(.setSections(sections)))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}

			case let .showResourceDetails(resource, details):
				resourceDetailsEffect(state: &state, resource: resource, details: details)
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .withdrawals(.delegate(.showAsset(transfer, token))),
			     let .deposits(.delegate(.showAsset(transfer, token))):
				guard let resource = transfer.resource, let details = transfer.details else {
					return .none
				}
				return resourceDetailsEffect(state: &state, resource: resource, details: details, nft: token)

			case let .dAppsUsed(.delegate(.openDapp(dAppID))), let .contributingToPools(.delegate(.openDapp(dAppID))), let .redeemingFromPools(.delegate(.openDapp(dAppID))):
				state.destination = .dApp(.init(dAppDefinitionAddress: dAppID))
				return .none

			case let .dAppsUsed(.delegate(.openUnknownAddresses(components))):
				state.destination = .unknownDappComponents(.init(
					title: L10n.TransactionReview.unknownComponents(components.count),
					rowHeading: L10n.Common.component,
					addresses: components.map { .component($0) }
				))
				return .none

			case let .contributingToPools(.delegate(.openUnknownAddresses(pools))), let .redeemingFromPools(.delegate(.openUnknownAddresses(pools))):
				state.destination = .unknownDappComponents(.init(
					title: L10n.TransactionReview.unknownPools(pools.count),
					rowHeading: L10n.Common.pool,
					addresses: pools.map { .resourcePool($0) }
				))
				return .none

			case .deposits(.delegate(.showCustomizeGuarantees)):
				guard let guarantees = state.deposits?.accounts.customizableGuarantees, !guarantees.isEmpty else { return .none }
				return .send(.delegate(.showCustomizeGuarantees(guarantees)))

			case let .proofs(.delegate(.showAsset(proof))):
				let resource = proof.resourceBalance.resource
				let details = proof.resourceBalance.details
				return resourceDetailsEffect(state: &state, resource: resource, details: details)

			default:
				return .none
			}
		}
	}
}

private extension InteractionReview.Sections {
	func resourceDetailsEffect(
		state: inout State,
		resource: OnLedgerEntity.Resource,
		details: KnownResourceBalance.Details,
		nft: OnLedgerEntity.NonFungibleToken? = nil
	) -> Effect<Action> {
		switch details {
		case let .fungible(details):
			state.destination = .fungibleTokenDetails(.init(
				resourceAddress: resource.resourceAddress,
				resource: .success(resource),
				ownedFungibleResource: .init(
					resourceAddress: resource.resourceAddress,
					atLedgerState: resource.atLedgerState,
					amount: details.amount,
					metadata: resource.metadata
				),
				isXRD: details.isXRD
			))

		case let .nonFungible(details):
			state.destination = .nonFungibleTokenDetails(.init(
				resourceAddress: resource.resourceAddress,
				resourceDetails: .success(resource),
				details: details,
				ledgerState: resource.atLedgerState
			))

		case let .liquidStakeUnit(details):
			state.destination = .lsuDetails(.init(
				validator: details.validator,
				stakeUnitResource: .init(
					resource: details.resource,
					amount: details.amount
				),
				xrdRedemptionValue: details.worth
			))

		case let .poolUnit(details):
			state.destination = .poolUnitDetails(.init(resourcesDetails: details.details))

		case let .stakeClaimNFT(details):
			state.destination = .nonFungibleTokenDetails(.init(
				resourceAddress: resource.resourceAddress,
				resourceDetails: .success(resource),
				details: nft.map { KnownResourceBalance.NonFungible.token(.init(token: $0)) },
				ledgerState: resource.atLedgerState,
				stakeClaim: details.stakeClaimTokens.stakeClaims.first,
				isClaimStakeEnabled: false
			))
		}

		return .none
	}
}

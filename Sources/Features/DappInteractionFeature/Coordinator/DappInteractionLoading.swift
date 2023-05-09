import CacheClient
import FeaturePrelude
import GatewayAPI

// MARK: - DappInteractionLoading
struct DappInteractionLoading: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let interaction: P2P.Dapp.Request
		var isLoading: Bool = false

		@PresentationState
		var errorAlert: AlertState<ViewAction.ErrorAlertAction>?

		init(interaction: P2P.Dapp.Request) {
			self.interaction = interaction
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case errorAlert(PresentationAction<ErrorAlertAction>)
		case dismissButtonTapped

		enum ErrorAlertAction: Sendable, Equatable {
			case retryButtonTapped
			case cancelButtonTapped
		}
	}

	enum InternalAction: Sendable, Equatable {
		case dappMetadataLoadingResult(TaskResult<DappContext>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dappContextLoaded(DappContext)
		case dismiss
	}

	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	@Dependency(\.cacheClient) var cacheClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$errorAlert, action: /Action.view .. ViewAction.errorAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return metadataLoadingEffect(with: &state)
		case let .errorAlert(.presented(action)):
			switch action {
			case .retryButtonTapped:
				return metadataLoadingEffect(with: &state)
			case .cancelButtonTapped:
				return .send(.delegate(.dismiss))
			}
		case .errorAlert:
			return .none
		case .dismissButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	func metadataLoadingEffect(with state: inout State) -> EffectTask<Action> {
		state.isLoading = true
		return .run { [fromRequest = state.interaction.metadata] send in

			let result: TaskResult<DappContext> = await {
				let isDeveloperModeEnabled = await appPreferencesClient.getPreferences().security.isDeveloperModeEnabled

				switch (fromRequest.dAppDefinitionAddress, isDeveloperModeEnabled) {
				case (.invalid, true):
					// DeveloperMode accepts invalid dapp definition addresses
					return .success(.fromRequest(fromRequest))

				case let (.valid(dappDefinitionAddress), _):
					// Valid DappDefinition => fetch from Ledger

					do {
						let fromLedger = try await cacheClient.withCaching(
							cacheEntry: .dAppRequestMetadata(dappDefinitionAddress.address),
							invalidateCached: { (cached: FromLedgerDappMetadata) in
								guard cached.name != nil, cached.
							}
							request: {
								let entityMetadataForDapp = try await gatewayAPIClient.getEntityMetadata(dappDefinitionAddress.address)
								return FromLedgerDappMetadata(
									entityMetadataForDapp: entityMetadataForDapp,
									dAppDefinintionAddress: dappDefinitionAddress,
									origin: fromRequest.origin
								)
							}
						)
						return .success(.fromLedger(fromLedger))
					} catch {
						guard isDeveloperModeEnabled else {
							return .failure(error)
						}
						loggerGlobal.warning("Failed to fetch Dapps metadata, but since 'isDeveloperModeEnabled' is enabled we surpress the error and allow continuation. Error: \(error)")
						return .success(.fromRequest(fromRequest))
					}

				default:
					return .failure(InvalidDappDefintionAddressNotSupportedWithoutDeveloperModeEnabled())
				}
			}()

			await send(.internal(.dappMetadataLoadingResult(result)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .dappMetadataLoadingResult(.success(dappContextLoaded)):
			state.isLoading = false
			return .send(.delegate(.dappContextLoaded(dappContextLoaded)))

		case let .dappMetadataLoadingResult(.failure(error)):
			state.errorAlert = .init(
				title: { TextState(L10n.App.errorOccurredTitle) },
				actions: {
					ButtonState(action: .send(.retryButtonTapped)) {
						TextState(L10n.DApp.MetadataLoading.ErrorAlert.retryButtonTitle)
					}
					ButtonState(role: .cancel, action: .send(.cancelButtonTapped)) {
						TextState(L10n.DApp.MetadataLoading.ErrorAlert.cancelButtonTitle)
					}
				},
				message: {
					TextState(
						L10n.DApp.MetadataLoading.ErrorAlert.message + {
							#if DEBUG
							"\n\n" + error.legibleLocalizedDescription
							#else
							""
							#endif
						}()
					)
				}
			)
			return .none
		}
	}
}

// MARK: - InvalidDappDefintionAddressNotSupportedWithoutDeveloperModeEnabled
struct InvalidDappDefintionAddressNotSupportedWithoutDeveloperModeEnabled: Swift.Error {}

extension FromLedgerDappMetadata {
	init(
		entityMetadataForDapp: GatewayAPI.EntityMetadataCollection,
		dAppDefinintionAddress: AccountAddress,
		origin: P2P.Dapp.Request.Metadata.Origin
	) {
		let items = entityMetadataForDapp.items
		self.init(
			dAppDefinintionAddress: dAppDefinintionAddress,
			origin: origin,
			name: items.first(where: { $0.key == "name" })?.value.asString,
			description: items.first(where: { $0.key == "description" })?.value.asString
		)
	}
}

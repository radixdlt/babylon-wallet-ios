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
		case dappMetadataLoadingResult(TaskResult<DappMetadata>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dappMetadataLoaded(DappMetadata)
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
		return .run { [dappDefinitionAddress = state.interaction.metadata.dAppDefinitionAddress, origin = state.interaction.metadata.origin] send in
			let metadata = await TaskResult {
				do {
					return try await cacheClient.withCaching(
						cacheEntry: .dAppRequestMetadata(dappDefinitionAddress.address),
						request: {
							try await DappMetadata(
								gatewayAPIClient.getEntityMetadata(dappDefinitionAddress.address).items,
								origin: origin
							)
						}
					)
				} catch is BadHTTPResponseCode {
					// FIXME: cleanup DappMetaData
					return DappMetadata(name: nil, origin: .init("")) // Not found - return unknown dapp metadata as instructed by network team
				} catch {
					if await appPreferencesClient.getPreferences().security.isDeveloperModeEnabled {
						loggerGlobal.notice("Failed to load metadata, but we surpressed the error since is appdeveloper")
						return DappMetadata(name: nil, origin: .init("")) // Not found - return unknown dapp metadata as instructed by network team
					} else {
						throw error
					}
				}
			}
			await send(.internal(.dappMetadataLoadingResult(metadata)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .dappMetadataLoadingResult(.success(dappMetadata)):
			state.isLoading = false
			return .send(.delegate(.dappMetadataLoaded(dappMetadata)))
		case let .dappMetadataLoadingResult(.failure(error)):
			state.errorAlert = .init(
				title: { TextState(L10n.Common.errorAlertTitle) },
				actions: {
					ButtonState(action: .send(.retryButtonTapped)) {
						TextState(L10n.Common.retry)
					}
					ButtonState(role: .cancel, action: .send(.cancelButtonTapped)) {
						TextState(L10n.Common.cancel)
					}
				},
				message: {
					TextState(
						L10n.DAppRequest.MetadataLoadingAlert.message + {
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

extension DappMetadata {
	init(
		_ items: [GatewayAPI.EntityMetadataItem],
		origin: P2P.Dapp.Request.Metadata.Origin
	) {
		self.init(
			name: items[.name]?.asString,
			thumbnail: items[.iconURL]?.asString.flatMap(URL.init),
			description: items[.description]?.asString,
			origin: origin
		)
	}
}

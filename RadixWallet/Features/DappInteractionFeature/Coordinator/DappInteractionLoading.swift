import ComposableArchitecture
import SwiftUI

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

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$errorAlert, action: /Action.view .. ViewAction.errorAlert)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			metadataLoadingEffect(with: &state)
		case let .errorAlert(.presented(action)):
			switch action {
			case .retryButtonTapped:
				metadataLoadingEffect(with: &state)
			case .cancelButtonTapped:
				.send(.delegate(.dismiss))
			}
		case .errorAlert:
			.none
		case .dismissButtonTapped:
			.send(.delegate(.dismiss))
		}
	}

	func metadataLoadingEffect(with state: inout State) -> Effect<Action> {
		state.isLoading = true

		if state.interaction.metadata.origin == .wallet {
			return .send(.internal(.dappMetadataLoadingResult(.success(.wallet(.init())))))
		}

		return .run { [request = state.interaction.metadata] send in

			let result: TaskResult<DappMetadata> = await {
				let isDeveloperModeEnabled = await appPreferencesClient.getPreferences().security.isDeveloperModeEnabled
				let dappDefinitionAddress = request.dAppDefinitionAddress

				do {
					let cachedMetadata = try await cacheClient.withCaching(
						cacheEntry: .dAppRequestMetadata(dappDefinitionAddress.address),
						invalidateCached: { (cached: DappMetadata.Ledger) in
							guard
								cached.name != nil,
								cached.description != nil,
								cached.thumbnail != nil
							else {
								/// Some of these fields were not set, fetch and see if they
								/// have been updated since last time...
								return .cachedIsInvalid
							}
							// All relevant fields are set, the cached metadata is valid.
							return .cachedIsValid
						},
						request: {
							let entityMetadataForDapp = try await gatewayAPIClient.getEntityMetadata(dappDefinitionAddress.address, .dappMetadataKeys)
							return DappMetadata.Ledger(
								entityMetadataForDapp: entityMetadataForDapp,
								dAppDefinintionAddress: dappDefinitionAddress,
								origin: request.origin
							)
						}
					)
					return .success(.ledger(cachedMetadata))
				} catch {
					guard isDeveloperModeEnabled else {
						return .failure(error)
					}
					loggerGlobal.warning("Failed to fetch Dapps metadata, but since 'isDeveloperModeEnabled' is enabled we surpress the error and allow continuation. Error: \(error)")
					return .success(.request(request))
				}

			}()

			await send(.internal(.dappMetadataLoadingResult(result)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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

extension DappMetadata.Ledger {
	init(
		entityMetadataForDapp: GatewayAPI.EntityMetadataCollection,
		dAppDefinintionAddress: AccountAddress,
		origin: P2P.Dapp.Request.Metadata.Origin
	) {
		let items = entityMetadataForDapp.items
		let maybeName: String? = items[.name]?.asString
		let name: NonEmptyString? = {
			guard let name = maybeName else {
				return nil
			}
			return NonEmptyString(rawValue: name)
		}()
		self.init(
			origin: origin,
			dAppDefinintionAddress: dAppDefinintionAddress,
			name: name,
			description: items[.description]?.asString,
			thumbnail: items[.iconURL]?.asURL
		)
	}
}

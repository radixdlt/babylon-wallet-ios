import FeaturePrelude
import GatewayAPI

// MARK: - DappInteractionLoading
struct DappInteractionLoading: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let interaction: P2P.FromDapp.WalletInteraction
		var isLoading: Bool = false

		@PresentationState
		var errorAlert: AlertState<ViewAction.ErrorAlertAction>?

		init(interaction: P2P.FromDapp.WalletInteraction) {
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

	@Dependency(\.gatewayAPIClient) var gatewayAPI

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
		return .run { [dappDefinitionAddress = state.interaction.metadata.dAppDefinitionAddress] send in
			let metadata = await TaskResult {
				do {
					return try await DappMetadata(gatewayAPI.getEntityMetadata(dappDefinitionAddress.address).items)
				} catch is BadHTTPResponseCode {
					return DappMetadata(name: nil) // Not found - return unknown dapp metadata as instructed by network team
				} catch {
					throw error
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

extension DappMetadata {
	init(_ items: [GatewayAPI.EntityMetadataItem]) {
		self.init(
			name: items.first(where: { $0.key == "name" })?.value.asString,
			description: items.first(where: { $0.key == "description" })?.value.asString
		)
	}
}

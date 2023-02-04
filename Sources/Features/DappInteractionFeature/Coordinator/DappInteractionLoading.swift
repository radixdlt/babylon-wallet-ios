import FeaturePrelude
import GatewayAPI

// MARK: - DappInteractionLoading
struct DappInteractionLoading: Sendable, FeatureReducer {
	// TODO: convert to enum State { case loading(...), finished(...) }
	struct State: Sendable, Hashable {
		let interaction: P2P.FromDapp.WalletInteraction
		var isLoading: Bool = false
		var errorAlert: AlertState<ViewAction.ErrorAlertAction>?

		init(interaction: P2P.FromDapp.WalletInteraction) {
			self.interaction = interaction
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case errorAlert(ErrorAlertAction)
		case dismissButtonTapped

		enum ErrorAlertAction: Sendable, Equatable {
			case retryButtonTapped
			case cancelButtonTapped
			case systemDismissed
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

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return metadataLoadingEffect(with: &state)
		case let .errorAlert(action):
			state.errorAlert = nil
			switch action {
			case .retryButtonTapped:
				return metadataLoadingEffect(with: &state)
			case .cancelButtonTapped, .systemDismissed:
				return .send(.delegate(.dismiss))
			}
		case .dismissButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	func metadataLoadingEffect(with state: inout State) -> EffectTask<Action> {
		state.isLoading = true
		return .run { [dappDefinitionAddress = state.interaction.metadata.dAppDefinitionAddress] send in
			let metadata = await TaskResult {
				try await gatewayAPI.accountMetadataByAddress(dappDefinitionAddress).metadata
			}
			.map(DappMetadata.init)
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
				title: TextState(L10n.App.errorOccurredTitle),
				message: TextState(error.legibleLocalizedDescription),
				buttons: [
					ButtonState(action: .send(.retryButtonTapped)) {
						TextState(L10n.DApp.MetadataLoading.ErrorAlert.retryButtonTitle)
					},
					ButtonState(role: .cancel, action: .send(.cancelButtonTapped)) {
						TextState(L10n.DApp.MetadataLoading.ErrorAlert.cancelButtonTitle)
					},
				]
			)
			return .none
		}
	}
}

extension DappMetadata {
	init(_ metadata: GatewayAPI.EntityMetadataCollection) {
		self.init(
			name: metadata.items.first(where: { $0.key == "name" })?.value ?? "",
			description: metadata.items.first(where: { $0.key == "description" })?.value ?? ""
		)
	}
}

import FeaturePrelude
import GatewayAPI
import ProfileClient

// MARK: - DAppProfile
public struct DAppProfile: Sendable, FeatureReducer {
	@Dependency(\.gatewayAPIClient) var gatewayClient
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient
	@Dependency(\.profileClient) var profileClient

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public let dApp: OnNetwork.ConnectedDappDetailed

		@PresentationState
		public var presentedPersona: PersonaProfile.State?

		init(dApp: OnNetwork.ConnectedDappDetailed, presentedPersona: PersonaProfile.State? = nil) {
			self.dApp = dApp
			self.presentedPersona = presentedPersona
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped
		case copyAddressButtonTapped
		case tokenTapped(UUID)
		case nftTapped(UUID)
		case personaTapped(OnNetwork.Persona.ID)
		case forgetThisDApp
	}

	public enum DelegateAction: Sendable, Equatable {
		case forgetDApp(id: OnNetwork.ConnectedDapp.ID, networkID: NetworkID)
	}

	public enum ChildAction: Sendable, Equatable {
		case presentedPersona(PresentationActionOf<PersonaProfile>)
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$presentedPersona, action: /Action.child .. ChildAction.presentedPersona) {
				PersonaProfile()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:

			return .none

		case .copyAddressButtonTapped:
			let address = state.dApp.dAppDefinitionAddress
			return .fireAndForget {
				pasteboardClient.copyString(address.address)
			}

		case .openURLTapped:
//			let url = state.dApp.url
			return .fireAndForget {
				await openURL(.placeholder)
			}

		case let .tokenTapped(token):
			return .none

		case let .nftTapped(nft):
			return .none

		case let .personaTapped(id):
			guard let persona = state.dApp.detailedAuthorizedPersonas[id: id] else { return .none }
			let presented = PersonaProfile.State(dAppName: state.dApp.displayName.rawValue, persona: persona)
			return .send(.child(.presentedPersona(.present(presented))))

		case .forgetThisDApp:
			let dAppID = state.dApp.dAppDefinitionAddress
			let networkID = state.dApp.networkID
			return .send(.delegate(.forgetDApp(id: dAppID, networkID: networkID)))
		}
	}

	func metadataLoadingEffect(with state: inout State) -> EffectTask<Action> {
//		state.isLoading = true
		let dappDefinitionAddress = state.dApp.dAppDefinitionAddress
		return .task {
			let metadata = await TaskResult {
				do {
					return DappMetadata(try await gatewayAPI.resourceDetailsByResourceIdentifier(dappDefinitionAddress.address).metadata)
				} catch let error as BadHTTPResponseCode {
					return DappMetadata(name: nil) // Not found - return unknown dapp metadata as instructed by network team
				} catch {
					throw error
				}
			}
			await send(.internal(.dappMetadataLoadingResult(metadata)))
		}
	}
}

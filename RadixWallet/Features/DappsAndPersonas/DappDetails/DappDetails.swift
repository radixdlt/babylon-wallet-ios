import ComposableArchitecture
import SwiftUI

// MARK: - DappDetails
public struct DappDetails: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.openURL) var openURL
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public struct FailedToLoadMetadata: Error, Hashable {}

	public typealias Store = StoreOf<Self>

	// MARK: State

	public struct State: Sendable, Hashable {
		public enum Context: Sendable, Hashable {
			case general
			case settings(SettingsContext)

			public enum SettingsContext: Sendable, Hashable {
				case personaDetails
				case authorizedDapps
			}
		}

		public let context: Context

		public let dAppDefinitionAddress: DappDefinitionAddress

		// This will only be non-nil if the dApp is in fact authorized
		public var authorizedDapp: Profile.Network.AuthorizedDappDetailed?

		public var personaList: PersonaList.State

		@Loadable
		public var metadata: OnLedgerEntity.Metadata? = nil

		@Loadable
		public var resources: Resources? = nil

		@Loadable
		public var associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil

		@PresentationState
		public var destination: Destination.State? = nil

		// Authorized dApp
		public init(
			dApp: Profile.Network.AuthorizedDappDetailed,
			context: Context.SettingsContext,
			metadata: OnLedgerEntity.Metadata? = nil,
			resources: Resources? = nil,
			associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil,
			destination: Destination.State? = nil
		) {
			self.context = .settings(context)
			self.dAppDefinitionAddress = dApp.dAppDefinitionAddress
			self.authorizedDapp = dApp
			self.personaList = .init(dApp: dApp)
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
			self.destination = destination
		}

		// General
		public init(
			dAppDefinitionAddress: DappDefinitionAddress,
			metadata: OnLedgerEntity.Metadata? = nil,
			resources: Resources? = nil,
			associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil,
			destination: Destination.State? = nil
		) {
			self.context = .general
			self.dAppDefinitionAddress = dAppDefinitionAddress
			self.authorizedDapp = nil
			self.personaList = .init() // TODO: Check reloading behaviour
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
			self.destination = destination
		}

		public struct Resources: Hashable, Sendable {
			public var fungible: IdentifiedArrayOf<OnLedgerEntity.Resource>
			public var nonFungible: IdentifiedArrayOf<OnLedgerEntity.Resource>
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped(URL)
		case fungibleTapped(ResourceAddress)
		case nonFungibleTapped(ResourceAddress)
		case dAppTapped(DappDefinitionAddress)
		case forgetThisDappTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dAppForgotten
	}

	public enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<OnLedgerEntity.Metadata>)
		case resourcesLoaded(Loadable<State.Resources>)
		case associatedDappsLoaded(Loadable<[OnLedgerEntity.AssociatedDapp]>)
		case dAppUpdated(Profile.Network.AuthorizedDappDetailed)
	}

	public enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)
	}

	// MARK: - Destination

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case personaDetails(PersonaDetails.State)
			case fungibleDetails(FungibleTokenDetails.State)
			case nonFungibleDetails(NonFungibleTokenDetails.State)
			case dappDetails(DappDetails.State)
			case confirmDisconnectAlert(AlertState<Action.ConfirmDisconnectAlert>)
		}

		public enum Action: Equatable, Sendable {
			case personaDetails(PersonaDetails.Action)
			case fungibleDetails(FungibleTokenDetails.Action)
			case nonFungibleDetails(NonFungibleTokenDetails.Action)
			case dappDetails(DappDetails.Action)
			case confirmDisconnectAlert(ConfirmDisconnectAlert)

			public enum ConfirmDisconnectAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.personaDetails, action: /Action.personaDetails) {
				PersonaDetails()
			}
			Scope(state: /State.fungibleDetails, action: /Action.fungibleDetails) {
				FungibleTokenDetails()
			}
			Scope(state: /State.nonFungibleDetails, action: /Action.nonFungibleDetails) {
				NonFungibleTokenDetails()
			}
		}
	}

	// MARK: Reducer

	struct MissingResource: LocalizedError {
		let address: ResourceAddress

		var errorDescription: String {
			"Missing resource: \(address)"
		}
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			state.$metadata = .loading
			state.$resources = .loading
			let dAppID = state.dAppDefinitionAddress
			let checkForAuthorizedDapp = state.authorizedDapp == nil
			return .run { send in
				if checkForAuthorizedDapp, let authorizedDapp = try? await authorizedDappsClient.getDetailedDapp(dAppID) {
					await send(.internal(.dAppUpdated(authorizedDapp)))
				}

				let result = await TaskResult {
					try await onLedgerEntitiesClient.getAssociatedDapp(dAppID).metadata
				}
				await send(.internal(.metadataLoaded(.init(result: result))))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .openURLTapped(url):
			return .run { _ in
				await openURL(url)
			}

		case let .fungibleTapped(address):
			guard let resource = state.resources?.fungible[id: address] else {
				errorQueue.schedule(MissingResource(address: address))
				return .none
			}

			// FIXME: Can a dApp be associated with XRD
			state.destination = .fungibleDetails(.init(resourceAddress: address, resource: .success(resource), isXRD: false))
			return .none

		case let .nonFungibleTapped(address):
			guard let resource = state.resources?.nonFungible[id: address] else {
				errorQueue.schedule(MissingResource(address: address))
				return .none
			}

			state.destination = .nonFungibleDetails(.init(resourceAddress: resource.resourceAddress, resourceDetails: .success(resource), ledgerState: resource.atLedgerState))
			return .none

		case let .dAppTapped(address):
			state.destination = .dappDetails(.init(dAppDefinitionAddress: address))
			return .none

		case .forgetThisDappTapped:
			state.destination = .confirmDisconnectAlert(.confirmDisconnect)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .personaList(.delegate(.openDetails(persona))):
			guard let dApp = state.authorizedDapp, let detailedPersona = dApp.detailedAuthorizedPersonas[id: persona.id] else { return .none }
			let personaDetailsState = PersonaDetails.State(.dApp(dApp, persona: detailedPersona))
			state.destination = .personaDetails(personaDetailsState)
			return .none

		case .personaList:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .metadataLoaded(metadata):
			state.$metadata = metadata

			let dAppDefinitionAddress = state.dAppDefinitionAddress
			return .run { send in
				let resources = await metadata.flatMap { await loadResources(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.resourcesLoaded(resources)))

				let associatedDapps = await metadata.flatMap { await loadDapps(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.associatedDappsLoaded(associatedDapps)))
			}

		case let .resourcesLoaded(resources):
			state.$resources = resources
			return .none

		case let .associatedDappsLoaded(dApps):
			state.$associatedDapps = dApps
			return .none

		case let .dAppUpdated(dApp):
			assert(dApp.dAppDefinitionAddress == state.dAppDefinitionAddress, "dAppUpdated called with wrong dApp")
			guard !dApp.detailedAuthorizedPersonas.isEmpty else {
				// FIXME: Without this delay, the screen is never dismissed
				return disconnectDappEffect(dAppID: dApp.dAppDefinitionAddress, networkID: dApp.networkID, delay: .milliseconds(500))
			}
			state.authorizedDapp = dApp
			state.personaList = .init(dApp: dApp)

			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .personaDetails(.delegate(.personaDeauthorized)):
			let dAppID = state.dAppDefinitionAddress
			return update(dAppID: dAppID, dismissPersonaDetails: true)

		case .personaDetails(.delegate(.personaChanged)):
			let dAppID = state.dAppDefinitionAddress
			return update(dAppID: dAppID, dismissPersonaDetails: false)

		case .fungibleDetails(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case .nonFungibleDetails(.delegate(.dismiss)):
			state.destination = nil
			return .none

		case .confirmDisconnectAlert(.confirmTapped):
			assert(state.authorizedDapp != nil, "Can only disconnect a dApp that has been authorized")
			guard let networkID = state.authorizedDapp?.networkID else { return .none }
			return disconnectDappEffect(dAppID: state.dAppDefinitionAddress, networkID: networkID)

		default:
			return .none
		}
	}

	/// Loads any fungible and non-fungible resources associated with the dApp
	private func loadResources(
		metadata: OnLedgerEntity.Metadata,
		validated dAppDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<State.Resources> {
		let resources = metadata.claimedEntities?.compactMap { try? ResourceAddress(validatingAddress: $0) } ?? []
		guard !resources.isEmpty else { return .idle }

		let result = await TaskResult {
			let items = try await onLedgerEntitiesClient.getResources(resources)
				.filter { $0.metadata.dappDefinitions?.contains(dAppDefinitionAddress) == true }
			let fungible: IdentifiedArray = .init(items.filter { $0.fungibility == .fungible }) { $1 }
			let nonFungible: IdentifiedArray = .init(items.filter { $0.fungibility == .nonFungible }) { $1 }

			return State.Resources(fungible: fungible, nonFungible: nonFungible)
		}

		return .init(result: result)
	}

	/// Loads any other dApps associated with the dApp
	private func loadDapps(
		metadata: OnLedgerEntity.Metadata,
		validated dappDefinitionAddress: DappDefinitionAddress
	) async -> Loadable<[OnLedgerEntity.AssociatedDapp]> {
		guard let dAppDefinitions = metadata.dappDefinitions else { return .idle }

		let loadedDApps = await (try? onLedgerEntitiesClient.getAssociatedDapps(dAppDefinitions)) ?? []
		let associatedDapps = loadedDApps.filter { dApp in
			do {
				try dApp.metadata.validate(dAppDefinitionAddress: dApp.address)
				guard dApp.metadata.name != nil else {
					throw OnLedgerEntity.Metadata.MetadataError.missingName
				}
				return true
			} catch {
				loggerGlobal.warning("Invalida dApp \(error)")
				return false
			}
		}

		guard !associatedDapps.isEmpty else { return .idle }

		return .success(associatedDapps)
	}

	private func update(dAppID: DappDefinitionAddress, dismissPersonaDetails: Bool) -> Effect<Action> {
		.run { send in
			let updatedDapp = try await authorizedDappsClient.getDetailedDapp(dAppID)
			await send(.internal(.dAppUpdated(updatedDapp)))
			if dismissPersonaDetails {
				await send(.destination(.dismiss))
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func disconnectDappEffect(dAppID: DappDefinitionAddress, networkID: NetworkID, delay: Duration? = .zero) -> Effect<Action> {
		.run { send in
			if let delay {
				try await clock.sleep(for: delay)
			}
			try await authorizedDappsClient.forgetAuthorizedDapp(dAppID, networkID)
			await send(.delegate(.dAppForgotten))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

extension AlertState<DappDetails.Destination.Action.ConfirmDisconnectAlert> {
	static var confirmDisconnect: AlertState {
		AlertState {
			TextState(L10n.AuthorizedDapps.ForgetDappAlert.title)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.AuthorizedDapps.ForgetDappAlert.forget)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
		} message: {
			TextState(L10n.AuthorizedDapps.ForgetDappAlert.message)
		}
	}
}

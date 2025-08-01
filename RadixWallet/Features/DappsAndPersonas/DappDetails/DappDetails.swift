import ComposableArchitecture
import SwiftUI

// MARK: - DappDetails
struct DappDetails: Sendable, FeatureReducer {
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	struct FailedToLoadMetadata: Error, Hashable {}

	typealias Store = StoreOf<Self>

	// MARK: State

	struct State: Sendable, Hashable {
		enum Context: Sendable, Hashable {
			case general
			case settings(SettingsContext)

			enum SettingsContext: Sendable, Hashable {
				case personaDetails
				case dAppsList
			}
		}

		let context: Context

		let dAppDefinitionAddress: DappDefinitionAddress

		// This will only be non-nil if the dApp is in fact authorized
		var authorizedDapp: AuthorizedDappDetailed?

		var personaList: PersonaList.State

		var mainWebsite: URL?

		@Loadable
		var metadata: OnLedgerEntity.Metadata? = nil

		@Loadable
		var resources: Resources? = nil

		@Loadable
		var associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil

		@PresentationState
		var destination: Destination.State? = nil

		// Authorized dApp
		init(
			dApp: AuthorizedDappDetailed,
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
		init(
			dAppDefinitionAddress: DappDefinitionAddress,
			context: Context = .general,
			metadata: OnLedgerEntity.Metadata? = nil,
			resources: Resources? = nil,
			associatedDapps: [OnLedgerEntity.AssociatedDapp]? = nil,
			destination: Destination.State? = nil
		) {
			self.context = context
			self.dAppDefinitionAddress = dAppDefinitionAddress
			self.authorizedDapp = nil
			self.personaList = .init() // TODO: Check reloading behaviour
			self.metadata = metadata
			self.resources = resources
			self.associatedDapps = associatedDapps
			self.destination = destination
		}

		struct Resources: Hashable, Sendable {
			var fungible: IdentifiedArrayOf<OnLedgerEntity.Resource>
			var nonFungible: IdentifiedArrayOf<OnLedgerEntity.Resource>

			var isEmpty: Bool {
				fungible.isEmpty && nonFungible.isEmpty
			}
		}
	}

	// MARK: Action

	enum ViewAction: Sendable, Equatable {
		case appeared
		case fungibleTapped(ResourceAddress)
		case nonFungibleTapped(ResourceAddress)
		case dAppTapped(DappDefinitionAddress)
		case depositsVisibleToggled(Bool)
		case forgetThisDappTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case dAppForgotten
	}

	enum InternalAction: Sendable, Equatable {
		case metadataLoaded(Loadable<OnLedgerEntity.Metadata>)
		case resourcesLoaded(Loadable<State.Resources>)
		case associatedDappsLoaded(Loadable<[OnLedgerEntity.AssociatedDapp]>)
		case dAppUpdated(AuthorizedDappDetailed)
		case mainWebsiteValidated(URL)
	}

	enum ChildAction: Sendable, Equatable {
		case personaList(PersonaList.Action)
	}

	// MARK: - Destination

	struct Destination: DestinationReducer {
		enum State: Hashable, Sendable {
			case personaDetails(PersonaDetails.State)
			case fungibleDetails(FungibleTokenDetails.State)
			case nonFungibleDetails(NonFungibleTokenDetails.State)
			case dappDetails(DappDetails.State)
			case confirmDisconnectAlert(AlertState<Action.ConfirmDisconnectAlert>)
		}

		enum Action: Equatable, Sendable {
			case personaDetails(PersonaDetails.Action)
			case fungibleDetails(FungibleTokenDetails.Action)
			case nonFungibleDetails(NonFungibleTokenDetails.Action)
			case dappDetails(DappDetails.Action)
			case confirmDisconnectAlert(ConfirmDisconnectAlert)

			enum ConfirmDisconnectAlert: Sendable, Equatable {
				case confirmTapped
				case cancelTapped
			}
		}

		var body: some ReducerOf<Self> {
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

	@Dependency(\.rolaClient) var rolaClient

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.personaList, action: /Action.child .. ChildAction.personaList) {
			PersonaList()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

		case let .depositsVisibleToggled(isVisible):
			state.authorizedDapp?.showDeposits(isVisible)
			guard let detailed = state.authorizedDapp else {
				return .none
			}
			return .run { _ in
				var dapp = try await authorizedDappsClient.getAuthorizedDapp(detailed: detailed)
				dapp.showDeposits(isVisible)
				try await authorizedDappsClient.updateAuthorizedDapp(dapp)
			}

		case .forgetThisDappTapped:
			state.destination = .confirmDisconnectAlert(.confirmDisconnect)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .personaList(.delegate(.openDetails(persona))):
			guard
				let dApp = state.authorizedDapp,
				let detailedPersona = dApp.detailedAuthorizedPersonas.asIdentified()[id: persona.id]
			else { return .none }

			let personaDetailsState = PersonaDetails.State(.dApp(dApp, persona: detailedPersona))
			state.destination = .personaDetails(personaDetailsState)
			return .none

		case .personaList:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .metadataLoaded(metadata):
			state.$metadata = metadata

			let dAppDefinitionAddress = state.dAppDefinitionAddress
			return .run { send in
				let resources = await metadata.flatMap { await loadResources(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.resourcesLoaded(resources)))

				let associatedDapps = await metadata.flatMap { await loadDapps(metadata: $0, validated: dAppDefinitionAddress) }
				await send(.internal(.associatedDappsLoaded(associatedDapps)))

				if let websites = metadata.wrappedValue?.claimedWebsites {
					for website in websites {
						do {
							try await rolaClient.performWellKnownFileCheck(website, dAppDefinitionAddress)
							await send(.internal(.mainWebsiteValidated(website)))
							return
						} catch {
							loggerGlobal.error("Failed to validate dapp main website: \(error)")
						}
					}
				}
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
				return disconnectDappEffect(dAppID: dApp.dAppDefinitionAddress, networkID: dApp.networkId, delay: .milliseconds(500))
			}
			state.authorizedDapp = dApp
			state.personaList = .init(dApp: dApp)

			return .none

		case let .mainWebsiteValidated(url):
			state.mainWebsite = url
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .personaDetails(.delegate(.personaDeauthorized)):
			let dAppID = state.dAppDefinitionAddress
			return update(dAppID: dAppID, dismissPersonaDetails: true)

		case .personaDetails(.delegate(.personaChanged)):
			let dAppID = state.dAppDefinitionAddress
			return update(dAppID: dAppID, dismissPersonaDetails: false)

		case .confirmDisconnectAlert(.confirmTapped):
			assert(state.authorizedDapp != nil, "Can only disconnect a dApp that has been authorized")
			guard let networkID = state.authorizedDapp?.networkId else { return .none }
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
				.filter {
					$0.metadata.dappDefinition == dAppDefinitionAddress ||
						$0.metadata.dappDefinitions?.contains(dAppDefinitionAddress) == true
				}
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

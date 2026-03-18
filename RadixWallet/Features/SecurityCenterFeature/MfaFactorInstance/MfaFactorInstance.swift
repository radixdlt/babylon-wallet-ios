import ComposableArchitecture
import Sargon

// MARK: - MfaFactorInstance
@Reducer
struct MfaFactorInstance {
	@ObservableState
	struct State: Hashable {
		struct UsedByAccount: Hashable {
			let address: AccountAddress
			let profileAccount: Account?
			let addressBookName: String?
		}

		struct ActiveUsage: Hashable {
			let signatureResource: NonFungibleGlobalId
			let accounts: [UsedByAccount]
			let factorSource: FactorSource?
		}

		var activeUsages: Loadable<[ActiveUsage]> = .idle

		@Presents
		var destination: Destination.State? = nil
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case factorSourceDetail(FactorSourceDetail.State)
			case addressDetails(AddressDetails.State)
		}

		@CasePathable
		enum Action: Equatable {
			case factorSourceDetail(FactorSourceDetail.Action)
			case addressDetails(AddressDetails.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.factorSourceDetail, action: \.factorSourceDetail) {
				FactorSourceDetail()
			}
			Scope(state: \.addressDetails, action: \.addressDetails) {
				AddressDetails()
			}
		}
	}

	enum Action: Equatable {
		case appeared
		case currentUsageLoaded(Loadable<[State.ActiveUsage]>)
		case signatureResourceTapped(NonFungibleGlobalId)
		case factorSourceIntegrityLoaded(FactorSourceIntegrity)
		case factorSourceTapped(FactorSource)
		case continueTapped
		case destination(PresentationAction<Destination.Action>)
		case delegate(DelegateAction)
	}

	enum DelegateAction: Equatable {
		case continueTapped
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.addressBookClient) var addressBookClient
	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .appeared:
				state.activeUsages = .loading
				return .run { send in
					let loadedUsages: Loadable<[State.ActiveUsage]>
					do {
						loadedUsages = try await .success(loadCurrentUsages())
					} catch {
						loadedUsages = .failure(error)
					}
					await send(.currentUsageLoaded(loadedUsages))
				}

			case let .currentUsageLoaded(loadable):
				state.activeUsages = loadable
				if case let .failure(error) = loadable {
					errorQueue.schedule(error)
				}
				return .none

			case .continueTapped:
				return .send(.delegate(.continueTapped))

			case let .signatureResourceTapped(globalId):
				state.destination = .addressDetails(.init(address: .nonFungibleGlobalID(globalId)))
				return .none

			case let .factorSourceIntegrityLoaded(integrity):
				state.destination = .factorSourceDetail(.init(integrity: integrity))
				return .none

			case let .factorSourceTapped(factorSource):
				return .run { send in
					let integrity = try await SargonOs.shared.factorSourceIntegrity(factorSource: factorSource.asGeneral)
					await send(.factorSourceIntegrityLoaded(integrity))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}

			case .destination:
				return .none

			case .delegate:
				return .none
			}
		}
		.ifLet(destinationPath, action: \.destination) {
			Destination()
		}
	}

	private func loadCurrentUsages() async throws -> [State.ActiveUsage] {
		let used = try await SargonOs.shared.usedMfaSignatureResourcesWithAccountsCurrentNetwork()
		let factorSources = try await factorSourcesClient.getFactorSources().elements
		let factorSourcesByID = try Dictionary(keysWithValues: factorSources.map { ($0.id, $0) })
		let profileAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
		let addressBookEntries = try addressBookClient.entriesOnCurrentNetwork()
		let addressBookEntriesByAddress = try Dictionary(keysWithValues: addressBookEntries.map { ($0.address, $0) })

		return used.map { usedResource in
			let factorSource = factorSourcesByID[usedResource.mfaFactorInstance.factorInstance.factorSourceId.asGeneral]
			let usedByAccounts = usedResource.accountAddresses.map { address in
				State.UsedByAccount(
					address: address,
					profileAccount: profileAccounts[id: address],
					addressBookName: addressBookEntriesByAddress[address]?.name.value
				)
			}

			return State.ActiveUsage(
				signatureResource: usedResource.nonFungibleGlobalId,
				accounts: usedByAccounts,
				factorSource: factorSource
			)
		}
	}
}

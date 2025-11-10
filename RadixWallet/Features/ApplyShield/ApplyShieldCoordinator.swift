import Sargon

extension ApplyShield {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let securityStructure: SecurityStructureOfFactorSources
			var selectedAccounts: [AccountAddress] = []
			var selectedPersonas: [IdentityAddress] = []

			var root: Path.State
			var path: StackState<Path.State> = .init()

			init(
				securityStructure: SecurityStructureOfFactorSources,
				selectedAccounts: [AccountAddress] = [],
				selectedPersonas: [IdentityAddress] = [],
				root: Path.State? = nil
			) {
				self.securityStructure = securityStructure
				self.root = root ?? .intro(.init(shieldID: securityStructure.metadata.id))
				self.selectedAccounts = selectedAccounts
				self.selectedPersonas = selectedPersonas
			}
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case intro(Intro)
			case chooseAccounts(ChooseAccountsForShield)
			case choosePersonas(ChoosePersonasForShield)
			case completion
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case applyButtonTapped
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(Path.Action)
			case path(StackActionOf<Path>)
		}

		enum DelegateAction: Sendable, Equatable {
			case skipped
			case finished
		}

		@Dependency(\.dappInteractionClient) var dappInteractionClient
		@Dependency(\.submitTXClient) var submitTXClient
		@Dependency(\.errorQueue) var errorQueue

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				Path.intro(.init())
			}
			Reduce(core)
				.forEach(\.path, action: \.child.path)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .applyButtonTapped:
				let addresses: [AddressOfAccountOrPersona] = state.selectedAccounts.map { .account($0) } + state.selectedPersonas.map { .identity($0) }
				return .run { [securityStructure = state.securityStructure] send in
					let manifest = try await SargonOs.shared.makeUpdateSecurityShieldManifest(securityStructure: securityStructure, address: addresses.first!)

					Task {
						let result = await dappInteractionClient.addWalletInteraction(
							.transaction(.init(send: .init(transactionManifest: manifest))),
							.shieldUpdate
						)

						// TODO: Remove this temporary - will be handled by Sargon once batch transactions are implemented
						switch result {
						case let .dapp(.success(success)):
							if case let .transaction(tx) = success.items {
								/// Wait for the transaction to be committed
								let txID = tx.send.transactionIntentHash
								if try await submitTXClient.hasTXBeenCommittedSuccessfully(txID) {
									// TODO: Use a client which wraps SargonOS so this features becomes testable
									try await SargonOs.shared.commitProvisionalSecurityState(entityAddress: addresses.first!)
								}
								return
							}

							assertionFailure("Not a transaction Response?")
						case .dapp(.failure), .none:
							break
						}
					}
					await send(.delegate(.finished))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case .root(.intro(.delegate(.started))):
				state.path.append(.chooseAccounts(.init(
					chooseAccounts: .init(
						context: .permission(.exactly(1)),
						canCreateNewAccount: false
					)
				)))
				return .none
			case .root(.intro(.delegate(.skipped))):
				return .send(.delegate(.skipped))
			case let .path(.element(id: _, action: .chooseAccounts(.delegate(.finished(accounts))))):
				if accounts.isEmpty {
					state.path.append(.choosePersonas(.init(
						choosePersonas: .init(
							selectionRequirement: .exactly(1)
						),
						canBeSkipped: false
					)))
					return .none
				}
				state.selectedAccounts = accounts
				state.path.append(.completion)
				return .none
			case let .path(.element(id: _, action: .choosePersonas(.delegate(.finished(personas))))):
				state.selectedPersonas = personas
				state.path.append(.completion)
				return .none
			default:
				return .none
			}
		}
	}
}

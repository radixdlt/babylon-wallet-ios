import Sargon

// MARK: - ApplyShield.Coordinator
extension ApplyShield {
	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let securityStructure: SecurityStructureOfFactorSources
			var entityAddress: AddressOfAccountOrPersona?

			var root: Path.State
			var path: StackState<Path.State> = .init()

			init(
				securityStructure: SecurityStructureOfFactorSources,
				entityAddress: AddressOfAccountOrPersona? = nil,
				root: Path.State? = nil
			) {
				self.securityStructure = securityStructure
				self.root = root ?? .intro(.init(shieldID: securityStructure.metadata.id))
				self.entityAddress = entityAddress
			}
		}

		@Reducer
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
		@Dependency(\.accessControllerClient) var accessControllerClient

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
				guard let entityAddress = state.entityAddress else {
					return .none
				}
				return .run { [securityStructure = state.securityStructure] send in
					let manifest = try await SargonOs.shared.makeUpdateSecurityShieldManifest(securityStructure: securityStructure, address: entityAddress)

					Task {
						let result = await dappInteractionClient.addWalletInteraction(
							.transaction(.init(send: .init(transactionManifest: manifest))),
							.shieldUpdate
						)

						switch result.p2pResponse {
						case let .dapp(.success(success)):
							if case let .transaction(tx) = success.items {
								/// Wait for the transaction to be committed
								let txID = tx.send.transactionIntentHash
								if try await submitTXClient.hasTXBeenCommittedSuccessfully(txID) {
									if let signedIntent = result.notarizedTransaction, !isAccessControllerTimedRecoveryManifest(manifest: signedIntent.signedIntent.intent.manifest) {
										try await SargonOs.shared.commitProvisionalSecurityState(entityAddress: entityAddress)
									}
									// Force refresh access controller state after successful shield update
									await accessControllerClient.forceRefresh()
								}
								return
							}

							assertionFailure("Not a transaction Response?")
						case .dapp(.failure):
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
				guard let account = accounts.first else {
					state.path.append(.choosePersonas(.init(
						choosePersonas: .init(
							selectionRequirement: .exactly(1)
						),
						canBeSkipped: false
					)))
					return .none
				}
				state.entityAddress = .account(account)
				state.path.append(.completion)
				return .none
			case let .path(.element(id: _, action: .choosePersonas(.delegate(.finished(personas))))):
				guard let persona = personas.first else {
					return .none
				}
				state.entityAddress = .identity(persona)
				state.path.append(.completion)
				return .none
			default:
				return .none
			}
		}
	}
}

// MARK: - ApplyShield.Coordinator.Path.State + Hashable
extension ApplyShield.Coordinator.Path.State: Hashable {}

// MARK: - ApplyShield.Coordinator.Path.Action + Equatable
extension ApplyShield.Coordinator.Path.Action: Equatable {}

import SargonUniFFI

// MARK: - HandleAccessControllerTimedRecovery
@Reducer
struct HandleAccessControllerTimedRecovery: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let acDetails: AccessControllerStateDetails
		let provisionalSecurityState: SecurityStructureOfFactorSources?
		let entity: AccountOrPersona

		init(acDetails: AccessControllerStateDetails) throws {
			self.acDetails = acDetails
			entity = try SargonOs.shared.entityByAccessControllerAddress(address: acDetails.address)
			provisionalSecurityState = try? SargonOs.shared.provisionalSecurityStructureOfFactorSourcesFromAddressOfAccountOrPersona(addressOfAccountOrPersona: entity.address)
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
		case stopButtonTapped
		case confirmButtonTapped
	}

	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.submitTXClient) var submitTXClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		case .stopButtonTapped:
			.run { [entityAddress = state.entity.address] _ in
				let manifest = try await SargonOS.shared.makeStopTimedRecoveryManifest(address: entityAddress)
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
								// TODO: Use a client which wraps SargonOS so this features becomes testable
								try await SargonOs.shared.removeProvisionalSecurityState(entityAddress: entityAddress)
							}
							return
						}

						assertionFailure("Not a transaction Response?")
					case .dapp(.failure):
						break
					}
				}
			}
		case .confirmButtonTapped:
			.run { [entityAddress = state.entity.address] _ in
				let manifest = try await SargonOS.shared.makeConfirmTimedRecoveryManifest(address: entityAddress)
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
								// TODO: Use a client which wraps SargonOS so this features becomes testable
								try await SargonOs.shared.commitProvisionalSecurityState(entityAddress: entityAddress)
							}
							return
						}

						assertionFailure("Not a transaction Response?")
					case .dapp(.failure):
						break
					}
				}
			}
		}
	}
}

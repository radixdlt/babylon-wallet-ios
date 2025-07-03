// MARK: - AddFactorSource.Intro
extension AddFactorSource {
	@Reducer
	struct Intro: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let kind: FactorSourceKind

			var hasAConnectorExtension: Bool = false
			var pendingAction: ActionRequiringP2P? = nil

			@Presents
			var destination: Destination.State? = nil
		}

		enum ActionRequiringP2P: Sendable, Hashable {
			case addLedger
			case continueWithFactorsource(FactorSource)
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case task
			case continueTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case completed
		}

		enum InternalAction: Sendable, Equatable {
			case hasAConnectorExtension(Bool)
			case receivedLedgerDeviceInfo(LedgerDeviceInfo)
			case factorSourceAlreadyExsits(FactorSource)
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case noP2PLink(AlertState<NoP2PLinkAlert>)
				case addNewP2PLink(NewConnection.State)
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case noP2PLink(NoP2PLinkAlert)
				case addNewP2PLink(NewConnection.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.addNewP2PLink, action: \.addNewP2PLink) {
					NewConnection()
				}
			}
		}

		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		var body: some ReducerOf<Self> {
			Reduce(core)
				.ifLet(destinationPath, action: \.destination) {
					Destination()
				}
		}

		private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				if state.kind == .ledgerHqHardwareWallet {
					return checkP2PLinkEffect()
				}
				return .none
			case .continueTapped:
				if state.kind == .ledgerHqHardwareWallet {
					guard state.hasAConnectorExtension else {
						state.destination = .noP2PLink(.noP2Plink)
						return .none
					}
					// Present identifying factor and call ledger client
					return .run { send in
						let info = try await ledgerHardwareWalletClient.getDeviceInfo()
						let existingLedger = try await factorSourcesClient.getFactorSource(
							id: FactorSourceID.hash(value: FactorSourceIdFromHash(kind: .ledgerHqHardwareWallet, body: Exactly32Bytes(bytes: info.id.data.data))),
							as: LedgerHardwareWalletFactorSource.self
						)

						if let existingLedger {
							await send(.internal(.factorSourceAlreadyExsits(existingLedger.asGeneral)))
						} else {
							await send(.internal(.receivedLedgerDeviceInfo(info)))
						}
					} catch: { error, _ in
						errorQueue.schedule(error)
					}
				}
				return .send(.delegate(.completed))
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .hasAConnectorExtension(hasCE):
				state.hasAConnectorExtension = hasCE
				return .none
			case let .receivedLedgerDeviceInfo(ledgerDeviceInfo):
				return .none
			case let .factorSourceAlreadyExsits(fs):
				return .none
			}
		}

		func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
			switch presentedAction {
			case let .noP2PLink(alertAction):
				switch alertAction {
				case .addNewP2PLinkTapped:
					state.destination = .addNewP2PLink(.init())
					return .none

				case .cancelTapped:
					return .none
				}

			case let .addNewP2PLink(.delegate(newP2PAction)):
				switch newP2PAction {
				case let .newConnection(connectedClient):
					state.destination = nil
					return .run { _ in
						try await radixConnectClient.updateOrAddP2PLink(connectedClient)
					} catch: { error, _ in
						loggerGlobal.error("Failed P2PLink, error \(error)")
						errorQueue.schedule(error)
					}
				}

			default:
				return .none
			}
		}

		private func checkP2PLinkEffect() -> Effect<Action> {
			.run { send in
				for try await isConnected in await ledgerHardwareWalletClient.isConnectedToAnyConnectorExtension() {
					guard !Task.isCancelled else { return }
					await send(.internal(.hasAConnectorExtension(isConnected)))
				}
			} catch: { error, _ in
				loggerGlobal.error("failed to get links updates, error: \(error)")
			}
		}

		private func performActionRequiringP2PEffect(_ action: ActionRequiringP2P, in state: inout State) -> Effect<Action> {
			// If we don't have a connection, we remember what we were trying to do and then ask if they want to link one
			guard state.hasAConnectorExtension else {
				state.pendingAction = action
				state.destination = .noP2PLink(.noP2Plink)
				return .none
			}

			state.pendingAction = nil
			return .none
		}
	}
}

// MARK: - NoP2PLinkAlert
enum NoP2PLinkAlert: Sendable, Hashable {
	case addNewP2PLinkTapped
	case cancelTapped
}

extension AlertState<NoP2PLinkAlert> {
	static var noP2Plink: AlertState {
		AlertState {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.title)
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .addNewP2PLinkTapped) {
				TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.continue)
			}
		} message: {
			TextState(L10n.LedgerHardwareDevices.LinkConnectorAlert.message)
		}
	}
}

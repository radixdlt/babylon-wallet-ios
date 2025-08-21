// MARK: - ArculusForgotPIN-EnterNewPIN
extension ArculusForgotPIN {
	@Reducer
	struct EnterNewPIN: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let factorSource: ArculusCardFactorSource
			let mnemonic: Mnemonic
			var createPIN: ArculusCreatePIN.State = .init()
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case createPIN(ArculusCreatePIN.Action)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished
		}

		@Dependency(\.arculusCardClient) var arculusCardClient
		@Dependency(\.errorQueue) var errorQueue

		var body: some ReducerOf<Self> {
			Scope(state: \.createPIN, action: \.child.createPIN) {
				ArculusCreatePIN()
			}
			Reduce(core)
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .createPIN(.delegate(.pinAdded(pin))):
				.run { [mnemonic = state.mnemonic, factorSource = state.factorSource] send in
					try await arculusCardClient.restoreCardPin(factorSource, mnemonic, pin)
					await send(.delegate(.finished))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			default:
				.none
			}
		}
	}
}

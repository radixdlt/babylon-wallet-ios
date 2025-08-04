// MARK: - ArculusChangePIN-EnterNewPIN
extension ArculusChangePIN {
	@Reducer
	struct EnterNewPIN: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let factorSource: ArculusCardFactorSource
			let oldPIN: String

			var pinInput: ArculusPINInput.State = .init(shouldConfirmPIN: true)
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case pinAdded(String)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished
		}

		enum InternalAction: Sendable, Equatable {
			case pinConfigured
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case pinInput(ArculusPINInput.Action)
		}

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.overlayWindowClient) var overlayWindowClient

		var body: some ReducerOf<Self> {
			Scope(state: \.pinInput, action: \.child.pinInput) {
				ArculusPINInput()
			}

			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .pinAdded(pin):
				.run { [fs = state.factorSource, oldPIN = state.oldPIN] send in
					try await SargonOS.shared.setCardPin(factorSource: fs, oldPin: oldPIN, newPin: pin)
					await overlayWindowClient.scheduleHUD(.succeeded)
					await send(.delegate(.finished))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			}
		}
	}
}

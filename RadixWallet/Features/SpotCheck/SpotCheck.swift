// MARK: - SpotCheck
@Reducer
struct SpotCheck: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		var factorSourceAccess: FactorSourceAccess.State

		init(factorSource: FactorSource, allowSkip: Bool) {
			self.factorSourceAccess = .init(factorSource: factorSource, purpose: .spotCheck(allowSkip: allowSkip))
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	enum InternalAction: Hashable {
		case spotCheckSucceeded(FactorSourceID)
	}

	enum DelegateAction: Equatable {
		case cancelled
		case skipped
		case validated
	}

	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .factorSourceAccess(.delegate(.perform(factorSource))):
			perform(factorSource: factorSource)
		case .factorSourceAccess(.delegate(.skip)):
			.send(.delegate(.skipped))
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancelled))
		default:
			.none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .spotCheckSucceeded(factorSourceId):
			.send(.delegate(.validated))
				.merge(with: updateFactorSourceLastUsedEffect(factorSourceId: factorSourceId))
		}
	}
}

private extension SpotCheck {
	func perform(factorSource: PrivateFactorSource) -> Effect<Action> {
		.run { send in
			let input: SpotCheckInput
			switch factorSource {
			case let .device(_, mnemonicWithPassphrase):
				input = .software(mnemonicWithPassphrase: mnemonicWithPassphrase)

			case .ledger:
				let deviceInfo = try await ledgerHardwareWalletClient.getDeviceInfo()
				input = .ledger(id: deviceInfo.id)

			case let .offDeviceMnemonic(_, mnemonicWithPassphrase):
				input = .software(mnemonicWithPassphrase: mnemonicWithPassphrase)

			default:
				fatalError("Not supported")
			}
			if factorSource.factorSource.spotCheck(input: input) {
				await send(.internal(.spotCheckSucceeded(factorSource.factorSource.id)))
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

// MARK: - SpotCheck
@Reducer
struct SpotCheck: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var factorSourceAccess: FactorSourceAccess.State

		init(factorSource: FactorSource, allowSkip: Bool) {
			self.factorSourceAccess = .init(factorSource: factorSource, purpose: .spotCheck(allowSkip: allowSkip))
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case cancelled
		case skipped
		case validated
	}

	@Dependency(\.secureStorageClient) var secureStorageClient
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
}

private extension SpotCheck {
	func perform(factorSource: PrivateFactorSource) -> Effect<Action> {
		.run { send in
			let input: SpotCheckInput
			switch factorSource {
			case let .device(device):
				let mnemonicWithPassphrase = try loadMnemonic(id: device.id)
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
				await send(.delegate(.validated))
			}
		} catch: { error, send in
			await handleError(factorSource: factorSource, error: error, send: send)
		}
	}

	private func handleError(factorSource: PrivateFactorSource, error: Error, send: Send<SpotCheck.Action>) async {
		switch factorSource {
		case .device:
			if !error.isUserCanceledKeychainAccess {
				// If user cancelled the operation, we will allow them to retry.
				// In any other situation we handle the error.
				errorQueue.schedule(error)
			}

		default:
			errorQueue.schedule(error)
		}
	}

	private func loadMnemonic(id: FactorSourceIdFromHash) throws -> MnemonicWithPassphrase {
		guard let result = try secureStorageClient.loadMnemonic(factorSourceID: id, notifyIfMissing: false) else {
			throw CommonError.UnableToLoadMnemonicFromSecureStorage(badValue: id.toString())
		}
		return result
	}
}

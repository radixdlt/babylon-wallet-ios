
extension FeatureReducer {
	func exportMnemonic(
		controlling account: Profile.Network.Account,
		notifyIfMissing: Bool = true,
		onSuccess: (SimplePrivateFactorSource) -> Void
	) -> Effect<Action> {
		guard let txSigningFI = account.virtualHierarchicalDeterministicFactorInstances.first(where: { $0.factorSourceID.kind == .device }) else {
			loggerGlobal.notice("Discrepancy, non software account has not mnemonic to export")
			return .none
		}

		return exportMnemonic(
			factorSourceID: txSigningFI.factorSourceID,
			notifyIfMissing: notifyIfMissing,
			onSuccess: onSuccess
		)
	}

	func exportMnemonic(
		factorSourceID: FactorSource.ID.FromHash,
		notifyIfMissing: Bool = true,
		onSuccess: (SimplePrivateFactorSource) -> Void,
		onError: (Swift.Error) -> Void = { error in
			loggerGlobal.error("Failed to load mnemonic to export: \(error)")
		}
	) -> Effect<Action> {
		@Dependency(\.secureStorageClient) var secureStorageClient
		do {
			guard let mnemonicWithPassphrase = try secureStorageClient.loadMnemonic(
				factorSourceID: factorSourceID,
				purpose: .displaySeedPhrase,
				notifyIfMissing: notifyIfMissing
			) else {
				onError(FailedToFindFactorSource())
				return .none
			}

			onSuccess(
				.init(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSourceID: factorSourceID
				)
			)

		} catch {
			onError(error)
		}
		return .none
	}
}

extension ExportMnemonic.State {
	static func export(
		_ input: SimplePrivateFactorSource,
		title: String
	) -> Self {
		self.init(
			header: .init(
				title: title
			),
			warning: L10n.RevealSeedPhrase.warning,
			mnemonicWithPassphrase: input.mnemonicWithPassphrase,
			readonlyMode: .init(
				context: .fromSettings,
				factorSourceKind: input.factorSourceID.kind
			)
		)
	}
}

// MARK: - SimplePrivateFactorSource
struct SimplePrivateFactorSource: Sendable, Hashable {
	let mnemonicWithPassphrase: MnemonicWithPassphrase
	let factorSourceID: FactorSource.ID.FromHash
}

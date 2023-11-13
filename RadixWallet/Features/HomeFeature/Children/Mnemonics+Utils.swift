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

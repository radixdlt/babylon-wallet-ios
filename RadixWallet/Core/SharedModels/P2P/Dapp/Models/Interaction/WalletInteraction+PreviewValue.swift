// extension DappToWalletInteractionPersonaDataRequestItem {
//    public static let previewValue = .sample
// }

// extension P2P.Dapp.Request.SendTransactionItem {
//	public static let previewValue = try! Self(transactionManifest: .previewValue)
// }
//
extension WalletInteractionId {
	public static let previewValue = Self.previewValue0
	public static let previewValue0: Self = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue1: Self = "D621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue2: Self = "C621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue3: Self = "B621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue4: Self = "A621E1F8-C36C-495A-93FC-0C247A3E6E5F"
}

//
// extension DappToWalletInteractionMetadata {
//	public static let previewValue = try! Self(
//		version: P2P.Dapp.currentVersion,
//		networkId: .simulator,
//		origin: .init(string: "foo.bar"),
//		dAppDefinitionAddress: .init(validatingAddress: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p")
//	)
// }
//
extension DappToWalletInteraction {
	public static func previewValueAllRequests() -> Self {
		.init(
			interactionId: .previewValue0,
			items: .authorizedRequest(.init(
				auth: .loginWithChallenge(.init(challenge: .sample)),
				reset: nil,
				ongoingAccounts: nil,
				ongoingPersonaData: nil,
				oneTimeAccounts: nil,
				oneTimePersonaData: nil
			)),
			metadata: .init(version: .default, networkId: .sample, origin: .wallet, dappDefinitionAddress: .sample)
		)
	}
//
//	public static let previewValueOneTimeAccount = Self.previewValueOneTimeAccount()
//
//	public static func previewValueOneTimeAccount(
//		id: ID = .previewValue0
//	) -> Self {
//		.init(
//			id: id,
//			items: .request(
//				.unauthorized(.init(
//					oneTimeAccounts: .previewValue,
//					oneTimePersonaData: .previewValue
//				))
//			),
//			metadata: .previewValue
//		)
//	}
}

// #endif // DEBUG

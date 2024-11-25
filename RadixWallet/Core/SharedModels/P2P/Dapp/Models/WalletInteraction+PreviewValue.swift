#if DEBUG
extension WalletInteractionId {
	static let previewValue = Self.previewValue0
	static let previewValue0: Self = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	static let previewValue1: Self = "D621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	static let previewValue2: Self = "C621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	static let previewValue3: Self = "B621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	static let previewValue4: Self = "A621E1F8-C36C-495A-93FC-0C247A3E6E5F"
}

extension DappToWalletInteractionAccountsRequestItem {
	static let previewValue = Self(
		numberOfAccounts: .exactly(1),
		challenge: nil
	)
}

extension DappToWalletInteractionPersonaDataRequestItem {
	static let previewValue = Self(
		isRequestingName: true,
		numberOfRequestedEmailAddresses: nil,
		numberOfRequestedPhoneNumbers: nil
	)
}

extension DappToWalletInteractionMetadata {
	static let previewValue = Self(
		version: .default,
		networkId: .sample,
		origin: .wallet,
		dappDefinitionAddress: .sample
	)
}

extension DappToWalletInteraction {
	static func previewValueAllRequests() -> Self {
		.init(
			interactionId: .previewValue0,
			items: .authorizedRequest(.init(
				auth: .loginWithChallenge(.init(challenge: .sample)),
				reset: nil,
				ongoingAccounts: .previewValue,
				ongoingPersonaData: .previewValue,
				oneTimeAccounts: .previewValue,
				oneTimePersonaData: .previewValue,
				proofOfOwnership: nil
			)),
			metadata: .previewValue
		)
	}

	static let previewValueOneTimeAccount = Self.previewValueOneTimeAccount()

	static func previewValueOneTimeAccount(
		interactionId: WalletInteractionId = .previewValue0
	) -> Self {
		.init(
			interactionId: interactionId,
			items: .unauthorizedRequest(.init(
				oneTimeAccounts: .previewValue,
				oneTimePersonaData: .previewValue
			)),
			metadata: .previewValue
		)
	}
}
#endif // DEBUG

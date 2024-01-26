
#if DEBUG

extension TransactionManifest {
	public static let previewValue = try! TransactionManifest(instructions: .fromString(string: complexManifestString, networkId: NetworkID.mainnet.rawValue), blobs: [])
}

private let complexManifestString = """
# Withdraw XRD from account
      CALL_METHOD
         Address("account_rdx12xx2rxz5wtr98x6vxsulvqukawa2xt6te5ahmr50xavll3my4nzxdm")
         "lock_fee"
         Decimal("10");
"""

extension P2P.Dapp.Request.AccountsRequestItem {
	public static let previewValue = Self(
		numberOfAccounts: .exactly(1),
		challenge: nil
	)
}

extension P2P.Dapp.Request.PersonaDataRequestItem {
	public static let previewValue = Self(isRequestingName: true)
}

extension P2P.Dapp.Request.SendTransactionItem {
	public static let previewValue = try! Self(transactionManifest: .previewValue)
}

extension P2P.Dapp.Request.ID {
	public static let previewValue = Self.previewValue0
	public static let previewValue0: Self = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue1: Self = "D621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue2: Self = "C621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue3: Self = "B621E1F8-C36C-495A-93FC-0C247A3E6E5F"
	public static let previewValue4: Self = "A621E1F8-C36C-495A-93FC-0C247A3E6E5F"
}

extension P2P.Dapp.Request.Metadata {
	public static let previewValue = try! Self(
		version: P2P.Dapp.currentVersion,
		networkId: .simulator,
		origin: .init(string: "foo.bar"),
		dAppDefinitionAddress: .init(validatingAddress: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p")
	)
}

extension P2P.Dapp.Request {
	public static func previewValueAllRequests(
		auth: P2P.Dapp.Request.AuthRequestItem = .login(.withoutChallenge)
	) -> Self {
		.init(
			id: .previewValue0,
			items: .request(.authorized(.init(
				auth: auth,
				reset: nil,
				ongoingAccounts: .previewValue,
				ongoingPersonaData: .previewValue,
				oneTimeAccounts: .previewValue,
				oneTimePersonaData: .previewValue
			))),
			metadata: .previewValue
		)
	}

	public static let previewValueOneTimeAccount = Self.previewValueOneTimeAccount()

	public static func previewValueOneTimeAccount(
		id: ID = .previewValue0
	) -> Self {
		.init(
			id: id,
			items: .request(
				.unauthorized(.init(
					oneTimeAccounts: .previewValue,
					oneTimePersonaData: .previewValue
				))
			),
			metadata: .previewValue
		)
	}

	public static let previewValueSignTX = Self.previewValueSignTX()

	public static func previewValueSignTX(
		id: ID = .previewValue0
	) -> Self {
		.init(
			id: id,
			items: .transaction(.init(
				send: .previewValue
			)),
			metadata: .previewValue
		)
	}

	public static let previewValueNoRequestItems = Self(
		id: .previewValue,
		items: .request(.unauthorized(.init(
			oneTimeAccounts: nil,
			oneTimePersonaData: nil
		))),
		metadata: .previewValue
	)
}
#endif // DEBUG

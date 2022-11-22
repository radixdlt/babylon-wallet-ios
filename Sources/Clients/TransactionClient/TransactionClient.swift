import Dependencies
import EngineToolkit
import EngineToolkitClient
import Foundation
import struct GatewayAPI.GatewayAPIClient
import struct GatewayAPI.PollStrategy
import Profile
import ProfileClient

// MARK: - TransactionClient
public struct TransactionClient: DependencyKey {
	public var makeAccountNonVirtual: MakeAccountNonVirtual
	public var signTransaction: SignTransaction
	public init(
		makeAccountNonVirtual: @escaping MakeAccountNonVirtual,
		signTransaction: @escaping SignTransaction
	) {
		self.makeAccountNonVirtual = makeAccountNonVirtual
		self.signTransaction = signTransaction
	}
}

// MARK: TransactionClient.SignTransaction
public extension TransactionClient {
	typealias SignTransaction = @Sendable (TransactionManifest) async throws -> TransactionIntent.TXID
}

public extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

public extension TransactionClient {
	static var liveValue: Self {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.profileClient) var profileClient

		let pollStrategy: PollStrategy = .default

		return Self(
			makeAccountNonVirtual: { (_: CreateAccountRequest) -> MakeEntityNonVirtualBySubmittingItToLedger in
				{ privateKey in
					print("🎭 Create On-Ledger-Account ✨")
					let (committed, txID) = try await gatewayAPIClient.submit(
						pollStrategy: pollStrategy
					) { epoch in
						let buildAndSignTXRequest = BuildAndSignTransactionWithoutManifestRequest(
							privateKey: privateKey,
							epoch: epoch,
							networkID: profileClient.getCurrentNetworkID()
						)
						return try engineToolkitClient.createOnLedgerAccount(request: buildAndSignTXRequest)
					}
					guard let accountAddressBech32 = committed
						.details
						.referencedGlobalEntities
						.first
					else {
						throw CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities()
					}
					print("🎭 SUCCESSFULLY CREATED ACCOUNT On-Ledger with address: \(accountAddressBech32) ✅ \n txID: \(txID)")
					return try AccountAddress(address: accountAddressBech32)
				}
			},

			signTransaction: { _ in
				throw NSError(domain: "Transaction signing disabled until app is Hammunet compatible, once we have it we will use EngineToolkit to get required list of signers and sign.", code: 1337)
			}
		)
	}
}

#if DEBUG
extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		makeAccountNonVirtual: { _ in
			{ _ in
				try AccountAddress(address: "mock")
			}
		},
		signTransaction: { _ in "mock TXID" }
	)
}
#endif // DEBUG

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

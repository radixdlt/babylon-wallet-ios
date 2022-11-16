//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-15.
//

import Dependencies
import EngineToolkitClient
import Foundation
import GatewayAPI
import Profile
import ProfileClient

// MARK: - TransactionClient
public struct TransactionClient: DependencyKey {
	public var makeAccountNonVirtual: MakeAccountNonVirtual
	public init(makeAccountNonVirtual: @escaping MakeAccountNonVirtual) {
		self.makeAccountNonVirtual = makeAccountNonVirtual
	}
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

		return Self(makeAccountNonVirtual: { (_: CreateAccountRequest) -> MakeEntityNonVirtualBySubmittingItToLedger in

			let makeEntityNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger = { privateKey in

				print("🎭 Create On-Ledger-Account ✨")

				let (committed, txID) = try await gatewayAPIClient.submit(
					pollStrategy: pollStrategy
				) { epoch in

					let buildAndSignTXRequest = BuildAndSignTransactionWithoutManifestRequest(
						privateKey: privateKey,
						epoch: epoch,
						networkID: profileClient.getCurrentNetworkID()
					)

					return try engineToolkitClient.createAccount(request: buildAndSignTXRequest)
				}

				guard let accountAddressBech32 = committed
					.receipt
					.stateUpdates
					.newGlobalEntities
					.first?
					.globalAddress
				else {
					throw CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities()
				}

				print("🎭 SUCCESSFULLY CREATED ACCOUNT On-Ledger with address: \(accountAddressBech32) ✅ \n txID: \(txID)")

				return try AccountAddress(address: accountAddressBech32)
			}

			return makeEntityNonVirtualBySubmittingItToLedger
		}
		)
	}
}

// MARK: - CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities
struct CreateOnLedgerAccountFailedExpectedToFindAddressInNewGlobalEntities: Swift.Error {}

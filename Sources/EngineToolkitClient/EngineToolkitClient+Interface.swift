//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-25.
//

import Bite
import Common
import ComposableArchitecture
import EngineToolkit
import Foundation
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

public extension Nonce {
	static func secureRandom() -> Self {
		let byteCount = RawValue.bitWidth / 8
		var data = Data(repeating: 0, count: byteCount)
		data.withUnsafeMutableBytes {
			assert($0.count == byteCount)
			$0.initializeWithRandomBytes(count: byteCount)
		}
		let rawValue = data.withUnsafeBytes { $0.load(as: RawValue.self) }
		return Self(rawValue: rawValue)
	}
}

// MARK: - AlphanetAddresses
public enum AlphanetAddresses {}
public extension AlphanetAddresses {
	static let faucet: ComponentAddress = "system_tdx_a_1qsqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs2ufe42"
	static let createAccountComponent: PackageAddress = "package_tdx_a_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqps373guw"
	static let xrd: ResourceAddress = "resource_tdx_a_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqegh4k9"
}

// MARK: - EngineToolkitClient
public struct EngineToolkitClient {
	public var buildTransactionForCreateOnLedgerAccount: BuildTransactionForCreateOnLedgerAccount
}

// MARK: EngineToolkitClient.BuildTransactionForCreateOnLedgerAccount
public extension EngineToolkitClient {
	// FIXME: what is the signature?
	typealias BuildTransactionForCreateOnLedgerAccount = @Sendable (BuildTransactionForCreateOnLedgerAccountRequest) throws -> NotarizedSignedTransctionContext
}

// MARK: - BuildTransactionForCreateOnLedgerAccountRequest
public struct BuildTransactionForCreateOnLedgerAccountRequest: Sendable {
	public let privateKey: PrivateKey
	public let transactionHeaderInput: TransactionHeaderInput
	public init(
		privateKey: PrivateKey,
		epoch: Epoch,
		networkID: NetworkID,
		costUnitLimit: UInt32 = TransactionHeaderInput.defaultCostUnitLimit
	) {
		self.privateKey = privateKey
		self.transactionHeaderInput = .init(
			publicKey: privateKey.publicKey(),
			startEpoch: epoch,
			networkID: networkID,
			costUnitLimit: costUnitLimit
		)
	}
}

// MARK: - TransactionHeaderInput
public struct TransactionHeaderInput: Sendable {
	public static let defaultCostUnitLimit: UInt32 = 10_000_000
	public let publicKey: PublicKey

	/// Fetch from GatewayAPI
	public let startEpoch: Epoch

	public let networkID: NetworkID
	public let costUnitLimit: UInt32
	public init(
		publicKey: PublicKey,
		startEpoch: Epoch,
		networkID: NetworkID,
		costUnitLimit: UInt32 = Self.defaultCostUnitLimit
	) {
		self.publicKey = publicKey
		self.startEpoch = startEpoch
		self.networkID = networkID
		self.costUnitLimit = costUnitLimit
	}

	public func header(
		epochDuration: Epoch = 2,
		version: Version = 1,
		nonce: @autoclosure () -> Nonce = Nonce.secureRandom(),
		notaryAsSignatory: Bool = true
	) throws -> TransactionHeader {
		try .init(
			version: version,
			networkId: self.networkID,
			startEpochInclusive: startEpoch,
			endEpochExclusive: startEpoch + epochDuration,
			nonce: nonce(),
			publicKey: publicKey.intoEngine(),
			notaryAsSignatory: notaryAsSignatory,
			costUnitLimit: costUnitLimit,
			tipPercentage: 0
		)
	}
}

public extension EngineToolkitClient {
	static let live: Self = .init(buildTransactionForCreateOnLedgerAccount: { request in
		let privateKey = request.privateKey

		let engineToolkit = EngineToolkit()
		let nonFungibleAddress = try engineToolkit.deriveNonFungibleAddressFromPublicKeyRequest(
			request: privateKey.publicKey().intoEngine()
		)
		.get()
		.nonFungibleAddress

		let transactionManifest = TransactionManifest {
			CallMethod(
				componentAddress: AlphanetAddresses.faucet,
				methodName: "lock_fee"
			) {
				Decimal_(10.0)
			}

			CallMethod(
				componentAddress: AlphanetAddresses.faucet,
				methodName: "free_xrd"
			)

			let xrdBucket: Bucket = "xrd"

			TakeFromWorktop(resourceAddress: AlphanetAddresses.xrd, bucket: xrdBucket)

			CallFunction(
				packageAddress: AlphanetAddresses.createAccountComponent,
				blueprintName: "Account",
				functionName: "new_with_resource"
			) {
				Enum("Protected") {
					Enum("ProofRule") {
						Enum("Require") {
							Enum("StaticNonFungible") {
								nonFungibleAddress
							}
						}
					}
				}
				xrdBucket
			}
		}

		let header = try request.transactionHeaderInput.header()

		let notarizedTXContext = try transactionManifest
			.header(header)
			.notarize(privateKey)

//		let signedTransactionIntent = SignedTransactionIntent(
//			intent: notarized.signedIntent.intent,
//			intentSignatures: notarized.signedIntent.intentSignatures
//		)
//
//
//		let compiledSignedTransactionIntent = try engineToolkit.compileSignedTransactionIntentRequest(request: signedTransactionIntent).get()

//		return compiledSignedTransactionIntent
		return notarizedTXContext
	})
}

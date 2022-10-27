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
import CryptoKit

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
	public var signTransactionIntent: SignTransactionIntent
	public init(signTransactionIntent: @escaping SignTransactionIntent) {
		self.signTransactionIntent = signTransactionIntent
	}
}

public struct SignedCompiledNotarizedTX: Sendable, Hashable {
	public let compileTransactionIntentResponse: CompileTransactionIntentResponse
	public let intentHash: Data
	public let compileNotarizedTransactionIntentResponse: CompileNotarizedTransactionIntentResponse
}

// MARK: EngineToolkitClient.BuildTransactionForCreateOnLedgerAccount
public extension EngineToolkitClient {
	typealias SignTransactionIntent = @Sendable (SignTransactionIntentRequest) throws -> SignedCompiledNotarizedTX
}

struct NonMatchingPrivateAnPublicKeys: Swift.Error {}

// MARK: - SignTransactionIntentRequest
public struct SignTransactionIntentRequest: Sendable {
	public let transactionIntent: TransactionIntent
	public let privateKey: PrivateKey
	
	public init(transactionIntent: TransactionIntent, privateKey: PrivateKey) throws {
		guard try transactionIntent.header.publicKey == privateKey.publicKey().intoEngine() else {
			throw NonMatchingPrivateAnPublicKeys()
		}
		self.transactionIntent = transactionIntent
		self.privateKey = privateKey
	}
}
public extension SignTransactionIntentRequest {
	init(
		manifest: TransactionManifest,
		header: TransactionHeader,
		privateKey: PrivateKey
	) throws {
		try self.init(
			transactionIntent: .init(
				header: header,
				manifest: manifest
			),
			privateKey: privateKey
		)
	}
	
	init(
		manifest: TransactionManifest,
		headerInput: TransactionHeaderInput,
		privateKey: PrivateKey
	) throws {
		try self.init(
			transactionIntent: .init(
				header: headerInput.header(),
				manifest: manifest
			),
			privateKey: privateKey
		)
	}
	
	init(
		manifest: TransactionManifest,
		privateKey: PrivateKey,
		epoch: Epoch,
		networkID: NetworkID,
		costUnitLimit: UInt32 = TransactionHeaderInput.defaultCostUnitLimit
	) throws {
		let headerInput = TransactionHeaderInput(
			publicKey: privateKey.publicKey(),
			startEpoch: epoch,
			networkID: networkID
		)
		try self.init(
			manifest: manifest,
			headerInput: headerInput,
			privateKey: privateKey
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
	static let live: Self = .init(signTransactionIntent: { request in
		let engineToolkit = EngineToolkit()

		let privateKey = request.privateKey
		let transactionIntent = request.transactionIntent

		let compiledTransactionIntent = try engineToolkit.compileTransactionIntentRequest(request: transactionIntent).get()
		let transactionIntentWithSignatures = SignedTransactionIntent(intent: transactionIntent, intentSignatures: [])
		let forNotarySignerToSign = try engineToolkit.compileSignedTransactionIntentRequest(request: transactionIntentWithSignatures).get()
		let (signedCompiledSignedTXIntent, forNotarySignerToSignHash) = try privateKey.signReturningHashOfMessage(data: forNotarySignerToSign.compiledSignedIntent)
		let notarizedTX = try NotarizedTransaction(
			signedIntent: transactionIntentWithSignatures,
			notarySignature: signedCompiledSignedTXIntent.intoEngine().signature
		)
		let notarizedTransactionIntent = try engineToolkit.compileNotarizedTransactionIntentRequest(request: notarizedTX).get()

		let intentHash = Data(SHA256.twice(data: Data(compiledTransactionIntent.compiledIntent)))
		
		return .init(
			compileTransactionIntentResponse: compiledTransactionIntent,
			intentHash: intentHash,
			compileNotarizedTransactionIntentResponse: notarizedTransactionIntent)

	})
}

public extension EngineToolkitClient {
	func createAccount(request: BuildAndSignTransactionRequest) throws -> SignedCompiledNotarizedTX {
		let privateKey = request.privateKey
		let headerInput = request.transactionHeaderInput
		
		let engineToolkit = EngineToolkit()
		let nonFungibleAddress = try engineToolkit.deriveNonFungibleAddressFromPublicKeyRequest(
			request: privateKey.publicKey().intoEngine()
		)
		.get()
		.nonFungibleAddress

		let manifest = TransactionManifest {
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
		
		let signTXRequest = try SignTransactionIntentRequest(
			manifest: manifest,
			headerInput: headerInput,
			privateKey: privateKey
		)

		return try signTransactionIntent(signTXRequest)
		
	}
}

// MARK: - BuildAndSignTransactionRequest
public struct BuildAndSignTransactionRequest: Sendable {
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

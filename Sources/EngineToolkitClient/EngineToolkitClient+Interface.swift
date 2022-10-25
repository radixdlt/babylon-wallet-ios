//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-25.
//

import ComposableArchitecture
import EngineToolkit
import Foundation
import Profile
import SLIP10

// MARK: - AlphanetAddresses
public enum AlphanetAddresses {}
public extension AlphanetAddresses {
	static let faucet: ComponentAddress = "system_tdx_a_1qsqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs2ufe42"
	static let createAccountComponent = "package_tdx_a_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqps373guw"
	static let xrd = "resource_tdx_a_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqegh4k9"
}

// MARK: - EngineToolkitClient
public struct EngineToolkitClient {
	public var buildTransactionForCreateOnLedgerAccount: BuildTransactionForCreateOnLedgerAccount
}

// MARK: EngineToolkitClient.BuildTransactionForCreateOnLedgerAccount
public extension EngineToolkitClient {
	// FIXME: what is the signature?
	typealias BuildTransactionForCreateOnLedgerAccount = @Sendable (PrivateKey) throws -> SignedTransactionIntent
}

public extension EngineToolkitClient {
	static let live: Self = .init(buildTransactionForCreateOnLedgerAccount: { _ in
		//            TransactionManifest {
		//                CallMethod(
		//                    componentAddress: AlphanetAddresses.faucet,
		//                    methodName: "lock_fee"
		//                ) {
		//                    Decimal_(10.0)
		//                }
		//            }
		fatalError()
	})
}

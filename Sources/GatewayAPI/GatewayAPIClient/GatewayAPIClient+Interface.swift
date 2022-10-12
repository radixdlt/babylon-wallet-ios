//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-10-11.
//

import Foundation
import Profile
import CryptoKit
import Common

public typealias AccountAddress = Profile.Account.Address
public typealias ResourceIdentifier = String


public struct GatewayAPIClient {
    public var accountResourcesByAddress: GetAccountResourcesByAddress
    public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
    public var submitTransaction: SubmitTransaction
    public var transactionStatus: GetTransactionStatus
    
    init(
        accountResourcesByAddress: @escaping GetAccountResourcesByAddress,
        resourceDetailsByResourceIdentifier: @escaping GetResourceDetailsByResourceIdentifier,
        submitTransaction: @escaping SubmitTransaction,
        transactionStatus: @escaping GetTransactionStatus
    ) {
        self.accountResourcesByAddress = accountResourcesByAddress
        self.resourceDetailsByResourceIdentifier = resourceDetailsByResourceIdentifier
        self.submitTransaction = submitTransaction
        self.transactionStatus = transactionStatus
    }
}


public extension GatewayAPIClient {
    typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> EntityResourcesResponse
    typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> EntityDetailsResponseDetails
    typealias SubmitTransaction = @Sendable (TransactionSubmitRequest) async throws -> TransactionSubmitResponse
    typealias GetTransactionStatus = @Sendable (TransactionStatusRequest) async throws -> TransactionStatusResponse
}


extension Date: @unchecked Sendable {}

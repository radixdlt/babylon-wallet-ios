//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-10-22.
//

import Foundation

public struct GetTokenDetailsRequest: Sendable, Encodable, Hashable {
    public let resourceAddress: String
}

public extension GetTokenDetailsRequest {
    enum CodingKeys: String, CodingKey {
        case resourceAddress = "resource_address"
    }
}

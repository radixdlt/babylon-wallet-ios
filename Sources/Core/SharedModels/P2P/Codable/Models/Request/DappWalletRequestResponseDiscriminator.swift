//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Foundation

internal extension P2P.FromDapp {
	// Used by Responses and Requests
	enum Discriminator: String, Codable {
		case ongoingAccountAddresses
		case signTransaction = "sendTransaction"
	}
}

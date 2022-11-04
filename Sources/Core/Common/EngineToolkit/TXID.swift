//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-04.
//

import EngineToolkit
import Foundation
import Tagged

// MARK: - TransactionIntent.TXID
public extension TransactionIntent {
	// Move to EngineToolkit?
	typealias TXID = Tagged<Self, String>
}

public typealias TXID = TransactionIntent.TXID

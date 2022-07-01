//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Foundation

public struct Profile: Equatable {
	public let name: String
	public init(name: String = "Unnamed") {
		self.name = name
	}
}

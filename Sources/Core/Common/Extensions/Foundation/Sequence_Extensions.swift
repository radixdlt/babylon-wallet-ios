//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-03.
//

import Foundation

public extension Sequence {
	func asyncMap<T>(
		_ transform: (Element) async throws -> T
	) async rethrows -> [T] {
		var values = [T]()

		for element in self {
			try await values.append(transform(element))
		}

		return values
	}
}

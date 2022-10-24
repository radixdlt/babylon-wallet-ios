//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-24.
//

import Foundation

// MARK: ImportProfile.State
public extension ImportProfile {
	struct State: Equatable {
		public var isDisplayingFileImporter = false

		public init(
			isDisplayingFileImporter: Bool = false
		) {
			self.isDisplayingFileImporter = isDisplayingFileImporter
		}
	}
}

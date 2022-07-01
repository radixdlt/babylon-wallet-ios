//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Profile

public struct Wallet: Equatable {
	private let profile: Profile
	public init(
		profile: Profile
	) {
		self.profile = profile
	}
}

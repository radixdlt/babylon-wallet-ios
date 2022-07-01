//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import Foundation

public extension String {
	var hexData: Data {
		try! Data(hex: self)
	}
}

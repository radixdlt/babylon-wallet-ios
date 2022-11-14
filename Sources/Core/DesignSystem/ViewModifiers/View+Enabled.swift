//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-14.
//

import Foundation
import SwiftUI

public extension View {
	func enabled(_ enabled: @autoclosure () -> Bool) -> some View {
		disabled(!enabled())
	}
}

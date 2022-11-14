//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-14.
//

import SwiftUI

// MARK: - PrimaryButtonStyle
public struct PrimaryButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled: Bool
	public func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.app.body1Header)
			.frame(maxWidth: .infinity)
			.frame(height: 50)
			.if(configuration.role == nil) { label in
				label
					.foregroundColor(.app.white)
					.background(isEnabled ? Color.app.blue2 : Color.app.gray4)
			}
			.cornerRadius(8)
	}
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
	static var primary: Self { Self() }
}

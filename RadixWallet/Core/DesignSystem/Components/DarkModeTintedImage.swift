//
//  DarkModeTintedImage.swift
//  RadixWallet
//
//  Created by Ghenadie VP on 13.05.2025.
//
import SwiftUI

extension Image {
	@MainActor
	func darkModeTinted() -> some View {
		DarkModeTintedImageModifier(image: self)
	}
}

// MARK: - DarkModeTintedImageModifier
struct DarkModeTintedImageModifier: View {
	@Environment(\.colorScheme) var colorScheme
	var image: Image

	var body: some View {
		image
			.renderingMode(colorScheme == .light ? .original : .template)
			.tint(colorScheme == .dark ? .iconPrimary : nil)
	}
}

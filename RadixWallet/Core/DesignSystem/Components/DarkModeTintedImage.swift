//
//  DarkModeTintedImage.swift
//  RadixWallet
//
//  Created by Ghenadie VP on 13.05.2025.
//
import SwiftUI

extension Image {
	@MainActor @ViewBuilder
	func darkModeTinted() -> some View {
		DarkModeTintedImageModifier(image: self)
	}
}

// MARK: - DarkModeTintedImageModifier
struct DarkModeTintedImageModifier: View {
	@Environment(\.colorScheme) var colorScheme
	var image: Image

	init(image: Image) {
		self.image = image
	}

	var body: some View {
		image
			.renderingMode(colorScheme == .light ? .original : .template)
			.tint(colorScheme == .dark ? .iconPrimary : nil)
	}
}

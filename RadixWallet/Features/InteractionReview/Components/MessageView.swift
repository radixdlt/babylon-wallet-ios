//
//  MessageView.swift
//  RadixWallet
//
//  Created by Ghenadie VP on 16.11.2025.
//
import SwiftUI

extension InteractionReview {
	// MARK: - TransactionMessageView
	struct TransactionMessageView: View {
		let message: String

		var body: some View {
			Speechbubble {
				Text(message)
					.message
					.flushedLeft
					.padding(.horizontal, .medium3)
					.padding(.vertical, .small1)
			}
		}
	}
}

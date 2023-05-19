import Prelude
import Resources
import SharedModels
import SwiftUI

public struct UseLedgerView: SwiftUI.View {
	public enum Purpose: Sendable, Hashable {
		case createAccount
		case createAuthSigningKey
	}

	public let id: String
	public let name: String
	public let model: String
	public let lastUsed: Date
	public let addedOn: Date

	init(
		purpose: Purpose,
		id: String,
		name: String,
		model: String,
		lastUsed: Date,
		addedOn: Date
	) {
		self.id = id
		self.name = name
		self.model = model
		self.lastUsed = lastUsed
		self.addedOn = addedOn
	}

	public var body: some View {
		VStack {
			Text("")
		}
	}
}

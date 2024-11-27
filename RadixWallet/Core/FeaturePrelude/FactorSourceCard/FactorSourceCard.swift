import Sargon
import SwiftUI

// MARK: - FactorSourceCard
struct FactorSourceCard: View {
	private let kind: Kind
	private let mode: Mode
	private let dataSource: FactorSourceCardDataSource
	private var isExpanded: Bool

	var onRemoveTapped: (() -> Void)? = nil

	var body: some View {
		switch mode {
		case .display, .selection:
			card
		case .removal:
			HStack {
				card

				Button {
					onRemoveTapped?()
				} label: {
					Image(asset: AssetResource.close)
						.frame(.smallest)
				}
				.foregroundColor(.app.gray2)
			}
		}
	}

	private var card: some View {
		VStack(spacing: 0) {
			topCard
				.padding(.horizontal, .medium3)
				.padding(.vertical, .medium2)

			if !dataSource.messages.isEmpty {
				VStack(alignment: .leading, spacing: .small2) {
					ForEach(dataSource.messages) { message in
						StatusMessageView(
							text: message.text,
							type: message.type,
							useNarrowSpacing: true,
							useSmallerFontSize: true
						)
					}
				}
				.padding(.horizontal, .large3)
				.padding(.bottom, .medium1)
			}

			if dataSource.hasAccountsOrPersonas {
				LinkedEntitesView(
					isExpanded: isExpanded,
					accounts: dataSource.accounts,
					personas: dataSource.personas
				)
			}
		}
		.background(.app.white)
		.roundedCorners(radius: .small1)
		.tokenRowShadow()
	}

	private var topCard: some View {
		HStack(spacing: .medium3) {
			Image(dataSource.icon)

			VStack(alignment: .leading, spacing: .small3) {
				Text(dataSource.title)
					.textStyle(.body1Header)
					.foregroundStyle(.app.gray1)

				if let subtitle = dataSource.subtitle {
					Text(subtitle)
						.textStyle(.body2Regular)
						.foregroundStyle(.app.gray2)
				}

				if let lastUsedOn = dataSource.lastUsedOn {
					Text(
						markdown: "**Last Used:** \(RadixDateFormatter.string(from: lastUsedOn, dateStyle: .long))",
						emphasizedColor: .app.gray2,
						emphasizedFont: .app.body2Link
					)
					.textStyle(.body2Regular)
					.foregroundStyle(.app.gray2)
				}
			}
			.flushedLeft

			if case let .selection(type, isSelected) = mode {
				switch type {
				case .radioButton:
					RadioButton(
						appearance: .dark,
						state: isSelected ? .selected : .unselected
					)
				case .checkmark:
					CheckmarkView(appearance: .dark, isChecked: isSelected)
				}
			}
		}
	}

	struct LinkedEntitesView: SwiftUI.View {
		@SwiftUI.State var isExpanded: Bool = false
		let accounts: [Account]
		let personas: [Persona]

		var body: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium2) {
				Button {
					withAnimation(.default) {
						isExpanded.toggle()
					}
				} label: {
					HStack(spacing: .zero) {
						Text("Linked to \(accounts.count) Accounts and \(personas.count) Personas")
							.textStyle(.body2Regular)
							.foregroundStyle(.app.gray2)

						Spacer(minLength: 0)

						Image(isExpanded ? .chevronUp : .chevronDown)
							.renderingMode(.original)
					}
				}

				if isExpanded {
					VStack(spacing: .small2) {
						ForEach(accounts) { account in
							AccountCard(kind: .compact, account: account)
						}

						ForEach(personas) { persona in
							Card {
								PlainListRow(
									context: .compactPersona,
									title: persona.displayName.value,
									accessory: nil
								) {
									Thumbnail(.persona, url: nil)
								}
							}
						}
					}
				}
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .small1)
			.background(.app.gray5)
		}
	}
}

extension FactorSourceCard {
	init?(
		kind: Kind,
		mode: Mode,
		messages: [FactorSourceCardDataSource.Message] = [],
		isExpanded: Bool = false
	) {
		guard
			let icon = kind.factorSourceKind.icon,
			let title = kind.title
		else { return nil }

		switch kind {
		case let .genericDescription(factorSourceKind):
			guard let details = factorSourceKind.details else { return nil }

			self = .init(
				kind: kind,
				mode: mode,
				dataSource: .init(
					icon: icon,
					title: title,
					subtitle: details,
					messages: messages
				),
				isExpanded: isExpanded
			)
		case let .instanceCompact(factorSource):
			guard let name = factorSource.name else { return nil }

			self = .init(
				kind: kind,
				mode: mode,
				dataSource: .init(
					icon: icon,
					title: name,
					messages: messages
				),
				isExpanded: isExpanded
			)
		case let .instanceRegular(factorSource):
			guard
				let name = factorSource.name,
				let details = factorSource.factorSourceKind.details
			else { return nil }

			self = .init(
				kind: kind,
				mode: mode,
				dataSource: .init(
					icon: icon,
					title: name,
					subtitle: details,
					messages: messages
				),
				isExpanded: isExpanded
			)
		case let .instanceLastUsed(factorSource, accounts, personas):
			guard let name = factorSource.name else { return nil }

			self = .init(
				kind: kind,
				mode: mode,
				dataSource: .init(
					icon: icon,
					title: name,
					lastUsedOn: factorSource.common.lastUsedOn,
					messages: messages,
					accounts: accounts,
					personas: personas
				),
				isExpanded: isExpanded
			)
		}
	}
}

extension FactorSourceCard {
	enum Kind {
		case genericDescription(FactorSourceKind)
		case instanceCompact(factorSource: FactorSource)
		case instanceRegular(factorSource: FactorSource)
		case instanceLastUsed(
			factorSource: FactorSource,
			accounts: [Account] = [],
			personas: [Persona] = []
		)
	}

	enum Mode {
		case display
		case selection(type: SelectionType, isSelected: Bool)
		case removal
	}

	enum SelectionType {
		case radioButton
		case checkmark
	}
}

extension FactorSourceCard.Kind {
	var factorSourceKind: FactorSourceKind {
		switch self {
		case let .genericDescription(factorSourceKind):
			factorSourceKind
		case let .instanceCompact(factorSource),
		     let .instanceRegular(factorSource),
		     let .instanceLastUsed(factorSource, _, _):
			factorSource.factorSourceKind
		}
	}

	var title: String? {
		switch self {
		case let .genericDescription(factorSourceKind):
			factorSourceKind.title
		case let .instanceCompact(factorSource),
		     let .instanceRegular(factorSource),
		     let .instanceLastUsed(factorSource, _, _):
			factorSource.name
		}
	}
}

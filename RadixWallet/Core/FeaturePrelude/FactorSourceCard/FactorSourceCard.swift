import Sargon
import SwiftUI

// MARK: - FactorSourceCard
struct FactorSourceCard: View {
	@Environment(\.colorScheme) private var colorScheme
	private let kind: Kind
	private let mode: Mode
	private let dataSource: FactorSourceCardDataSource
	private var isExpanded: Bool

	var onAction: ((Action) -> Void)? = nil

	var body: some View {
		switch mode {
		case .display, .selection:
			card
		case .removal:
			HStack {
				card

				Button {
					onAction?(.removeTapped)
				} label: {
					Image(asset: AssetResource.close)
						.frame(.smallest)
				}
				.foregroundColor(.secondaryText)
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
						.onTapGesture {
							onAction?(.messageTapped)
						}
					}
				}
				.flushedLeft
				.padding(.horizontal, .large3)
				.padding(.bottom, .medium1)
			}

			if let linkedEntities = dataSource.linkedEntities, !linkedEntities.isEmpty {
				LinkedEntitesView(
					isExpanded: isExpanded,
					dataSource: linkedEntities
				)
			}
		}
		.background(.primaryBackground)
		.roundedCorners(radius: .small1)
		.cardShadow
		.animation(.default, value: dataSource.messages.count)
	}

	private var topCard: some View {
		HStack(spacing: .medium3) {
			Image(dataSource.icon)
				.resizable()
				.frame(.smallest)

			VStack(alignment: .leading, spacing: .small3) {
				Text(dataSource.title)
					.textStyle(.body1Header)
					.foregroundStyle(.primaryText)

				if let subtitle = dataSource.subtitle {
					Text(subtitle)
						.textStyle(.body2Regular)
						.foregroundStyle(.secondaryText)
				}

				if let lastUsedOn = dataSource.lastUsedOn {
					Text(
						markdown: L10n.FactorSources.Card.lastUsed(RadixDateFormatter.string(from: lastUsedOn, dateStyle: .long)),
						emphasizedColor: .secondaryText,
						emphasizedFont: .app.body2Link
					)
					.textStyle(.body2Regular)
					.foregroundStyle(.secondaryText)
				}
			}
			.flushedLeft

			if case let .selection(type, isSelected) = mode {
				switch type {
				case .radioButton:
					RadioButton(
						appearance: colorScheme == .light ? .dark : .light,
						isSelected: isSelected
					)
				case .checkmark:
					CheckmarkView(
						appearance: colorScheme == .light ? .dark : .light,
						isChecked: isSelected
					)
				}
			}
		}
	}

	struct LinkedEntitesView: SwiftUI.View {
		@SwiftUI.State var isExpanded: Bool = false
		let dataSource: FactorSourceCardDataSource.LinkedEntities

		var body: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium2) {
				Button {
					withAnimation(.default) {
						isExpanded.toggle()
					}
				} label: {
					HStack(spacing: .zero) {
						Text(linkedTitle)
							.textStyle(.body2Regular)
							.foregroundStyle(.secondaryText)

						Spacer(minLength: 0)

						Image(isExpanded ? .chevronUp : .chevronDown)
							.renderingMode(.original)
					}
				}

				if isExpanded {
					VStack(spacing: .small2) {
						ForEach(dataSource.accounts) { account in
							AccountCard(kind: .display, account: account)
						}

						ForEach(dataSource.personas) { persona in
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

						if dataSource.hasHiddenEntities {
							Text(L10n.Common.hiddenAccountsOrPersonas)
								.textStyle(.body1HighImportance)
								.foregroundStyle(.secondaryText)
								.frame(maxWidth: .infinity)
								.padding(.small1)
								.background(.primaryBackground)
								.cornerRadius(.small1)
						}
					}
				}
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .small1)
			.background(.cardBackgroundSecondary)
		}

		private var linkedTitle: String {
			typealias Card = L10n.FactorSources.Card
			let accountsCount = dataSource.accounts.count
			let personasCount = dataSource.personas.count
			let hasHiddenEntities = dataSource.hasHiddenEntities
			let accountsString = accountsCount == 1 ? Card.accountSingular : Card.accountPlural(accountsCount)
			let personasString = personasCount == 1 ? Card.personaSingular : Card.personaPlural(personasCount)

			if accountsCount > 0, personasCount > 0 {
				return hasHiddenEntities ? Card.linkedAccountsAndPersonasSomeHidden(accountsString, personasString) : Card.linkedAccountsAndPersonas(accountsString, personasString)
			} else if accountsCount > 0 {
				return hasHiddenEntities ? Card.linkedAccountsOrPersonasSomeHidden(accountsString) : Card.linkedAccountsOrPersonas(accountsString)
			} else if personasCount > 0 {
				return hasHiddenEntities ? Card.linkedAccountsOrPersonasSomeHidden(personasString) : Card.linkedAccountsOrPersonas(personasString)
			} else if hasHiddenEntities {
				return Card.linkedAccountsAndPersonasSomeHidden(accountsString, personasString)
			}
			return ""
		}
	}
}

extension FactorSourceCard {
	init(
		kind: Kind,
		mode: Mode,
		messages: [FactorSourceCardDataSource.Message] = [],
		isExpanded: Bool = false,
		onAction: ((Action) -> Void)? = nil
	) {
		switch kind {
		case let .genericDescription(factorSourceKind):
			self = .init(
				kind: kind,
				mode: mode,
				dataSource: .init(
					icon: factorSourceKind.icon,
					title: factorSourceKind.title,
					subtitle: factorSourceKind.details,
					messages: messages
				),
				isExpanded: isExpanded,
				onAction: onAction
			)
		case let .instance(factorSource, instanceKind):
			switch instanceKind {
			case let .short(showDetails):
				self = .init(
					kind: kind,
					mode: mode,
					dataSource: .init(
						icon: kind.factorSourceKind.icon,
						title: factorSource.name,
						subtitle: showDetails ? factorSource.factorSourceKind.details : nil,
						messages: messages
					),
					isExpanded: isExpanded,
					onAction: onAction
				)
			case let .extended(linkedEntities):
				self = .init(
					kind: kind,
					mode: mode,
					dataSource: .init(
						icon: kind.factorSourceKind.icon,
						title: factorSource.name,
						lastUsedOn: factorSource.common.lastUsedOn,
						messages: messages,
						linkedEntities: linkedEntities
					),
					isExpanded: isExpanded,
					onAction: onAction
				)
			}
		}
	}
}

extension FactorSourceCard {
	enum Kind {
		case genericDescription(FactorSourceKind)
		case instance(factorSource: FactorSource, kind: InstanceKind)

		enum InstanceKind {
			case short(showDetails: Bool)
			case extended(linkedEntities: FactorSourceCardDataSource.LinkedEntities)
		}
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

	enum Action {
		case removeTapped
		case messageTapped
	}
}

extension FactorSourceCard.Kind {
	var factorSourceKind: FactorSourceKind {
		switch self {
		case let .genericDescription(factorSourceKind):
			factorSourceKind
		case let .instance(factorSource, _):
			factorSource.factorSourceKind
		}
	}

	var title: String {
		switch self {
		case let .genericDescription(factorSourceKind):
			factorSourceKind.title
		case let .instance(factorSource, _):
			factorSource.name
		}
	}
}

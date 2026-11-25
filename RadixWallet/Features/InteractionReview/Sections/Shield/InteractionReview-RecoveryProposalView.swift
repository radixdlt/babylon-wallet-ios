import Sargon
import SwiftUI

// Shows an access controller operation on an account that belongs to none of
// the user's entities, e.g. a shared account: the account, then the rules of
// its three roles, if the operation sets them.
//
// Every shape of `AccessRequirementForDisplay` maps to one building block:
// * a list of badges gets a header: "Any of these", "Any 2 of these 3",
//   "All of these";
// * ways are cards joined by an OR pill;
// * parts of a way are joined by an AND pill, like the OR pill;
// * a group joined by AND to other parts of a way is boxed;
// * anything deeper is a summary row that opens a sheet.
//
// The user's factors are factor source cards; other keys have a dashed outline;
// resources and NFTs, which anyone holding them passes, a solid one and a
// "Transferable" tag. Every badge but the user's factors shows its address.

// MARK: - InteractionReview.ControlOperation
extension InteractionReview {
	/// An access controller operation on one access controller that belongs to
	/// none of the user's entities, e.g. a shared account: the account, what
	/// the operation does, one effect per row, and the rules, when it sets or
	/// stops a change of them.
	struct ControlOperation: Hashable {
		enum Heading: Hashable {
			case updateAccountControl, recoveryFees, createAccount, createPersona
		}

		/// One thing the operation does, shown as an icon and a short line.
		struct Effect: Hashable {
			enum Icon: Hashable {
				case applied, timed, stop, cancel, lock, unlock, created, proposer
			}

			let icon: Icon
			let text: String
		}

		var heading: Heading = .updateAccountControl
		/// The access controller operated on, `nil` for one the manifest creates.
		let accessController: AccessControllerAddress?
		let controlledEntity: AddressOfAccountOrPersona?
		/// Whether the manifest creates the entity, whose address is then only
		/// the preview's, so it isn't shown.
		var createsEntity = false
		var effects: [Effect] = []
		var rules: AccessControllerRuleSetForDisplay? = nil
		/// The heading of the rules' own section: what the rules are to this
		/// operation.
		var rulesHeading = "New rules"
		/// The controlled account as the review draws accounts: the user's own
		/// when it is in the Profile, else external. Resolved when the sections
		/// are built; `nil` until then, or when it isn't an account.
		var controlledAccount: InteractionReview.ReviewAccount? = nil
	}
}

extension InteractionReview.ControlOperation {
	/// Proposed and confirmed together. The access controller keeps its
	/// current delay under the new rules, so that is the one shown.
	init(recovery proposal: AccessControllerRecoveryProposal) {
		self.init(
			accessController: proposal.accessController,
			controlledEntity: proposal.controlledEntity,
			effects: [
				.init(icon: .applied, text: "Applied once submitted"),
				.proposedBy(proposal.proposer),
				.currentDelay(proposal.currentTimedRecoveryDelayInMinutes),
			],
			rules: proposal.proposedRules
		)
	}

	/// Proposed with the recovery role only, to be completed later. The
	/// engine keeps the access controller's current delay, not the one the
	/// proposal names, so that is the one shown, and never the proposal's.
	init(timedRecovery recovery: AccessControllerTimedRecoveryProposal) {
		var effects: [Effect] = [.init(
			icon: .timed,
			text: recovery.currentTimedRecoveryDelayInMinutes.map {
				"Timed update, can be completed after \(Self.period(minutes: $0))"
			} ?? "Timed update, delay unknown: it may not complete without confirmation"
		)]
		if recovery.locksPrimaryRole {
			effects.append(.init(icon: .lock, text: "Locks Primary Role"))
		}
		self.init(
			accessController: recovery.accessController,
			controlledEntity: recovery.controlledEntity,
			effects: effects,
			rules: recovery.proposedRules
		)
	}

	/// Completes a change proposed earlier: quickly, with a second role, or
	/// once a timed recovery's delay has passed.
	init(confirmation: AccessControllerRecoveryConfirmation) {
		self.init(
			accessController: confirmation.accessController,
			controlledEntity: confirmation.controlledEntity,
			effects: [
				.init(
					icon: .applied,
					text: confirmation.kind == .quick ? "Confirms the pending update" : "Completes the timed update"
				),
				.proposedBy(confirmation.proposer),
				.currentDelay(confirmation.currentTimedRecoveryDelayInMinutes),
			],
			rules: confirmation.proposedRules
		)
	}

	/// Stops a timed recovery, cancels pending proposals, or both, and may
	/// unlock the primary role: one effect for each. The stopped rules are
	/// the recovery role's proposal, cancelled only if that role's proposal
	/// is: otherwise they are still pending and can be confirmed.
	init(cancellation: AccessControllerRecoveryCancellation) {
		let cancelsRecoveryRoleProposal = cancellation.cancelledProposers.contains(.recovery)
		var effects: [Effect] = []
		if cancellation.stoppedTimedRecovery != nil {
			effects.append(.init(
				icon: .stop,
				text: cancelsRecoveryRoleProposal
					? "Stops the timer of the Recovery Role's update"
					: "Stops the timer of the Recovery Role's update; it can still be confirmed"
			))
		}
		// Once per role, in a fixed order, as a role is cancelled at most once.
		for proposer in [RecoveryProposer.recovery, .primary] where cancellation.cancelledProposers.contains(proposer) {
			effects.append(.init(icon: .cancel, text: "Cancels the \(proposer.roleName)'s pending update"))
		}
		if cancellation.unlocksPrimaryRole {
			effects.append(.init(icon: .unlock, text: "Unlocks Primary Role"))
		}
		self.init(
			accessController: cancellation.accessController,
			controlledEntity: cancellation.controlledEntity,
			effects: effects,
			rules: cancellation.stoppedTimedRecovery,
			rulesHeading: cancelsRecoveryRoleProposal ? "Cancelled rules" : "Pending rules"
		)
	}

	init(primaryRoleLock operation: AccessControllerPrimaryRoleLockOperation) {
		self.init(
			accessController: operation.accessController,
			controlledEntity: operation.controlledEntity,
			effects: [operation.operation == .lock
				? .init(icon: .lock, text: "Locks Primary Role")
				: .init(icon: .unlock, text: "Unlocks Primary Role")]
		)
	}

	init(recoveryFeeContribution transfer: AccessControllerXrdTransfer) {
		self.init(
			heading: .recoveryFees,
			accessController: transfer.accessController,
			controlledEntity: transfer.controlledEntity
		)
	}

	init(recoveryFeeWithdrawal transfer: AccessControllerXrdTransfer) {
		self.init(
			heading: .recoveryFees,
			accessController: transfer.accessController,
			controlledEntity: transfer.controlledEntity
		)
	}

	/// An account or persona created with its owner badge in a new access
	/// controller, e.g. a shared account a dApp sets up.
	init(created: CreatedSecurifiedEntity) {
		let isAccount = if case .account = created.entity {
			true
		} else {
			false
		}
		self.init(
			heading: isAccount ? .createAccount : .createPersona,
			accessController: nil,
			controlledEntity: created.entity,
			createsEntity: true,
			effects: [.init(icon: .created, text: "Controlled by the rules below")]
				+ (created.timedRecoveryDelayInMinutes.map {
					[.init(icon: .timed, text: "Timed recovery after \(Self.period(minutes: $0))")]
				} ?? []),
			rules: created.rules,
			rulesHeading: "Rules"
		)
	}

	/// The period as the shield setup names it ("3 days", "2 weeks"), or
	/// spelled out when it isn't a whole number of days, or is too many for
	/// the shield setup's periods.
	static func period(minutes: UInt32) -> String {
		let minutesPerDay: UInt32 = 24 * 60
		if minutes > 0, minutes % minutesPerDay == 0 {
			let days = minutes / minutesPerDay
			if days % 7 == 0, let weeks = UInt16(exactly: days / 7) {
				return TimePeriod(value: weeks, unit: .weeks).title
			}
			if days % 7 != 0, let days = UInt16(exactly: days) {
				return TimePeriod(value: days, unit: .days).title
			}
		}
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.day, .hour, .minute]
		formatter.unitsStyle = .full
		formatter.maximumUnitCount = 2
		return formatter.string(from: TimeInterval(minutes) * 60) ?? "\(minutes) minutes"
	}
}

extension InteractionReview.ControlOperation.Effect {
	/// The role that proposed the update.
	fileprivate static func proposedBy(_ proposer: RecoveryProposer) -> Self {
		.init(icon: .proposer, text: "Proposed by the \(proposer.roleName)")
	}

	/// The access controller's current timed recovery delay, which it keeps
	/// under the new rules: the time after which a recovery role proposal
	/// can be completed without the confirmation role.
	fileprivate static func currentDelay(_ minutes: UInt32?) -> Self {
		.init(
			icon: .timed,
			text: minutes.map {
				"Timed recovery after \(InteractionReview.ControlOperation.period(minutes: $0))"
			} ?? "Timed recovery delay unknown"
		)
	}
}

extension RecoveryProposer {
	/// The role, as the rules name it.
	fileprivate var roleName: String {
		switch self {
		case .primary: "Primary Role"
		case .recovery: "Recovery Role"
		}
	}
}

extension DetailedManifestClass {
	/// The access controllers an access controller class operates on, `nil`
	/// for other classes.
	var accessControllerAddresses: [AccessControllerAddress]? {
		switch self {
		case let .accessControllerRecovery(acAddresses, _),
		     let .accessControllerTimedRecovery(acAddresses, _),
		     let .accessControllerConfirmRecovery(acAddresses, _),
		     let .accessControllerCancelRecovery(acAddresses, _),
		     let .accessControllerPrimaryRoleLock(acAddresses, _),
		     let .accessControllerRecoveryFee(acAddresses, _, _, _, _):
			acAddresses
		// Every other class, by name, so that a new one has to be sorted here.
		case .general, .transfer, .validatorClaim, .validatorStake, .validatorUnstake,
		     .accountDepositSettingsUpdate, .poolContribution, .poolRedemption, .deleteAccounts,
		     .securifyEntity, .securifiedEntityCreation:
			nil
		}
	}

	/// Whether it changes, confirms, stops or locks access controllers: the
	/// operations signed with an access controller's roles, as a pre-
	/// authorization may make them.
	var isAccessControllerOperation: Bool {
		switch self {
		case .accessControllerRecovery, .accessControllerTimedRecovery, .accessControllerConfirmRecovery,
		     .accessControllerCancelRecovery, .accessControllerPrimaryRoleLock:
			true
		// Every other class, by name, so that a new one has to be sorted here.
		case .accessControllerRecoveryFee, .securifiedEntityCreation,
		     .general, .transfer, .validatorClaim, .validatorStake, .validatorUnstake,
		     .accountDepositSettingsUpdate, .poolContribution, .poolRedemption, .deleteAccounts,
		     .securifyEntity:
			false
		}
	}
}

// MARK: - InteractionReview.RecoveryProposalView
extension InteractionReview {
	/// Draws a `ControlOperation`: a card with the account and what the
	/// operation does, then, if it sets or stops rules, a section of their
	/// own with the primary, recovery and confirmation roles.
	struct RecoveryProposalView: View {
		let operation: ControlOperation

		/// The details shown in a sheet, as on the MFA signature resources
		/// screen: the address details of a key, resource or NFT, or the user's
		/// factor source.
		@State private var details: Details?

		@Dependency(\.errorQueue) private var errorQueue
		@Dependency(\.addressBookClient) private var addressBookClient

		var body: some View {
			VStack(alignment: .leading, spacing: .medium1) {
				Card {
					VStack(alignment: .leading, spacing: .zero) {
						controlledAccount
						controlledEntityAddress

						if !operation.effects.isEmpty {
							EffectsView(effects: operation.effects)
								.flushedLeft
								.padding(.medium3)
								.background(.secondaryBackground)
						}
					}
				}

				if let rules = operation.rules {
					VStack(alignment: .leading, spacing: .small2) {
						HeadingView(operation.rulesHeading, icon: AssetResource.signingKey, scalesIcon: true)
						Card {
							VStack(alignment: .leading, spacing: .medium2) {
								RoleView(title: "Primary Role", requirement: rules.primaryRole)
								RoleView(title: "Recovery Role", requirement: rules.recoveryRole)
								RoleView(title: "Confirmation Role", requirement: rules.confirmationRole)
							}
							.padding(.medium3)
						}
					}
				}
			}
			.environment(\.showDetails, show)
			.sheet(item: $details) { details in
				switch details.kind {
				case let .address(address):
					AddressDetails.View(
						store: Store(initialState: .init(address: address)) {
							AddressDetails()
						}
					)
				case let .factorSource(integrity):
					FactorSourceDetail.View(
						store: Store(initialState: .init(integrity: integrity)) {
							FactorSourceDetail()
						}
					)
					.withNavigationBar { self.details = nil }
				}
			}
		}

		private func show(_ request: DetailsRequest) {
			switch request {
			case let .address(address):
				details = Details(kind: .address(address))
			case let .factorSource(factorSource):
				Task {
					do {
						let integrity = try await SargonOs.shared.factorSourceIntegrity(factorSource: factorSource)
						details = Details(kind: .factorSource(integrity))
					} catch {
						errorQueue.schedule(error)
					}
				}
			}
		}

		/// The account the access controller controls: the user's own account
		/// card when it is in the Profile, else the card the review uses for
		/// accounts not in this wallet.
		@ViewBuilder
		private var controlledAccount: some View {
			if operation.createsEntity {
				NewEntityHeader(isAccount: operation.heading == .createAccount)
			} else if let account = operation.controlledAccount {
				AccountCard(kind: .innerCompact, account: account)
			} else if case let .account(address) = operation.controlledEntity {
				AccountCard(
					kind: .innerCompact,
					account: InteractionReview.ReviewAccount.external(
						address,
						approved: false,
						addressBookName: (try? addressBookClient.entryByAddress(address.asGeneral))?.name.value
					)
				)
			}
		}

		/// What the access controller controls when it isn't an account: a
		/// persona, or the access controller itself when unknown.
		@ViewBuilder
		private var controlledEntityAddress: some View {
			switch operation.controlledEntity {
			case _ where operation.createsEntity:
				EmptyView()
			case .account:
				EmptyView()
			case let .identity(address):
				AddressView(.address(.identity(address)))
					.textStyle(.body2HighImportance)
					.foregroundStyle(.secondaryText)
					.padding(.medium3)
			case nil:
				Text(operation.accessController?.formatted() ?? "")
					.textStyle(.body2HighImportance)
					.foregroundStyle(.secondaryText)
					.padding(.medium3)
			}
		}
	}
}

// MARK: - NewEntityHeader
/// An account or persona the manifest creates, drawn like the card the review
/// uses for accounts not in this wallet, but without an address: the preview's
/// isn't the one it will have.
private struct NewEntityHeader: View {
	let isAccount: Bool

	var body: some View {
		HStack {
			Text(isAccount ? "New Account" : "New Persona")
				.textStyle(.body1Header)
				.foregroundColor(.white)
			Spacer(minLength: .zero)
		}
		.padding(.horizontal, .medium3)
		.padding(.vertical, .small1)
		.background(Color.externalAccountBackground)
	}
}

// MARK: - EffectsView
/// What an access controller operation does, one effect per row: an icon in
/// the text color and a bold line.
private struct EffectsView: View {
	let effects: [InteractionReview.ControlOperation.Effect]

	var body: some View {
		VStack(alignment: .leading, spacing: .small1) {
			ForEach(effects, id: \.self) { effect in
				HStack(spacing: .small1) {
					effect.image
						.resizable()
						.scaledToFit()
						.frame(width: 24, height: 24)
						.foregroundStyle(.primaryText)
					Text(effect.text)
						.textStyle(.body1Header)
						.foregroundStyle(.primaryText)
						.multilineTextAlignment(.leading)
				}
			}
		}
	}
}

extension InteractionReview.ControlOperation.Effect {
	/// SF Symbols, so every effect shares one stroke style.
	fileprivate var image: Image {
		switch icon {
		case .applied: Image(systemName: "checkmark.circle")
		case .timed: Image(systemName: "calendar.badge.clock")
		case .stop: Image(systemName: "clock.badge.xmark")
		case .cancel: Image(systemName: "nosign")
		case .lock: Image(systemName: "lock")
		case .unlock: Image(systemName: "lock.open")
		case .created: Image(systemName: "plus.circle")
		case .proposer: Image(systemName: "key")
		}
	}
}

// MARK: - RoleView
private struct RoleView: View {
	let title: String
	let requirement: AccessRequirementForDisplay

	var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text(title)
				.textStyle(.body1Header)
				.foregroundStyle(.primaryText)
			RequirementView(requirement: requirement)
		}
	}
}

// MARK: - RequirementView
/// A whole requirement, at the top of a role or of a summary sheet.
private struct RequirementView: View {
	let requirement: AccessRequirementForDisplay

	var body: some View {
		switch requirement {
		case .anyone:
			StateCard(
				title: "Anyone",
				subtitle: "No factor needed",
				color: .error,
				icon: Image(asset: AssetResource.error)
			)
		case .noOne:
			StateCard(
				title: "No one",
				subtitle: "Can never be used",
				color: .secondaryText,
				icon: Image(systemName: "lock.fill")
			)
		// A list is a group, outlined like a way, wherever it is.
		case let .anyOf(requirements) where requirements.allSatisfy(\.isLeaf):
			WayCard { LeafList(header: "Any of these", leaves: requirements) }
		case let .anyOf(ways):
			VStack(spacing: .small2) {
				ForEach(Array(ways.enumerated()), id: \.offset) { index, way in
					if index > 0 {
						Connector(text: "OR")
					}
					if way.drawsOwnCard(asPart: false) {
						WayView(requirement: way)
					} else {
						WayCard { WayView(requirement: way) }
					}
				}
			}
		case let .allOf(requirements) where requirements.allSatisfy(\.isLeaf):
			WayCard { LeafList(header: "All of these", leaves: requirements) }
		case .allOf:
			WayCard { WayView(requirement: requirement) }
		case let .countOf(count, badges):
			WayCard {
				LeafList(
					header: "Any \(count) of these \(badges.count)",
					leaves: badges.map { .badge(badge: $0) }
				)
			}
		case .badge, .amountOf:
			LeafView(requirement: requirement)
		}
	}
}

// MARK: - WayView
/// One way of passing a role, drawn inside a card.
private struct WayView: View {
	let requirement: AccessRequirementForDisplay

	var body: some View {
		switch requirement {
		// A list of badges gets a header, like anywhere else; AND only joins
		// parts of which some are groups.
		case let .allOf(parts) where parts.allSatisfy(\.isLeaf):
			LeafList(header: "All of these", leaves: parts)
		case let .allOf(parts):
			VStack(alignment: .leading, spacing: .small2) {
				ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
					if index > 0 {
						// Joins parts as the OR pill joins ways.
						Connector(text: "AND")
					}
					if part.drawsOwnCard(asPart: true) {
						PartView(requirement: part)
					} else {
						// A list joined by AND is boxed, so it reads as one part.
						PartView(requirement: part)
							.padding(.small1)
							.frame(maxWidth: .infinity, alignment: .leading)
							.overlay(
								RoundedRectangle(cornerRadius: .small1)
									.strokeBorder(Color.border, lineWidth: 1)
							)
					}
				}
			}
		default:
			PartView(requirement: requirement)
		}
	}
}

// MARK: - PartView
/// A part of a way: a badge, a list of badges, or a summary of anything deeper.
private struct PartView: View {
	let requirement: AccessRequirementForDisplay

	var body: some View {
		switch requirement {
		case let .anyOf(choices) where choices.allSatisfy(\.isLeaf):
			LeafList(header: "Any of these", leaves: choices)
		case let .countOf(count, badges):
			LeafList(
				header: "Any \(count) of these \(badges.count)",
				leaves: badges.map { .badge(badge: $0) }
			)
		case let .allOf(requirements) where requirements.allSatisfy(\.isLeaf):
			LeafList(header: "All of these", leaves: requirements)
		case .badge, .amountOf:
			LeafView(requirement: requirement)
		case .anyOf, .allOf, .anyone, .noOne:
			SummaryRow(requirement: requirement)
		}
	}
}

// MARK: - LeafList
private struct LeafList: View {
	let header: String
	let leaves: [AccessRequirementForDisplay]

	var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text(header)
				.textStyle(.body2HighImportance)
				.foregroundStyle(.primaryText)
				.padding(.horizontal, .small2)
				.padding(.vertical, .small3 / 2)
				.background(.tertiaryBackground)
				.clipShape(RoundedRectangle(cornerRadius: .small3))
			ForEach(Array(leaves.enumerated()), id: \.offset) { _, leaf in
				LeafView(requirement: leaf)
			}
		}
	}
}

// MARK: - LeafView
private struct LeafView: View {
	let requirement: AccessRequirementForDisplay

	var body: some View {
		switch requirement {
		case let .badge(badge):
			BadgeView(badge: badge)
		case let .amountOf(amount, resource):
			ResourceBadgeRow(badge: .amount(amount, of: resource))
		default:
			SummaryRow(requirement: requirement)
		}
	}
}

// MARK: - BadgeView
private struct BadgeView: View {
	let badge: BadgeForDisplay
	@Environment(\.showDetails) private var showDetails
	@Dependency(\.addressBookClient) private var addressBookClient

	var body: some View {
		switch badge {
		case let .ownFactor(factorSource):
			// As the "Created with" factor source on the MFA signature
			// resources screen.
			Button { showDetails(.factorSource(factorSource)) } label: {
				FactorSourceCard(
					kind: .instance(factorSource: factorSource, kind: .short(showDetails: false)),
					mode: .display,
					surface: .glass(interactive: true)
				)
				.frame(maxWidth: .infinity, alignment: .leading)
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
		case let .unknownKey(badge):
			// Drawn like a signature resource on the MFA signature resources
			// screen, with a dashed outline as it isn't in this wallet, and
			// named as in the address book. A key without a name stands out
			// as one the user hasn't met, with a warning.
			Button { showDetails(.address(.nonFungibleGlobalID(badge))) } label: {
				HStack(spacing: .small2) {
					Thumbnail(.nft, url: nil, size: .small)

					VStack(alignment: .leading, spacing: .small3) {
						Text(alias(of: badge) ?? "Unknown key")
							.textStyle(.body1Header)
							.foregroundColor(.primaryText)
							.lineLimit(1)

						// The whole row opens the details, not only the address.
						AddressView(.address(.nonFungibleGlobalID(badge)), isTappable: false)
							.textStyle(.body2Regular)
							.foregroundColor(.secondaryText)

						if alias(of: badge) == nil {
							StatusMessageView(
								text: "Not in your address book",
								type: .warning,
								useNarrowSpacing: true,
								useSmallerFontSize: true
							)
						}
					}

					Spacer(minLength: .zero)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.medium2)
				.addressBookEntrySurface()
				.overlay(
					RoundedRectangle(cornerRadius: .medium3)
						.strokeBorder(Color.secondaryText, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
				)
				.contentShape(RoundedRectangle(cornerRadius: .medium3))
			}
			.buttonStyle(.plain)
		case let .nonFungible(badge):
			ResourceBadgeRow(badge: .nonFungible(badge))
		case let .resource(resource):
			ResourceBadgeRow(badge: .resource(resource))
		}
	}
}

extension BadgeView {
	/// The name the address book gives the key, if any.
	private func alias(of key: NonFungibleGlobalID) -> String? {
		(try? addressBookClient.entryByTarget(.nonFungible(value: key)))?.name.value
	}
}

// MARK: - DetailsRequest
/// What a tapped badge asks to show.
private enum DetailsRequest {
	/// A key, a resource or an NFT, by its address.
	case address(LedgerIdentifiable.Address)
	case factorSource(FactorSource)
}

// MARK: - Details
private struct Details: Identifiable {
	enum Kind {
		case address(LedgerIdentifiable.Address)
		case factorSource(FactorSourceIntegrity)
	}

	let id = UUID()
	let kind: Kind
}

// MARK: - ShowDetailsKey
private struct ShowDetailsKey: EnvironmentKey {
	static let defaultValue: (DetailsRequest) -> Void = { _ in }
}

extension EnvironmentValues {
	/// Shows the details of a badge in a proposed rule.
	fileprivate var showDetails: (DetailsRequest) -> Void {
		get { self[ShowDetailsKey.self] }
		set { self[ShowDetailsKey.self] = newValue }
	}
}

// MARK: - ResourceBadgeRow
/// A badge that is a resource, an amount of one or an NFT: anyone holding it
/// passes, and it can be transferred. Drawn like a key, with its address or
/// global ID under its name, as names come from the ledger and anyone can set
/// them; the whole row opens the address details.
private struct ResourceBadgeRow: View {
	enum Badge: Hashable {
		case resource(ResourceAddress)
		case amount(Decimal192, of: ResourceAddress)
		case nonFungible(NonFungibleGlobalID)

		var resourceAddress: ResourceAddress {
			switch self {
			case let .resource(resource), let .amount(_, resource): resource
			case let .nonFungible(badge): badge.resourceAddress
			}
		}

		/// The NFT's global ID, or the resource's address.
		var address: LedgerIdentifiable.Address {
			switch self {
			case let .nonFungible(id): .nonFungibleGlobalID(id)
			case .resource, .amount: .resource(resourceAddress)
			}
		}
	}

	let badge: Badge

	@Environment(\.showDetails) private var showDetails
	@Dependency(\.onLedgerEntitiesClient) private var onLedgerEntitiesClient
	@State private var resource: OnLedgerEntity.Resource?
	@State private var nonFungibleName: String?

	var body: some View {
		Button { showDetails(.address(badge.address)) } label: {
			HStack(alignment: .top, spacing: .small2) {
				thumbnail

				VStack(alignment: .leading, spacing: .small3) {
					Text(title)
						.textStyle(.body1Header)
						.foregroundColor(.primaryText)
						.lineLimit(1)

					// Only loaded for an NFT badge.
					if let nonFungibleName {
						Text(nonFungibleName)
							.textStyle(.body2HighImportance)
							.foregroundColor(.primaryText)
							.lineLimit(1)
					}

					// The whole row opens the details, not only the address.
					AddressView(.address(badge.address), isTappable: false)
						.textStyle(.body2Regular)
						.foregroundColor(.secondaryText)

					Text(holders)
						.textStyle(.body2Regular)
						.foregroundColor(.secondaryText)
						.multilineTextAlignment(.leading)
				}

				Spacer(minLength: .zero)

				Text("Transferable")
					.textStyle(.body2HighImportance)
					.foregroundStyle(.primaryText)
					.padding(.horizontal, .small2)
					.padding(.vertical, .small3 / 2)
					.background(.tertiaryBackground)
					.clipShape(RoundedRectangle(cornerRadius: .small3))
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.medium2)
			.addressBookEntrySurface()
			.overlay(
				RoundedRectangle(cornerRadius: .medium3)
					.strokeBorder(Color.border, lineWidth: 1)
			)
			.contentShape(RoundedRectangle(cornerRadius: .medium3))
		}
		.buttonStyle(.plain)
		.task(id: badge) {
			resource = try? await onLedgerEntitiesClient.getResource(
				badge.resourceAddress,
				metadataKeys: .dappMetadataKeys
			)
			if case let .nonFungible(id) = badge {
				nonFungibleName = try? await onLedgerEntitiesClient.getNonFungibleTokenData(
					.init(resource: id.resourceAddress, nonFungibleIds: [id])
				).first?.data?.name
			}
		}
	}

	private var isNonFungible: Bool {
		badge.resourceAddress.isNonFungible
	}

	@ViewBuilder
	private var thumbnail: some View {
		if isNonFungible {
			Thumbnail(.nft, url: resource?.metadata.iconURL, size: .small)
		} else {
			Thumbnail(.token(badge.resourceAddress.isXRD ? .xrd : .other), url: resource?.metadata.iconURL, size: .small)
		}
	}

	/// The name the ledger gives the resource, never the only identifier.
	private var title: String {
		let metadata = resource?.metadata
		return isNonFungible
			? metadata?.name ?? "Unnamed NFT collection"
			: metadata?.title ?? "Unnamed token"
	}

	/// Who passes: anyone holding the badge.
	private var holders: String {
		switch badge {
		case .nonFungible:
			"Anyone holding this NFT"
		case .resource where isNonFungible:
			"Anyone holding an NFT of this collection"
		case .resource:
			"Anyone holding any amount of this token"
		case let .amount(amount, _):
			"Anyone holding \(amount.formatted()) of this token"
		}
	}
}

// MARK: - SummaryRow
/// Stands in for a requirement too deep to draw in place, and opens it in a sheet.
private struct SummaryRow: View {
	let requirement: AccessRequirementForDisplay
	@State private var showsDetails = false

	var body: some View {
		Button { showsDetails = true } label: {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(title)
						.textStyle(.body1Header)
						.foregroundStyle(.primaryText)
					Text(subtitle)
						.textStyle(.body2Regular)
						.foregroundStyle(.secondaryText)
				}
				Spacer(minLength: 0)
				Image(systemName: "chevron.right")
					.foregroundStyle(.iconSecondary)
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .small1)
			.background(.secondaryBackground)
			.clipShape(RoundedRectangle(cornerRadius: .small1))
		}
		.buttonStyle(.plain)
		.sheet(isPresented: $showsDetails) {
			ScrollView {
				RequirementView(requirement: requirement)
					.padding(.medium1)
			}
			.radixToolbar(title: title)
			.withNavigationBar { showsDetails = false }
			.presentationDetents([.medium, .large])
		}
	}

	private var title: String {
		switch requirement {
		case let .anyOf(options): "One of \(options.count) options"
		case let .allOf(parts): "All of \(parts.count) parts"
		case .anyone: "Anyone"
		case .noOne: "No one"
		default: "Requirement"
		}
	}

	private var subtitle: String {
		switch requirement {
		// Neutral: what the options or parts need is only known once opened.
		case .anyOf, .allOf: "Tap to review"
		case .anyone: "No factor needed"
		case .noOne: "Can never be used"
		default: ""
		}
	}
}

// MARK: - WayCard
private struct WayCard<Content: View>: View {
	@ViewBuilder let content: Content

	var body: some View {
		content
			.padding(.small1)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(.primaryBackground)
			.clipShape(RoundedRectangle(cornerRadius: .small1))
			.overlay(
				RoundedRectangle(cornerRadius: .small1)
					.strokeBorder(Color.border, lineWidth: 1)
			)
	}
}

// MARK: - Connector
private struct Connector: View {
	let text: String

	var body: some View {
		HStack(spacing: .small2) {
			Rectangle().fill(Color.border).frame(height: 1)
			Text(text)
				.textStyle(.body2HighImportance)
				.foregroundStyle(.secondaryText)
				.padding(.horizontal, .small2)
				.overlay(Capsule().strokeBorder(Color.border, lineWidth: 1))
			Rectangle().fill(Color.border).frame(height: 1)
		}
	}
}

// MARK: - StateCard
private struct StateCard: View {
	let title: String
	let subtitle: String
	let color: Color
	let icon: Image

	var body: some View {
		HStack(spacing: .small1) {
			icon
				.resizable()
				.scaledToFit()
				.frame(.smallest)
				.foregroundStyle(color)
			VStack(alignment: .leading, spacing: 0) {
				Text(title)
					.textStyle(.body1Header)
					.foregroundStyle(color)
				Text(subtitle)
					.textStyle(.body2Regular)
					.foregroundStyle(.secondaryText)
			}
			Spacer(minLength: 0)
		}
		.padding(.horizontal, .medium3)
		.padding(.vertical, .small1)
		.overlay(
			RoundedRectangle(cornerRadius: .small1)
				.strokeBorder(color, lineWidth: 1)
		)
	}
}

extension AccessRequirementForDisplay {
	fileprivate var isLeaf: Bool {
		switch self {
		case .badge, .amountOf: true
		default: false
		}
	}

	/// Whether, as a way or as a part joined by AND, it is drawn as a card of
	/// its own (a badge or a summary row) and so needs no box around it. A way
	/// that joins groups by AND is drawn in place, while a part is summarized.
	fileprivate func drawsOwnCard(asPart: Bool) -> Bool {
		switch self {
		case .badge, .amountOf, .anyone, .noOne: true
		case let .anyOf(choices): !choices.allSatisfy(\.isLeaf)
		case let .allOf(parts): asPart && !parts.allSatisfy(\.isLeaf)
		case .countOf: false
		}
	}
}

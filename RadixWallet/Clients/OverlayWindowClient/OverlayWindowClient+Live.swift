// MARK: - OverlayWindowClient + DependencyKey
extension OverlayWindowClient: DependencyKey {
	public static let liveValue: Self = {
		let items = AsyncPassthroughSubject<Item>()
		let alertActions = AsyncPassthroughSubject<(action: Item.AlertAction, id: Item.AlertState.ID)>()
		let fullScreenActions = AsyncPassthroughSubject<(action: FullScreenAction, id: FullScreenID)>()
		let isUserInteractionEnabled = AsyncPassthroughSubject<Bool>()

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.pasteboardClient) var pasteBoardClient

		errorQueue.errors().map { error in
			if let sargonError = error as? SargonError {
				#if DEBUG
				let message = error.localizedDescription
				#else
				let message = L10n.Error.emailSupportMessage(sargonError.errorCode)
				#endif
				return Item.alert(.init(
					title: { TextState(L10n.Common.errorAlertTitle) },
					actions: {
						let buttons: [ButtonState<OverlayWindowClient.Item.AlertAction>] = [
							.init(role: .cancel, action: .dismissed, label: { TextState(L10n.Common.cancel) }),
							.init(action: .emailSupport(additionalInfo: error.localizedDescription), label: { TextState(L10n.Error.emailSupportButtonTitle) }),
						]
						return buttons
					},
					message: { TextState(message) }
				))
			} else {
				return Item.alert(.init(
					title: { TextState(L10n.Common.errorAlertTitle) },
					message: { TextState(error.localizedDescription) }
				))
			}
		}
		.subscribe(items)

		pasteBoardClient.copyEvents().map { _ in Item.hud(.copied) }.subscribe(items)

		let scheduleAlertAndIgnoreAction: ScheduleAlertAndIgnoreAction = { alert in
			items.send(.alert(alert))
		}

		return .init(
			scheduledItems: { items.eraseToAnyAsyncSequence() },
			scheduleAlert: { alert in
				scheduleAlertAndIgnoreAction(alert)
				return await alertActions.first { $0.id == alert.id }?.action ?? .dismissed
			},
			scheduleAlertAndIgnoreAction: scheduleAlertAndIgnoreAction,
			scheduleHUD: { items.send(.hud($0)) },
			scheduleSheet: { items.send(.sheet($0, $1)) },
			scheduleFullScreen: { fullScreen in
				items.send(.fullScreen(fullScreen))
				return await fullScreenActions.first { $0.id == fullScreen.id }?.action ?? .dismiss
			},
			sendAlertAction: { action, id in alertActions.send((action, id)) },
			sendFullScreenAction: { action, id in fullScreenActions.send((action, id)) },
			setIsUserIteractionEnabled: { isUserInteractionEnabled.send($0) },
			isUserInteractionEnabled: { isUserInteractionEnabled.eraseToAnyAsyncSequence() }
		)
	}()
}

// MARK: - OverlayWindowClient.InfoLink
extension OverlayWindowClient {
	public enum InfoLink: String, Sendable {
		private static let scheme: String = "infolink"

		case linkingNewAccount
		case poolunit
		case gateways
		case radixconnect
		case transactionfee
		case securityshield

		public init?(url: URL) {
			guard url.scheme == Self.scheme, let host = url.host(), let link = InfoLink(rawValue: host) else {
				return nil
			}
			self = link
		}
	}
}

extension OverlayWindowClient {
	public func showInfoLink(_ infoLink: InfoLink) {
		scheduleSheet(.init(text: infoLink.string), .replace)
	}
}

extension OverlayWindowClient.InfoLink {
	var string: String {
		switch self {
		case .linkingNewAccount:
			linkingNewAccountString
		case .poolunit:
			poolunitString
		case .gateways:
			gatewaysString
		case .radixconnect:
			radixconnectString
		case .transactionfee:
			transactionfeeString
		case .securityshield:
			securityshieldString
		}
	}
}

let linkingNewAccountString = """
# Why your Accounts will be linked
Paying your transaction fee from this Account will make you identifiable on ledger as both the owner of the fee-paying Account and all other Accounts you use in this transaction.

*This* is _because_ you’ll **sign** the transactions on [github](https://github.com) from each [transaction fee ⓘ](infolink://transactionfee) at the same time, so your Accounts will be linked together in the transaction record.
"""

let poolunitString = """
# Pool Units
Pool units are fungible tokens that represent the proportional size of a user's contribution to a liquidity pool (LP).

Pool units are redeemable for the user's portion of the LP, but can also be traded, sold and used in DeFi applications.
"""

let gatewaysString = """
# Gateways
Gateways are your connection to blockchain networks – they enable users to communicate with the Radix Network and transfer data to and from it. As there are multiple different networks within the Radix ecosystem (for example, the Stokenet test environment or the Babylon mainnet), there a multiple gateways providing access to each one.
"""

let radixconnectString = """
# Radix Connect
Radix Connect enables users to link their Radix Wallet to desktop dApps.
"""

let transactionfeeString = """
# Transaction Fee

## Network fee
These go to Radix node operators who validate transactions and secure the Radix Network. Network fees reflect the size of the transaction.

## Royalty fee
These are set by developers and allow them to collect a “use fee” every time their work is used in a transaction.

## Tip
These are optional payments you can make directly to validators to speed up transactions. [pool unit ⓘ](infolink://poolunit)
"""

let securityshieldString = """
# Security Shields
Security Shields are a combination of security factors you use to sign transactions, and recover locked Accounts and Personas. You'll need to pay a small transaction fee to apply one to the Radix Network.
"""

extension OverlayWindowClient.Item.HUD {
	public static let updatedAccount = Self(text: L10n.AccountSettings.updatedAccountHUDMessage)
	public static let copied = Self(text: L10n.AddressAction.copiedToClipboard)
	public static let seedPhraseImported = Self(text: L10n.ImportMnemonic.seedPhraseImported)
	public static let thankYou = Self(text: "Thank you!")
}

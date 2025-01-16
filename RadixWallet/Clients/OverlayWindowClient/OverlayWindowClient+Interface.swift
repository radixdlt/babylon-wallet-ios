// MARK: - OverlayWindowClient
/// This client is the intermediary between Main Window and the Overlay Window.
struct OverlayWindowClient: Sendable {
	/// All scheduled items to be shown in Overlay Window.
	var scheduledItems: ScheduledItems

	/// Schedule an Alert to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	var scheduleAlert: ScheduleAlert

	/// Schedule an Alert to be shown in the Overlay Window, but don't wait for any action
	var scheduleAlertAndIgnoreAction: ScheduleAlertAndIgnoreAction

	/// Schedule a HUD to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	var scheduleHUD: ScheduleHUD

	/// Schedule a sheet to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	var scheduleSheet: ScheduleSheet

	/// Schedule a FullScreen to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	var scheduleFullScreen: ScheduleFullScreen

	/// Used by the Overlay Window to send actions from an Alert back to the client
	var sendAlertAction: SendAlertAction

	/// Used by the Overlay Window to send actions from an FullScreenOverlay back to the client
	var sendFullScreenAction: SendFullScreenAction

	/// Used by the Overlay Window to send actions from an SheetAction back to the client
	var sendSheetAction: SendSheetAction

	var setIsUserIteractionEnabled: SetIsUserIteractionEnabled
	var isUserInteractionEnabled: IsUserInteractionEnabled
}

extension OverlayWindowClient {
	typealias FullScreenAction = FullScreenOverlayCoordinator.DelegateAction
	typealias FullScreenID = FullScreenOverlayCoordinator.State.ID
	typealias SheetID = SheetOverlayCoordinator.State.ID
	typealias SheetAction = SheetOverlayCoordinator.DelegateAction

	typealias ScheduleAlert = @Sendable (Item.AlertState) async -> Item.AlertAction
	typealias ScheduleAlertAndIgnoreAction = @Sendable (Item.AlertState) -> Void
	typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	typealias ScheduleSheet = @Sendable (SheetOverlayCoordinator.State) async -> SheetAction
	typealias ScheduleFullScreen = @Sendable (FullScreenOverlayCoordinator.State) async -> FullScreenAction
	typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	typealias SendFullScreenAction = @Sendable (FullScreenAction, FullScreenID) -> Void
	typealias SendSheetAction = @Sendable (SheetAction, SheetID) -> Void
	typealias ScheduledItems = @Sendable () -> AnyAsyncSequence<Item>

	typealias SetIsUserIteractionEnabled = @Sendable (Bool) -> Void
	typealias IsUserInteractionEnabled = @Sendable () -> AnyAsyncSequence<Bool>
}

// MARK: OverlayWindowClient.Item
extension OverlayWindowClient {
	enum Item: Sendable, Hashable {
		typealias AlertState = ComposableArchitecture.AlertState<AlertAction>
		enum AlertAction: Sendable, Hashable {
			case primaryButtonTapped
			case secondaryButtonTapped
			case dismissed
			case emailSupport(additionalInfo: String)
		}

		struct HUD: Sendable, Hashable, Identifiable {
			let id = UUID()
			let text: String
			let icon: Icon?

			init(
				text: String,
				icon: Icon? = Icon(
					kind: .system("checkmark.circle.fill"),
					foregroundColor: Color.app.green1
				)
			) {
				self.text = text
				self.icon = icon
			}
		}

		struct Icon: Hashable, Sendable {
			enum Kind: Hashable, Sendable {
				case asset(ImageAsset)
				case system(String)
			}

			let kind: Kind
			let foregroundColor: Color

			init(
				kind: Kind,
				foregroundColor: Color = .app.green1
			) {
				self.kind = kind
				self.foregroundColor = foregroundColor
			}
		}

		case hud(HUD)
		case alert(AlertState)
		case sheet(SheetOverlayCoordinator.State)
		case fullScreen(FullScreenOverlayCoordinator.State)
	}
}

extension DependencyValues {
	var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}

extension OverlayWindowClient {
	func showInfoLink(_ state: InfoLinkSheet.State) {
		Task {
			let _ = await scheduleSheet(.init(root: .infoLink(state)))
		}
	}

	func signTransaction(input: PerFactorSourceInputOfTransactionIntent) async -> SheetAction {
		await scheduleSheet(.init(root: .newSigning(.init(input: input))))
	}

	func signSubintent(input: PerFactorSourceInputOfSubintent) async -> SheetAction {
		await scheduleSheet(.init(root: .newSigning(.init(input: input))))
	}

	func signAuth(input: PerFactorSourceInputOfAuthIntent) async -> SheetAction {
		await scheduleSheet(.init(root: .newSigning(.init(input: input))))
	}
}

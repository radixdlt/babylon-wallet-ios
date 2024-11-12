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

	var setIsUserIteractionEnabled: SetIsUserIteractionEnabled
	var isUserInteractionEnabled: IsUserInteractionEnabled

	init(
		scheduledItems: @escaping ScheduledItems,
		scheduleAlert: @escaping ScheduleAlert,
		scheduleAlertAndIgnoreAction: @escaping ScheduleAlertAndIgnoreAction,
		scheduleHUD: @escaping ScheduleHUD,
		scheduleSheet: @escaping ScheduleSheet,
		scheduleFullScreen: @escaping ScheduleFullScreen,
		sendAlertAction: @escaping SendAlertAction,
		sendFullScreenAction: @escaping SendFullScreenAction,
		setIsUserIteractionEnabled: @escaping SetIsUserIteractionEnabled,
		isUserInteractionEnabled: @escaping IsUserInteractionEnabled
	) {
		self.scheduledItems = scheduledItems
		self.scheduleAlert = scheduleAlert
		self.scheduleAlertAndIgnoreAction = scheduleAlertAndIgnoreAction
		self.scheduleHUD = scheduleHUD
		self.scheduleSheet = scheduleSheet
		self.scheduleFullScreen = scheduleFullScreen
		self.sendAlertAction = sendAlertAction
		self.sendFullScreenAction = sendFullScreenAction
		self.setIsUserIteractionEnabled = setIsUserIteractionEnabled
		self.isUserInteractionEnabled = isUserInteractionEnabled
	}
}

extension OverlayWindowClient {
	typealias FullScreenAction = FullScreenOverlayCoordinator.DelegateAction
	typealias FullScreenID = FullScreenOverlayCoordinator.State.ID

	typealias ScheduleAlert = @Sendable (Item.AlertState) async -> Item.AlertAction
	typealias ScheduleAlertAndIgnoreAction = @Sendable (Item.AlertState) -> Void
	typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	typealias ScheduleSheet = @Sendable (SheetOverlayCoordinator.Root.State) -> Void
	typealias ScheduleFullScreen = @Sendable (FullScreenOverlayCoordinator.State) async -> FullScreenAction
	typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	typealias SendFullScreenAction = @Sendable (FullScreenAction, FullScreenID) -> Void
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
		case sheet(SheetOverlayCoordinator.Root.State)
		case fullScreen(FullScreenOverlayCoordinator.State)
	}
}

extension DependencyValues {
	var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}

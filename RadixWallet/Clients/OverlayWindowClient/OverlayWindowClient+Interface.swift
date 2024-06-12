// MARK: - OverlayWindowClient
/// This client is the intermediary between Main Window and the Overlay Window.
public struct OverlayWindowClient: Sendable {
	/// All scheduled items to be shown in Overlay Window.
	public var scheduledItems: ScheduledItems

	/// Schedule an Alert to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleAlert: ScheduleAlert

	/// Schedule an Alert to be shown in the Overlay Window, but don't wait for any action
	public var scheduleAlertAndIgnoreAction: ScheduleAlertAndIgnoreAction

	/// Schedule a HUD to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleHUD: ScheduleHUD

	/// Schedule a FullScreen to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleFullScreen: ScheduleFullScreen

	/// Used by the Overlay Window to send actions from an Alert back to the client
	public var sendAlertAction: SendAlertAction

	/// Used by the Overlay Window to send actions from an FullScreenOverlay back to the client
	public var sendFullScreenAction: SendFullScreenAction

	public var setIsUserIteractionEnabled: SetIsUserIteractionEnabled
	public var isUserInteractionEnabled: IsUserInteractionEnabled

	public var scheduleLinkingDapp: ScheduleLinkingDapp

	public init(
		scheduledItems: @escaping ScheduledItems,
		scheduleAlert: @escaping ScheduleAlert,
		scheduleAlertAndIgnoreAction: @escaping ScheduleAlertAndIgnoreAction,
		scheduleHUD: @escaping ScheduleHUD,
		scheduleFullScreen: @escaping ScheduleFullScreen,
		sendAlertAction: @escaping SendAlertAction,
		sendFullScreenAction: @escaping SendFullScreenAction,
		setIsUserIteractionEnabled: @escaping SetIsUserIteractionEnabled,
		isUserInteractionEnabled: @escaping IsUserInteractionEnabled,
		scheduleLinkingDapp: @escaping ScheduleLinkingDapp
	) {
		self.scheduledItems = scheduledItems
		self.scheduleAlert = scheduleAlert
		self.scheduleAlertAndIgnoreAction = scheduleAlertAndIgnoreAction
		self.scheduleHUD = scheduleHUD
		self.scheduleFullScreen = scheduleFullScreen
		self.sendAlertAction = sendAlertAction
		self.sendFullScreenAction = sendFullScreenAction
		self.setIsUserIteractionEnabled = setIsUserIteractionEnabled
		self.isUserInteractionEnabled = isUserInteractionEnabled
		self.scheduleLinkingDapp = scheduleLinkingDapp
	}
}

extension OverlayWindowClient {
	public typealias FullScreenAction = FullScreenOverlayCoordinator.DelegateAction
	public typealias FullScreenID = FullScreenOverlayCoordinator.State.ID

	public typealias ScheduleAlert = @Sendable (Item.AlertState) async -> Item.AlertAction
	public typealias ScheduleAlertAndIgnoreAction = @Sendable (Item.AlertState) -> Void
	public typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	public typealias ScheduleFullScreen = @Sendable (FullScreenOverlayCoordinator.State) async -> FullScreenAction
	public typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	public typealias SendFullScreenAction = @Sendable (FullScreenAction, FullScreenID) -> Void
	public typealias ScheduledItems = @Sendable () -> AnyAsyncSequence<Item>

	public typealias SetIsUserIteractionEnabled = @Sendable (Bool) -> Void
	public typealias IsUserInteractionEnabled = @Sendable () -> AnyAsyncSequence<Bool>
	public typealias ScheduleLinkingDapp = @Sendable (DappMetadata) async -> Item.AlertAction
}

// MARK: OverlayWindowClient.Item
extension OverlayWindowClient {
	public enum Item: Sendable, Hashable {
		public typealias AlertState = ComposableArchitecture.AlertState<AlertAction>
		public enum AlertAction: Sendable, Equatable {
			case primaryButtonTapped
			case secondaryButtonTapped
			case dismissed
		}

		public struct HUD: Sendable, Hashable, Identifiable {
			public let id = UUID()
			public let text: String
			public let icon: Icon?

			public struct Icon: Hashable, Sendable {
				public enum Kind: Hashable, Sendable {
					case asset(ImageAsset)
					case system(String)
				}

				public let kind: Kind
				public let foregroundColor: Color

				public init(
					kind: Kind,
					foregroundColor: Color = .app.green1
				) {
					self.kind = kind
					self.foregroundColor = foregroundColor
				}
			}

			public init(
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

		case hud(HUD)
		case alert(AlertState)
		case autodismissSheet(UUID, DappMetadata)
		case fullScreen(FullScreenOverlayCoordinator.State)
	}
}

extension DependencyValues {
	public var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}

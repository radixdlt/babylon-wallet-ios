// MARK: - OverlayWindowClient
/// This client is the intermediary between Main Window and the Overlay Window.
public struct OverlayWindowClient: Sendable {
	/// All scheduled items to be shown in Overlay Window.
	public var scheduledItems: ScheduledItems

	/// Schedule an Alert to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleAlertIgnoreAction: ScheduleAlertIgnoreAction
	public var scheduleAlertAwaitAction: ScheduleAlertAwaitAction

	/// Schedule a HUD to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleHUD: ScheduleHUD

	/// This is meant to be used by the Overlay Window to send
	/// back the actions from an Alert to the Main Window.
	public var sendAlertAction: SendAlertAction

	public var setIsUserIteractionEnabled: SetIsUserIteractionEnabled
	public var isUserInteractionEnabled: IsUserInteractionEnabled

	public var scheduleLinkingDapp: ScheduleLinkingDapp

	public init(
		scheduledItems: @escaping ScheduledItems,
		scheduleAlertIgnoreAction: @escaping ScheduleAlertIgnoreAction,
		scheduleAlertAwaitAction: @escaping ScheduleAlertAwaitAction,
		scheduleHUD: @escaping ScheduleHUD,
		sendAlertAction: @escaping SendAlertAction,
		setIsUserIteractionEnabled: @escaping SetIsUserIteractionEnabled,
		isUserInteractionEnabled: @escaping IsUserInteractionEnabled,
		scheduleLinkingDapp: @escaping ScheduleLinkingDapp
	) {
		self.scheduledItems = scheduledItems
		self.scheduleAlertIgnoreAction = scheduleAlertIgnoreAction
		self.scheduleAlertAwaitAction = scheduleAlertAwaitAction
		self.scheduleHUD = scheduleHUD
		self.sendAlertAction = sendAlertAction
		self.setIsUserIteractionEnabled = setIsUserIteractionEnabled
		self.isUserInteractionEnabled = isUserInteractionEnabled
		self.scheduleLinkingDapp = scheduleLinkingDapp
	}
}

extension OverlayWindowClient {
	public typealias ScheduleAlertIgnoreAction = @Sendable (Item.AlertState) -> Void
	public typealias ScheduleAlertAwaitAction = @Sendable (Item.AlertState) async -> Item.AlertAction
	public typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	public typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	public typealias ScheduledItems = @Sendable () -> AnyAsyncSequence<Item>

	public typealias SetIsUserIteractionEnabled = @Sendable (Bool) -> Void
	public typealias IsUserInteractionEnabled = @Sendable () -> AnyAsyncSequence<Bool>
	public typealias ScheduleLinkingDapp = @Sendable () async -> Void
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
		case autodismissAlert(AlertState)
		case autodismissSheet(UUID)
	}
}

extension DependencyValues {
	public var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}

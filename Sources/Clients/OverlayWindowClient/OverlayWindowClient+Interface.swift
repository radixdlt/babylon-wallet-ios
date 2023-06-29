import AsyncExtensions
import ComposableArchitecture
import Dependencies
import Resources
import SwiftUI

// MARK: - OverlayWindowClient
/// This client is the intermediary between Main Window and the Overlay Window.
public struct OverlayWindowClient: Sendable {
	/// All scheduled items to be shown in Overlay Window.
	public var scheduledItems: ScheduledItems

	/// Schedule an Alert to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleAlert: ScheduleAlert

	/// Schedule a HUD to be shown in the Overlay Window.
	/// /// Usually to be called from the Main Window.
	public var scheduleHUD: ScheduleHUD

	/// This is meant to be used by the Overlay Window to send
	/// back the actions from an Alert to the Main Window.
	public var sendAlertAction: SendAlertAction

	/// Internal observer for actions emitted from an Alert.
	public var onAlertAction: OnAlertAction

	public init(
		scheduledItems: @escaping ScheduledItems,
		scheduleAlert: @escaping ScheduleAlert,
		scheduleHUD: @escaping ScheduleHUD,
		sendAlertAction: @escaping SendAlertAction,
		onAlertAction: @escaping OnAlertAction
	) {
		self.scheduledItems = scheduledItems
		self.scheduleAlert = scheduleAlert
		self.scheduleHUD = scheduleHUD
		self.sendAlertAction = sendAlertAction
		self.onAlertAction = onAlertAction
	}
}

extension OverlayWindowClient {
	public typealias ScheduleAlert = @Sendable (Item.AlertState) -> Void
	public typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	public typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	public typealias ScheduledItems = @Sendable () -> AnyAsyncSequence<Item>
	public typealias OnAlertAction = @Sendable (Item.AlertState.ID) async -> Item.AlertAction
}

// MARK: OverlayWindowClient.Item
extension OverlayWindowClient {
	public enum Item: Sendable, Hashable {
		public typealias AlertState = ComposableArchitecture.AlertState<AlertAction>
		public enum AlertAction: Equatable {
			case primaryButtonTapped
			case secondaryButtonTapped
			case dismissed
		}

		public struct HUD: Sendable, Hashable, Identifiable {
			public enum Icon: Sendable {
				case asset(ImageAsset)
				case system(String)
			}

			public let id: UUID
			public let text: String
			public let icon: Icon?
			public let iconForegroundColor: Color?

			public init(
				id: UUID = UUID(),
				text: String,
				icon: Icon?,
				iconForegroundColor: Color?
			) {
				self.id = id
				self.text = text
				self.icon = icon
				self.iconForegroundColor = iconForegroundColor
			}

			public func hash(into hasher: inout Hasher) {
				hasher.combine(id)
			}

			public static func == (lhs: HUD, rhs: HUD) -> Bool {
				lhs.id == rhs.id
			}
		}

		case hud(HUD)
		case alert(AlertState)
	}
}

extension OverlayWindowClient {
	public func schedule(hud: Item.HUD) {
		scheduleHUD(hud)
	}

	public func schedule(alert: Item.AlertState) async -> Item.AlertAction {
		scheduleAlert(alert)
		return await onAlertAction(alert.id)
	}
}

extension DependencyValues {
	public var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}

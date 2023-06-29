import AsyncExtensions
import ComposableArchitecture
import Dependencies
import DesignSystem
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
	var onAlertAction: OnAlertAction
}

extension OverlayWindowClient {
	public typealias ScheduleAlert = @Sendable (Item.AlertState) -> Void
	public typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	public typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	public typealias ScheduledItems = @Sendable () -> AnyAsyncSequence<Item>
	typealias OnAlertAction = @Sendable (Item.AlertState.ID) async -> Item.AlertAction
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

		public struct HUD: Sendable, Hashable {
			public enum Icon: Sendable, Hashable {
				case asset(ImageAsset)
				case system(String)
			}

			public let text: String
			public let icon: Icon?
			public let iconForegroundColor: Color?

			public init(text: String, icon: Icon?, iconForegroundColor: Color?) {
				self.text = text
				self.icon = icon
				self.iconForegroundColor = iconForegroundColor
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

	public func scheduleCopiedItem() {
		schedule(hud:
			.init(
				text: "Copied",
				icon: .system("checkmark.circle.fill"),
				iconForegroundColor: .app.green1
			)
		)
	}
}

// MARK: - ImageAsset + Hashable
extension ImageAsset: Hashable {
	public static func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
		lhs.name == rhs.name
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.name)
	}
}

extension DependencyValues {
	public var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}

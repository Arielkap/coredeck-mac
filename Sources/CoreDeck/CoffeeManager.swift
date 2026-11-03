import Foundation
import SwiftUI
import Combine
import IOKit.pwr_mgt
import IOKit.ps

public struct PowerTelemetry: Sendable, Equatable {
    public let isPluggedIn: Bool
    public let batteryPercentage: Int?
    public let isCharging: Bool
}

public func getSystemPowerTelemetry() -> PowerTelemetry {
    guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
        return PowerTelemetry(isPluggedIn: true, batteryPercentage: nil, isCharging: false)
    }
    guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
        return PowerTelemetry(isPluggedIn: true, batteryPercentage: nil, isCharging: false)
    }
    
    for ps in sources {
        if let info = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] {
            let state = info[kIOPSPowerSourceStateKey as String] as? String
            let isPlugged = (state == (kIOPSACPowerValue as String))
            let curCap = info[kIOPSCurrentCapacityKey as String] as? Int
            let maxCap = info[kIOPSMaxCapacityKey as String] as? Int
            let isCharging = info[kIOPSIsChargingKey as String] as? Bool ?? false
            
            var pct: Int? = nil
            if let cur = curCap, let max = maxCap, max > 0 {
                pct = Int((Double(cur) / Double(max)) * 100.0)
            }
            return PowerTelemetry(isPluggedIn: isPlugged, batteryPercentage: pct, isCharging: isCharging)
        }
    }
    return PowerTelemetry(isPluggedIn: true, batteryPercentage: nil, isCharging: false)
}

public enum CoffeeDuration: String, CaseIterable, Sendable, Identifiable {
    case indefinite = "indefinite"
    case minutes15 = "15m"
    case minutes30 = "30m"
    case minutes60 = "1h"
    case minutes120 = "2h"
    
    public var id: String { rawValue }
    
    public var seconds: Int? {
        switch self {
        case .indefinite: return nil
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .minutes60: return 60 * 60
        case .minutes120: return 120 * 60
        }
    }
    
    public func title(lang: AppLanguage) -> String {
        switch self {
        case .indefinite:
            return lang == .en ? "Indefinite (Until toggled off)" : "Bez limitu (Do wyłączenia)"
        case .minutes15:
            return lang == .en ? "15 Minutes (Espresso)" : "15 Minut (Espresso)"
        case .minutes30:
            return lang == .en ? "30 Minutes" : "30 Minut"
        case .minutes60:
            return lang == .en ? "1 Hour" : "1 Godzina"
        case .minutes120:
            return lang == .en ? "2 Hours" : "2 Godziny"
        }
    }
    
    public var shortBadge: String {
        switch self {
        case .indefinite: return "∞"
        case .minutes15: return "15m"
        case .minutes30: return "30m"
        case .minutes60: return "1h"
        case .minutes120: return "2h"
        }
    }
}

@MainActor
public final class CoffeeManager: ObservableObject {
    public static let shared = CoffeeManager()
    
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var currentDuration: CoffeeDuration = .indefinite
    @Published public private(set) var remainingSeconds: Int? = nil
    @Published public var batterySafetyThreshold: Int = 30
    @Published public private(set) var currentPower: PowerTelemetry = getSystemPowerTelemetry()
    @Published public private(set) var guardAlertMessage: String? = nil
    
    private var assertionID: IOPMAssertionID = 0
    private var countdownTimer: AnyCancellable?
    
    private init() {}
    
    deinit {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
        }
    }
    
    public func toggle(duration: CoffeeDuration = .indefinite) {
        if isActive {
            stop()
        } else {
            _ = start(duration: duration)
        }
    }
    
    @discardableResult
    public func start(duration: CoffeeDuration = .indefinite) -> Bool {
        releaseAssertion()
        
        let pwr = getSystemPowerTelemetry()
        self.currentPower = pwr
        
        // Safety guard: Block starting Coffee Mode if running on battery at or below threshold
        if !pwr.isPluggedIn, let pct = pwr.batteryPercentage, pct <= batterySafetyThreshold {
            self.guardAlertMessage = "Bateria: \(pct)% (<= \(batterySafetyThreshold)%). Podłącz zasilacz."
            self.isActive = false
            return false
        }
        self.guardAlertMessage = nil
        
        let reason = "CoreDeck: Coffee Mode Active" as CFString
        let success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        
        if success == kIOReturnSuccess {
            self.isActive = true
            self.currentDuration = duration
            self.remainingSeconds = duration.seconds
            startTimer()
            return true
        } else {
            self.isActive = false
            self.assertionID = 0
            return false
        }
    }
    
    public func stop(reason: String? = nil) {
        countdownTimer?.cancel()
        countdownTimer = nil
        releaseAssertion()
        self.isActive = false
        self.remainingSeconds = nil
    }
    
    private func releaseAssertion() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
    
    private func startTimer() {
        countdownTimer?.cancel()
        
        var currentRemaining = remainingSeconds
        // Run heartbeat every second to update remaining time AND monitor battery power
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isActive else { return }
                
                // 1. Battery Sentinel check
                let pwr = getSystemPowerTelemetry()
                self.currentPower = pwr
                
                if !pwr.isPluggedIn, let pct = pwr.batteryPercentage, pct <= self.batterySafetyThreshold {
                    self.stop(reason: "low_battery")
                    self.sendBatteryGuardNotification(batteryLevel: pct)
                    return
                }
                
                // 2. Countdown if timed
                if var secs = currentRemaining {
                    secs -= 1
                    currentRemaining = secs
                    if secs <= 0 {
                        self.stop()
                    } else {
                        self.remainingSeconds = secs
                    }
                }
            }
    }
    
    private func sendBatteryGuardNotification(batteryLevel: Int) {
        let title = "CoreDeck: Coffee Mode"
        let body = "Ochrona baterii: wyłączono czuwanie (bateria spadła do \(batteryLevel)%). Ekran może teraz zasnąć."
        let script = "display notification \"\(body)\" with title \"☕️ \(title)\""
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        try? task.run()
    }
    
    public func formattedRemaining(lang: AppLanguage) -> String {
        guard let secs = remainingSeconds else {
            return lang == .en ? "Awake (Infinite)" : "Czuwa (Bez limitu)"
        }
        let mins = secs / 60
        let s = secs % 60
        if mins >= 60 {
            let hours = mins / 60
            let remMins = mins % 60
            return String(format: "%dh %02dm", hours, remMins)
        } else {
            return String(format: "%02d:%02d", mins, s)
        }
    }
    
    public func statusSubtitle(lang: AppLanguage) -> String {
        if !isActive {
            return lang == .en ? "Display sleep enabled (normal)" : "Uśpienie ekranu aktywne"
        }
        let guardNote = lang == .en ? " (Guard: \(batterySafetyThreshold)%)" : " (Ochrona: \(batterySafetyThreshold)%)"
        if let formatted = remainingSeconds {
            let mins = formatted / 60
            let secs = formatted % 60
            return lang == .en ? "Display awake for \(String(format: "%02d:%02d", mins, secs))\(guardNote)" : "Ekran nie zaśnie przez \(String(format: "%02d:%02d", mins, secs))\(guardNote)"
        } else {
            return lang == .en ? "Display & system awake (∞)\(guardNote)" : "Ekran i system nie zasną (∞)\(guardNote)"
        }
    }
}

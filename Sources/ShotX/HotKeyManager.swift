import Cocoa
import Carbon.HIToolbox

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: (() -> Void)?

    private static var instances: [UInt32: HotKeyManager] = [:]
    private static var nextID: UInt32 = 1
    private let id: UInt32

    init() {
        id = HotKeyManager.nextID
        HotKeyManager.nextID += 1
    }

    func register(handler: @escaping () -> Void) {
        self.handler = handler
        HotKeyManager.instances[id] = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                guard let event = event else { return noErr }
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if let instance = HotKeyManager.instances[hkID.id] {
                    DispatchQueue.main.async { instance.handler?() }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        // 'SHTX' signature, D key, Option modifier
        let signature: OSType = 0x53485458
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_D),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let handler = eventHandler { RemoveEventHandler(handler) }
        HotKeyManager.instances.removeValue(forKey: id)
    }
}

//
//  RegistrationCenterBruteForce.swift
//  BigNotifyTests
//
//  Created by Nicky Taylor (Nick Raptis) on 10/8/22.
//

import Foundation
@testable import BigNotify

class RegistrationCenterBruteForce {
    
    var observerRegistrations = [TestObserverRegistration]()
    var notificationRegistrations = [TestNotificationRegistration]()
    
    private func containsObserverRegistration(observer: NSObject, name: NSNotification.Name, object: AnyHashable?) -> Bool {
        for reg in observerRegistrations {
            if reg.observer == observer &&
                reg.name == name &&
                reg.object == object {
                return true
            }
        }
        return false
    }
    
    private func containsNotificationRegistration(observer: NSObject, selector: Selector, name: NSNotification.Name, object: AnyHashable?) -> Bool {
        for reg in notificationRegistrations {
            if reg.observer == observer &&
                reg.selector == selector &&
                reg.name == name &&
                reg.object == object {
                return true
            }
        }
        return false
    }
    
    func addObserver(observer: NSObject, selector: Selector, name: NSNotification.Name?, object: AnyHashable?) {
        
        guard let name = name else { return }
        
        if containsObserverRegistration(observer: observer, name: name, object: object) == false {
            observerRegistrations.append(TestObserverRegistration(observer: observer, name: name, object: object))
        }
        
        if containsNotificationRegistration(observer: observer, selector: selector, name: name, object: object) == false {
            notificationRegistrations.append(TestNotificationRegistration(observer: observer, selector: selector, name: name, object: object))
        }
        
    }
    
    func removeObserver(observer: NSObject, name: NSNotification.Name?, object: AnyHashable?) {
        
        guard let name = name else { return }
        
        notificationRegistrations.removeAll { reg in
            reg.observer == observer &&
            reg.name == name &&
            reg.object == object
        }
        observerRegistrations.removeAll { reg in
            reg.observer == observer &&
            reg.name == name &&
            reg.object == object
        }
    }
    
    func removeObserver(observer: NSObject) {
        notificationRegistrations.removeAll { reg in
            reg.observer == observer
        }
        observerRegistrations.removeAll { reg in
            reg.observer == observer
        }
    }
    
    func allObserverNodes() -> [TestObserverRegistration] {
        observerRegistrations
    }
    
    func allNotificationNodes() -> [TestNotificationRegistration] {
        notificationRegistrations
    }
    
    func allNotifyNodes(_ name: Notification.Name) -> [NotifyNode] {
        var result = [NotifyNode]()
        for reg in notificationRegistrations {
            if reg.name == name {
                result.append(NotifyNode(observer: reg.observer, object: reg.object, selector: reg.selector))
            }
        }
        return result
    }
    
    func allNotificationNames() -> [Notification.Name] {
        var set = Set<Notification.Name>()
        for reg in notificationRegistrations {
            set.insert(reg.name)
        }
        return Array(set)
    }
    
}

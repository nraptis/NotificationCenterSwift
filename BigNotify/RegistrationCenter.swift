//
//  RegistrationCenter.swift
//  BigNotify
//
//  Created by Nicky Taylor (Nick Raptis) on 10/7/22.
//

import Foundation

struct NotifyNode: Hashable {
    let observer: NSObject
    let object: AnyHashable?
    let selector: Selector
}

// A key to access a dictionary by type: AnyHashable?
struct NotificationBucketObjectKey: Hashable {
    let object: AnyHashable?
}

class NotificationBucketObjectNode {
    
    let object: AnyHashable?
    private var selectorSet = Set<Selector>()
    
    init(object: AnyHashable?) {
        self.object = object
    }
    
    var allSelectors: [Selector] {
        return Array(selectorSet)
    }
    
    func addSelector(selector: Selector) {
        selectorSet.insert(selector)
    }
    
    func isEmpty() -> Bool {
        return allSelectors.count <= 0
    }
}

private class NotificationBucketObserverNode {
    
    let observer: NSObject
    var objectDict = [NotificationBucketObjectKey: NotificationBucketObjectNode]()
    
    init(_ observer: NSObject) {
        self.observer = observer
    }
    
    func addObject(object: AnyHashable?, selector: Selector) {
        let key = NotificationBucketObjectKey(object: object)
        if let node = objectDict[key] {
            node.addSelector(selector: selector)
        } else {
            let node = NotificationBucketObjectNode(object: object)
            node.addSelector(selector: selector)
            objectDict[key] = node
        }
    }
    
    func removeObject(object: AnyHashable?) {
        let key = NotificationBucketObjectKey(object: object)
        objectDict.removeValue(forKey: key)
    }
    
    func isEmpty() -> Bool {
        return objectDict.count == 0
    }
}

private class NotificationBucket {
    
    let name: NSNotification.Name
    fileprivate var observerDict = [NSObject: NotificationBucketObserverNode]()
    
    init(name: NSNotification.Name) {
        self.name = name
    }
    
    func allNotifyNodes() -> [NotifyNode] {
        var result = [NotifyNode]()
        for observerNode in observerDict.values {
            for objectNode in observerNode.objectDict.values {
                for selector in objectNode.allSelectors {
                    let observer = observerNode.observer
                    let object = objectNode.object
                    result.append(NotifyNode(observer: observer,
                                             object: object,
                                             selector: selector))
                    
                }
            }
        }
        
        return result
    }
    
    func addObserver(_ observer: NSObject, selector: Selector, object: AnyHashable?) {
        //let key = NotificationBucketObserverKey(observer: observer)
        if let node = observerDict[observer] {
            node.addObject(object: object, selector: selector)
        } else {
            let node = NotificationBucketObserverNode(observer)
            node.addObject(object: object, selector: selector)
            observerDict[observer] = node
        }
    }
    
    func removeObserver(_ observer: NSObject, object: AnyHashable?) {
        //let key = NotificationBucketObserverKey(observer: observer)
        if let bucket = observerDict[observer] {
            bucket.removeObject(object: object)
            if bucket.isEmpty() {
                observerDict.removeValue(forKey: observer)
            }
        }
    }
    
    func isEmpty() -> Bool {
        return observerDict.count <= 0
    }
    
}

// A key to access a dictionary by type: (NSNotification.Name, AnyHashable?)
private struct ObserverBucketNodeKey: Hashable {
    let name: NSNotification.Name
    let object: AnyHashable?
}

private struct ObserverBucketNode {
    
    let name: NSNotification.Name
    let object: AnyHashable?
    
    init(name: NSNotification.Name, object: AnyHashable?) {
        self.name = name
        self.object = object
    }
}

private class ObserverBucket {
    
    let observer: NSObject
    init(observer: NSObject) {
        self.observer = observer
    }
    
    fileprivate var dict = [ObserverBucketNodeKey: ObserverBucketNode]()
    
    func addNode(selector: Selector, name: NSNotification.Name, object: AnyHashable?) {
        let key = ObserverBucketNodeKey(name: name, object: object)
        if let node = dict[key] {
            dict[key] = node
        } else {
            let node = ObserverBucketNode(name: name, object: object)
            dict[key] = node
        }
    }
    
    func removeNode(name: NSNotification.Name, object: AnyHashable?) {
        let key = ObserverBucketNodeKey(name: name, object: object)
        dict.removeValue(forKey: key)
    }
    
    func isEmpty() -> Bool {
        return dict.count <= 0
    }
}

class RegistrationCenter {
    
    fileprivate var observerBucketDict = [NSObject: ObserverBucket]()
    fileprivate var notificationBucketDict = [Notification.Name: NotificationBucket]()
    
    func addObserver(observer: NSObject, selector: Selector, name: NSNotification.Name?, object: AnyHashable?) {
        guard let name = name else { return }
        
        if let bucket = notificationBucketDict[name] {
            bucket.addObserver(observer, selector: selector, object: object)
        } else {
            let bucket = NotificationBucket(name: name)
            notificationBucketDict[name] = bucket
            bucket.addObserver(observer, selector: selector, object: object)
        }
        
        if let bucket = observerBucketDict[observer] {
            bucket.addNode(selector: selector, name: name, object: object)
        } else {
            let bucket = ObserverBucket(observer: observer)
            observerBucketDict[observer] = bucket
            bucket.addNode(selector: selector, name: name, object: object)
        }
    }
    
    func removeObserver(observer: NSObject, name: NSNotification.Name?, object: AnyHashable?) {
        guard let name = name else { return }
        
        if let bucket = notificationBucketDict[name] {
            bucket.removeObserver(observer, object: object)
            if bucket.isEmpty() {
                notificationBucketDict.removeValue(forKey: name)
            }
        }
        
        if let bucket = observerBucketDict[observer] {
            bucket.removeNode(name: name, object: object)
            if bucket.isEmpty() {
                observerBucketDict.removeValue(forKey: observer)
            }
        }
    }
    
    func removeObserver(observer: NSObject) {
        if let bucket = observerBucketDict[observer] {
            let allNodes = bucket.dict.values
            for node in allNodes {
                removeObserver(observer: observer,
                               name: node.name,
                               object: node.object)
            }
            observerBucketDict.removeValue(forKey: observer)
        }
    }
    
    func post(notification: Notification) {
        if let bucket = notificationBucketDict[notification.name] {
            for notify in bucket.allNotifyNodes() {
                let observer = notify.observer
                let object = notify.object
                let selector = notify.selector
                observer.perform(selector, with: object)
            }
        }
    }    
}

// For testing, or inspecting contents

struct TestObserverRegistration: Hashable {
    let observer: NSObject
    let name: NSNotification.Name
    let object: AnyHashable?
}

struct TestNotificationRegistration: Hashable {
    let observer: NSObject
    let selector: Selector
    let name: NSNotification.Name
    let object: AnyHashable?
}

extension RegistrationCenter {
    
    func allObserverNodes() -> [TestObserverRegistration] {
        var result = [TestObserverRegistration]()
        for (observer, bucket) in observerBucketDict {
            for bucketNode in bucket.dict.values {
                let object = bucketNode.object
                let name = bucketNode.name
                result.append(TestObserverRegistration(observer: observer, name: name, object: object))
            }
        }
        return result
    }
    
    func allNotificationNodes() -> [TestNotificationRegistration] {
        var result = [TestNotificationRegistration]()
        for (name, bucket) in notificationBucketDict {
            for notify in bucket.allNotifyNodes() {
                let observer = notify.observer
                let object = notify.object
                let selector = notify.selector
                result.append(TestNotificationRegistration(observer: observer, selector: selector, name: name, object: object))
            }
        }
        return result
    }
    
    func allNotifyNodes(_ name: Notification.Name) -> [NotifyNode] {
        var result = [NotifyNode]()
        if let bucket = notificationBucketDict[name] {
            result.append(contentsOf: bucket.allNotifyNodes())
        }
        return result
    }
    
    func allNotificationNames() -> [Notification.Name] {
        
        var result = [Notification.Name]()
        for name in notificationBucketDict.keys {
            result.append(name)
        }
        return result
    }
    
}

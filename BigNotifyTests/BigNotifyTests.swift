//
//  BigNotifyTests.swift
//  BigNotifyTests
//
//  Created by Nicky Taylor (Nick Raptis) on 10/7/22.
//

import XCTest
@testable import BigNotify

func s_nn(_ string: String) -> Notification.Name {
    return Notification.Name(string)
}

func s_n(_ string: String) -> Notification {
    Notification(name: s_nn(string))
}

final class BigNotifyTests: XCTestCase {
    
    struct DummyObject: Hashable {
        let name: String
    }
    
    class DummyObserver: NSObject {
        let name: String
        let chirp: (Int, AnyHashable?) -> Void
        
        init(name: String, chirp: @escaping (Int, AnyHashable?) -> Void) {
            self.name = name
            self.chirp = chirp
        }
        
        @objc func method1(_ object: AnyHashable?) {
            chirp(1, object)
        }
        
        @objc func method2(_ object: AnyHashable?) {
            chirp(2, object)
        }
        
        @objc func method3(_ object: AnyHashable?) {
            chirp(3, object)
        }
        
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSimpleNotification() {
        var notifyWasCalled = false
        let observer = DummyObserver(name: "observer") { number, object in
            notifyWasCalled = true
        }
        let rc = RegistrationCenter()
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method3(_:)), name: s_nn("chirp"), object: nil)
        rc.post(notification: s_n("chirp"))
        XCTAssertTrue(notifyWasCalled)
    }
    
    func testSimpleUnregisterTriplet() {
        var notifyCountCalled = 0
        let observer = DummyObserver(name: "observer") { number, object in
            notifyCountCalled += 1
        }
        let rc = RegistrationCenter()
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method3(_:)), name: s_nn("chirp"), object: nil)
        rc.post(notification: s_n("chirp"))
        rc.removeObserver(observer: observer, name: s_nn("chirp"), object: nil)
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCountCalled == 1)
    }
    
    func testSimpleUnregisterObserver() {
        var notifyCountCalled = 0
        let observer = DummyObserver(name: "observer") { number, object in
            notifyCountCalled += 1
        }
        let rc = RegistrationCenter()
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method3(_:)), name: s_nn("chirp"), object: nil)
        rc.post(notification: s_n("chirp"))
        rc.removeObserver(observer: observer)
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCountCalled == 1)
    }
    
    func testSimpleUnregisterTripletWithAndWithoutObject() {
        var notifyCountCalled = 0
        let observer = DummyObserver(name: "observer") { number, object in
            notifyCountCalled += 1
        }
        let object = DummyObject(name: "object")
        let rc = RegistrationCenter()
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method3(_:)), name: s_nn("chirp"), object: object)
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCountCalled == 1)
        rc.removeObserver(observer: observer, name: s_nn("chirp"), object: nil)
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCountCalled == 2)
        rc.removeObserver(observer: observer, name: s_nn("chirp"), object: object)
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCountCalled == 2)
    }
    
    func test2Selectors() {
        
        var notifyCount1 = 0
        var notifyCount2 = 0
        let observer = DummyObserver(name: "observer") { number, object in
            if number == 1 { notifyCount1 += 1}
            if number == 2 { notifyCount2 += 1}
        }
        
        let rc = RegistrationCenter()
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method1(_:)), name: s_nn("chirp"), object: nil)
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method2(_:)), name: s_nn("chirp"), object: nil)
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCount1 == 1)
        XCTAssert(notifyCount2 == 1)
    }
    
    func test3Selectors() {
        
        var notifyCount1 = 0
        var notifyCount2 = 0
        var notifyCount3 = 0
        
        let observer = DummyObserver(name: "observer") { number, object in
            if number == 1 { notifyCount1 += 1}
            if number == 2 { notifyCount2 += 1}
            if number == 3 { notifyCount3 += 1}
        }
        
        let rc = RegistrationCenter()
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method1(_:)), name: s_nn("chirp"), object: nil)
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method2(_:)), name: s_nn("chirp"), object: nil)
        rc.addObserver(observer: observer, selector: #selector(DummyObserver.method3(_:)), name: s_nn("chirp"), object: nil)
        
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCount1 == 1)
        XCTAssert(notifyCount2 == 1)
        XCTAssert(notifyCount3 == 1)
        
        rc.post(notification: s_n("other"))
        XCTAssert(notifyCount1 == 1)
        XCTAssert(notifyCount2 == 1)
        XCTAssert(notifyCount3 == 1)
        
        rc.post(notification: s_n("chirp"))
        XCTAssert(notifyCount1 == 2)
        XCTAssert(notifyCount2 == 2)
        XCTAssert(notifyCount3 == 2)
    }
    
    func compareBF(_ registrationCenterBruteForce: RegistrationCenterBruteForce, _ registrationCenter: RegistrationCenter) -> Bool {
        
        let rc_notificationNodes = registrationCenter.allNotificationNodes()
        let bf_notificationNodes = registrationCenterBruteForce.allNotificationNodes()
        
        if rc_notificationNodes.count != bf_notificationNodes.count {
            print("MISMATCH 1: rc_no = \(rc_notificationNodes)")
            print("MISMATCH 1: bf_no = \(bf_notificationNodes)")
            return false
        } else {
            let bucket = Set(bf_notificationNodes)
            for node in rc_notificationNodes {
                if !bucket.contains(node) {
                    print("MISMATCH 2: rc_no = \(rc_notificationNodes)")
                    print("MISMATCH 2: bf_no = \(bf_notificationNodes)")
                    return false
                }
            }
        }
        
        let rc_observerNodes = registrationCenter.allObserverNodes()
        let bf_observerNodes = registrationCenterBruteForce.allObserverNodes()
        
        if rc_observerNodes.count != bf_observerNodes.count {
            print("MISMATCH 1: rc_o = \(rc_observerNodes)")
            print("MISMATCH 1: bf_o = \(bf_observerNodes)")
            return false
        } else {
            let bucket = Set(bf_observerNodes)
            for node in rc_observerNodes {
                if !bucket.contains(node) {
                    print("MISMATCH 2: rc_o = \(rc_observerNodes)")
                    print("MISMATCH 2: bf_o = \(bf_observerNodes)")
                    return false
                }
            }
        }
        
        let rc_names = registrationCenter.allNotificationNames()
        let bf_names = registrationCenterBruteForce.allNotificationNames()
        
        if rc_names.count != bf_names.count {
            print("MISMATCH 1: rc_nn = \(rc_names)")
            print("MISMATCH 1: bf_nn = \(bf_names)")
            return false
        } else {
            let bucket = Set(bf_names)
            for name in rc_names {
                if !bucket.contains(name) {
                    print("MISMATCH 2: rc_n = \(rc_names)")
                    print("MISMATCH 2: bf_n = \(bf_names)")
                    return false
                }
            }
        }
        
        for name in rc_names {
            
            let rc_notify = registrationCenter.allNotifyNodes(name)
            let bf_notify = registrationCenterBruteForce.allNotifyNodes(name)
            
            if rc_notify.count != bf_notify.count {
                print("MISMATCH 1: rc_ntfy = \(rc_notify)")
                print("MISMATCH 1: bf_ntfy = \(bf_notify)")
                return false
            } else {
                let bucket = Set(bf_notify)
                for notify in rc_notify {
                    if !bucket.contains(notify) {
                        print("MISMATCH 2: rc_ntfy = \(rc_notify)")
                        print("MISMATCH 2: bf_ntfy = \(bf_notify)")
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    func ensureEmptyBF(_ registrationCenterBruteForce: RegistrationCenterBruteForce, _ registrationCenter: RegistrationCenter) -> Bool {
        
        let rc_notificationNodes = registrationCenter.allNotificationNodes()
        let bf_notificationNodes = registrationCenterBruteForce.allNotificationNodes()
        
        if rc_notificationNodes.count > 0 {
            print("MISMATCH 1: rc_no = \(rc_notificationNodes)")
            print("MISMATCH 1: bf_no = \(bf_notificationNodes)")
            return false
        }
        
        if bf_notificationNodes.count > 0 {
            print("MISMATCH 1: rc_no = \(rc_notificationNodes)")
            print("MISMATCH 1: bf_no = \(bf_notificationNodes)")
            return false
        }
        
        
        let rc_observerNodes = registrationCenter.allObserverNodes()
        let bf_observerNodes = registrationCenterBruteForce.allObserverNodes()

        if rc_observerNodes.count != 0 {
            print("NOT-0 1: rc_o = \(rc_observerNodes)")
            print("NOT-0 1: bf_o = \(bf_observerNodes)")
            return false
        }

        if bf_observerNodes.count != 0 {
            print("NOT-0 1: rc_o = \(rc_observerNodes)")
            print("NOT-0 1: bf_o = \(bf_observerNodes)")
            return false
        }
        
        
        let rc_names = registrationCenter.allNotificationNames()
        let bf_names = registrationCenterBruteForce.allNotificationNames()
        
        if rc_names.count != 0 {
            print("NOT-0 1: rc_nn = \(rc_names)")
            print("NOT-0 1: bf_nn = \(bf_names)")
            return false
        }
        
        if bf_names.count != 0 {
            print("NOT-0 1: rc_nn = \(rc_names)")
            print("NOT-0 1: bf_nn = \(bf_names)")
            return false
        }

        
        return true
    }
    
    func testCompareWithBruteForce() {
        
        let object1 = DummyObject(name: "object_1")
        let object2 = DummyObject(name: "object_2")
        let object3 = DummyObject(name: "object_3")
        
        let observer1 = DummyObserver(name: "observer_1") { _, _ in }
        let observer2 = DummyObserver(name: "observer_1") { _, _ in }
        let observer3 = DummyObserver(name: "observer_1") { _, _ in }
        
        let name1 = s_nn("notification_1")
        let name2 = s_nn("notification_2")
        let name3 = s_nn("notification_3")
        
        let selector1 = #selector(DummyObserver.method1(_:))
        let selector2 = #selector(DummyObserver.method2(_:))
        let selector3 = #selector(DummyObserver.method3(_:))
        
        let rc = RegistrationCenter()
        let bf = RegistrationCenterBruteForce()
        
        let countSelector = 1
        let countName = 2
        let countObserver = 1
        let countObject = 1
        
        for selectorIndex in 0..<countSelector {
            var selector = selector1
            if selectorIndex == 1 { selector = selector2 }
            if selectorIndex == 2 { selector = selector3 }
            for observerIndex in 0..<countObserver {
                var observer = observer1
                if observerIndex == 1 { observer = observer2 }
                if observerIndex == 2 { observer = observer3 }
                for nameIndex in 0..<countName {
                    var name = name1
                    if nameIndex == 1 { name = name2 }
                    if nameIndex == 2 { name = name3 }
                    for objectIndex in 0..<countObject {
                        var object = object1
                        if objectIndex == 1 { object = object2 }
                        if objectIndex == 2 { object = object3 }
                        
                        rc.addObserver(observer: observer, selector: selector, name: name, object: object)
                        bf.addObserver(observer: observer, selector: selector, name: name, object: object)
                        
                        if !compareBF(bf, rc) {
                            XCTFail("Unexpected internal structure!")
                        }
                    }
                }
            }
        }
        
        for observerIndex in 0..<countObserver {
            var observer = observer1
            if observerIndex == 1 { observer = observer2 }
            if observerIndex == 2 { observer = observer3 }
            for nameIndex in 0..<countName {
                var name = name1
                if nameIndex == 1 { name = name2 }
                if nameIndex == 2 { name = name3 }
                for objectIndex in 0..<countObject {
                    var object = object1
                    if objectIndex == 1 { object = object2 }
                    if objectIndex == 2 { object = object3 }
                    
                    rc.removeObserver(observer: observer, name: name, object: object)
                    bf.removeObserver(observer: observer, name: name, object: object)
                    
                    if !compareBF(bf, rc) {
                        XCTFail("Unexpected internal structure!")
                    }
                }
            }
        }
        
        if !ensureEmptyBF(bf, rc) {
            XCTFail("Unexpected internal structure, should both be empty!")
        }
    }
    
    func randomString() -> String {
        let letters = "abcdefg1234567"
        return String((0..<10).compactMap{ _ in letters.randomElement() })
    }
    
    func testHardcore() {
        
        let rc = RegistrationCenter()
        let bf = RegistrationCenterBruteForce()
        
        var selectorList = [Selector]()
        selectorList.append(#selector(DummyObserver.method1(_:)))
        selectorList.append(#selector(DummyObserver.method2(_:)))
        selectorList.append(#selector(DummyObserver.method3(_:)))
        
        var objectList = [DummyObject?](repeating: nil, count: 10)
        for index in objectList.indices {
            if Int.random(in: 0...5) != 0 {
                let object = DummyObject(name: randomString())
                objectList[index] = object
            }
        }
        
        var observerList = [DummyObserver]()
        for _ in 0..<10 {
            let observer = DummyObserver(name: randomString()) { _, _ in }
            observerList.append(observer)
        }
        
        var nameList = [Notification.Name]()
        for _ in 0..<10 {
            let name = s_nn(randomString())
            nameList.append(name)
        }
        
        let addQuadruplets: (Int) -> Void = { count in
            
            for _ in 0..<count {
                guard let object = objectList.randomElement() else { continue }
                guard let name = nameList.randomElement() else { continue }
                guard let selector = selectorList.randomElement() else { continue }
                guard let observer = observerList.randomElement() else { continue }
                
                rc.addObserver(observer: observer, selector: selector, name: name, object: object)
                bf.addObserver(observer: observer, selector: selector, name: name, object: object)
                
                if !self.compareBF(bf, rc) {
                    XCTFail("Unexpected internal structure!")
                }
            }
        }
        
        let removeTriplets: (Int) -> Void = { count in
            
            for _ in 0..<count {
                guard let object = objectList.randomElement() else { continue }
                guard let name = nameList.randomElement() else { continue }
                guard let observer = observerList.randomElement() else { continue }
                
                rc.removeObserver(observer: observer, name: name, object: object)
                bf.removeObserver(observer: observer, name: name, object: object)
                
                if !self.compareBF(bf, rc) {
                    XCTFail("Unexpected internal structure!")
                }
            }
        }
        
        let removeObservers: (Int) -> Void = { count in
            for _ in 0..<count {
                
                guard let observer = observerList.randomElement() else { continue }
                
                rc.removeObserver(observer: observer)
                bf.removeObserver(observer: observer)
                
            }
            if !self.compareBF(bf, rc) {
                XCTFail("Unexpected internal structure!")
            }
        }
        
        let removeAll: () -> Void = {
            for observer in observerList {
                for name in nameList {
                    for object in objectList {
                        rc.removeObserver(observer: observer, name: name, object: object)
                        bf.removeObserver(observer: observer, name: name, object: object)
                    }
                }
            }
            if !self.ensureEmptyBF(bf, rc) {
                XCTFail("Unexpected internal structure!")
            }
        }
        
        let numberOfRuns = 1000
        for testIndex in 0...numberOfRuns {
            
            let random = Int.random(in: 0...100)
            
            if random < 10 {
                removeAll()
            } else if random < 30 {
                removeTriplets(Int.random(in: 0...50))
            } else if random < 50 {
                removeObservers(Int.random(in: 0...50))
            } else {
                addQuadruplets(Int.random(in: 0...50))
            }
            
            if (testIndex % 100) == 0 {
                print("Test Index: \(testIndex) / \(numberOfRuns)")
            }
        }
    }
}

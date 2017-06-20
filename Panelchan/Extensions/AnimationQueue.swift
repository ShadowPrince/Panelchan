//
//  AnimationQueue.swift
//  Panelchan
//
//  Created by shdwprince on 6/5/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import UIKit

class AnimationQueue {
    typealias Animation = () -> Void
    fileprivate var animations = [Animation]()
    fileprivate var completions = [Animation]()
    fileprivate var running = false

    func queue(duration: CFTimeInterval, _ block: @escaping Animation, _ completion: @escaping Animation) {
        self.animations.append(block)
        self.completions.append(completion)
        
        self.start(duration: duration)
    }

    func start(duration: CFTimeInterval) {
        if self.running {
            return
        }

        if let animation = self.animations.first,
           let completion = self.completions.first {
            let _ = self.animations.removeFirst()
            let _ = self.completions.removeFirst()

            print("started animation")
            self.running = true
            UIView.animate(withDuration: duration, animations: {
                animation()
            }) { (_) in
                print("done animation")
                completion()
                self.running = false
                self.start(duration: duration)
            }
        }
    }
}

var UIViewAnimationQueueHandle: UInt8 = 3
extension UIView {
    var animationQueue: AnimationQueue {
        get {
            var instance = objc_getAssociatedObject(self, &UIViewAnimationQueueHandle)
            if instance == nil {
                instance = AnimationQueue()
                objc_setAssociatedObject(self, &UIViewAnimationQueueHandle, instance, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            return instance as! AnimationQueue
        }
    }
}

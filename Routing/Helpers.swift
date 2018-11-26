//
//  Helpers.swift
//  Routing
//
//  Created by Chris Eidhof on 18.10.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Foundation

func async<A>(_ f: @escaping () -> A, onComplete: @escaping (A) -> ()) {
    DispatchQueue(label: "background").async {
        let result = f()
        DispatchQueue.main.async {
            onComplete(result)
        }
    }
}

import UIKit

typealias Constraint = (_ child: UIView, _ parent: UIView) -> NSLayoutConstraint

func equal<L, Axis>(_ to: KeyPath<UIView, L>) -> Constraint where L: NSLayoutAnchor<Axis> {
    return { view, parent in
        view[keyPath: to].constraint(equalTo: parent[keyPath: to])
    }
}

func equal<L>(_ keyPath: KeyPath<UIView, L>, to constant: CGFloat) -> Constraint where L: NSLayoutDimension {
    return { view, parent in
        view[keyPath: keyPath].constraint(equalToConstant: constant)
    }
}

func equal<L, Axis>(_ from: KeyPath<UIView, L>, _ to: KeyPath<UIView, L>) -> Constraint where L: NSLayoutAnchor<Axis> {
    return { view, parent in
        view[keyPath: from].constraint(equalTo: parent[keyPath: to])
    }
}

extension UIView {
    func addSubview(_ other: UIView, constraints: [Constraint]) {
        other.translatesAutoresizingMaskIntoConstraints = false
        addSubview(other)
        addConstraints(constraints.map { $0(other, self) })
    }
}

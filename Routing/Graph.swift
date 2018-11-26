//
//  Graph.swift
//  Routing
//
//  Created by Chris Eidhof on 22.11.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import UIKit

protocol Vector2 {
    associatedtype Component: Numeric
    var x: Component { get }
    var y: Component { get }
    init(x: Component, y: Component)
}

extension CGPoint: Vector2 {}

extension Vector2 {
    func dot(_ other: Self) -> Component {
        return (x * other.x) + (y * other.y)
    }
    
    static func -(l: Self, r: Self) -> Self {
        return Self(x: l.x-r.x, y: l.y-r.y)
    }
    
    static func +(l: Self, r: Self) -> Self {
        return Self(x: l.x+r.x, y: l.y+r.y)
    }
    
    static func *(l: Component, r: Self) -> Self {
        return Self(x: l*r.x, y: l*r.y)
    }
}

extension Vector2 where Component: FloatingPoint{
    func closestPoint(on line: (Self, Self)) -> Self {
        let s1 = line.0
        let s2 = line.1 - s1
        let p = self - s1
        let lambda = s2.dot(p) / s2.dot(s2)
        return s1 + lambda * s2
    }
}

import CoreLocation

// This is *not* a euclidian space, but it works well enough for this specific application.
extension CLLocationCoordinate2D: Vector2 {
    var x: Double { return longitude }    
    var y: Double { return latitude }
    
    typealias Component = Double
    
    init(x: Component, y: Component) {
        self.init(latitude: x, longitude: y)
    }
}

struct Graph {
    struct Destination {
        var coordinate: Coordinate
        var distance: CLLocationDistance
    }
    private(set) var edges: [Coordinate:[Destination]] = [:]
    
    mutating func addEdge(from: Coordinate, to: Coordinate) {
        let dist = from.distance(to: to)
        edges[from, default: []].append(Destination(coordinate: to, distance: dist))
    }
}

extension Graph {
    func debug_connectedVertices(vertex from: Coordinate) -> [[(Coordinate, Coordinate)]] {
        var result: [[(Coordinate, Coordinate)]] = [[]]
        var seen: Set<Coordinate> = []
        
        var sourcePoints = [from]
        while !sourcePoints.isEmpty {
            var newSourcePoints: [Coordinate] = []
            for source in sourcePoints {
                seen.insert(source)
                for edge in edges[source] ?? [] {
                    result[result.endIndex-1].append((source, edge.coordinate))
                    newSourcePoints.append(edge.coordinate)
                }
            }
            result.append([])
            sourcePoints = newSourcePoints.filter { !seen.contains($0) }
        }
        
        return result
    }
}

func buildGraph(tracks: [Track]) -> Graph {
    var result = Graph()
    for track in tracks {
        for (from, to) in zip(track.coordinates, track.coordinates.dropFirst() + [track.coordinates[0]]) {
            result.addEdge(from: from.coordinate, to: to.coordinate)
        }
    }
    return result
}


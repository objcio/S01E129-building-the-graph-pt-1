//
//  Helpers.swift
//  Routing
//
//  Created by Chris Eidhof on 18.10.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Foundation

enum Color: Int, Codable, Equatable, Hashable {
    case red
    case turquoise
    case brightGreen
    case violet
    case purple
    case green
    case beige
    case blue
    case brown
    case yellow
    case gray
    case lightBlue
    case lightBrown
    case orange
    case pink
    case lightPink
}

extension Color {
    var name: String {
        switch self {
        case .red: return "rot"
        case .turquoise: return "tuerkis"
        case .brightGreen: return "hellgruen"
        case .beige: return "beige"
        case .green: return "gruen"
        case .purple: return "lila"
        case .violet: return "violett"
        case .blue: return "blau"
        case .brown: return "braun"
        case .yellow: return "gelb"
        case .gray: return "grau"
        case .lightBlue: return "hellblau"
        case .lightBrown: return "hellbraun"
        case .orange: return "orange"
        case .pink: return "pink"
        case .lightPink: return "rosa"
        }
    }
}

struct Coordinate: Codable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct CoordinateWithElevation: Codable, Equatable, Hashable {
    let coordinate: Coordinate
    let elevation: Double
}

struct Track: Codable, Equatable, Hashable {
    var coordinates: [CoordinateWithElevation]
    let color: Color
    let number: Int
    let name: String
    
    var numbers: String {
        let components = name.split(separator: " ")
        guard !components.isEmpty else { return "" }
        
        func simplify<S: StringProtocol>(_ numbers: [S]) -> String {
            if numbers.count == 1 { return String(numbers[0]) }
            return String("\(numbers[0])-\(numbers.last!)")
        }
        
        return simplify(components.last!.split(separator: "/"))
    }
}

extension String {
    func remove(prefix: String) -> String {
        return String(dropFirst(prefix.count))
    }
}

final class TrackReader: NSObject, XMLParserDelegate {
    var inTrk = false
    
    var points: [CoordinateWithElevation] = []
    var pending: (lat: Double, lon: Double)?
    var elementContents: String = ""
    var name = ""
    
    init?(url: URL) {
        guard let parser = XMLParser(contentsOf: url) else { return nil }
        super.init()
        parser.delegate = self
        guard parser.parse() else { return nil }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        elementContents += string
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        guard inTrk else {
            inTrk = elementName == "trk"
            return
        }
        if elementName == "trkpt" {
            guard let latStr = attributeDict["lat"], let lat = Double(latStr),
                let lonStr = attributeDict["lon"], let lon = Double(lonStr) else { return }
            pending = (lat: lat, lon: lon)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        defer { elementContents = "" }
        var trimmed: String { return elementContents.trimmingCharacters(in: .whitespacesAndNewlines) }
        if elementName == "trk" {
            inTrk = false
        } else if elementName == "ele" {
            guard let p = pending, let ele = Double(trimmed) else { return }
            points.append(CoordinateWithElevation(coordinate: .init(latitude: p.lat, longitude: p.lon), elevation: ele))
        } else if elementName == "name" && inTrk {
            name = trimmed.remove(prefix: "Laufpark Stechlin - Wabe ")
        }
    }
}


extension Track {
    static func load() -> [Track] {
        let definitions: [(Color, Int)] = [
            (.red, 4),
            (.turquoise, 5),
            (.brightGreen, 7),
            (.beige, 2),
            (.green, 4),
            (.purple, 3),
            (.violet, 4),
            (.blue, 3),
            (.brown, 4),
            (.yellow, 4),
            (.gray, 0),
            (.lightBlue, 4),
            (.lightBrown, 5),
            (.orange, 0),
            (.pink, 4),
            (.lightPink, 6)
        ]
        var allTracks: [[Track]] = []
        allTracks = definitions.map { (color, count) in
            let begin = count == 0 ? 0 : 1
            let trackNames: [(Int, String)] = (begin...count).map { ($0, "gpx/wabe \(color.name)-strecke \($0)") }
            return trackNames.map { numberAndName -> Track in
                let reader = TrackReader(url: Bundle.main.url(forResource: numberAndName.1, withExtension: "gpx")!)!
                return Track(coordinates: reader.points, color: color, number: numberAndName.0, name: reader.name)
            }
        }
        return Array(allTracks.joined())
    }
}

#if os(OSX)
import Cocoa
typealias LColor = NSColor
#else
import UIKit
typealias LColor = UIColor
#endif


extension LColor {
    convenience init(r: Int, g: Int, b: Int) {
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
    }
}

extension Color {
    var textColor: LColor {
        switch self {
        case .yellow, .gray, .beige:
            return .black
        default:
            return .white
        }
    }
    var uiColor: LColor {
        switch self {
        case .red:
            return LColor(r: 255, g: 0, b: 0)
        case .turquoise:
            return LColor(r: 0, g: 159, b: 159)
        case .brightGreen:
            return LColor(r: 104, g: 195, b: 12)
        case .violet:
            return LColor(r: 174, g: 165, b: 213)
        case .purple:
            return LColor(r: 135, g: 27, b: 138)
        case .green:
            return LColor(r: 0, g: 132, b: 70)
        case .beige:
            return LColor(r: 227, g: 177, b: 151)
        case .blue:
            return LColor(r: 0, g: 92, b: 181)
        case .brown:
            return LColor(r: 126, g: 50, b: 55)
        case .yellow:
            return LColor(r: 255, g: 244, b: 0)
        case .gray:
            return LColor(r: 174, g: 165, b: 213)
        case .lightBlue:
            return LColor(r: 0, g: 166, b: 198)
        case .lightBrown:
            return LColor(r: 190, g: 135, b: 90)
        case .orange:
            return LColor(r: 255, g: 122, b: 36)
        case .pink:
            return LColor(r: 255, g: 0, b: 94)
        case .lightPink:
            return LColor(r: 255, g: 122, b: 183)
        }
    }
}

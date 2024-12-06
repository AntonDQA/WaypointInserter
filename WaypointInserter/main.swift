//https://github.com/DiadiukAntony

import CoreLocation
import Foundation
var waypoints = [CLLocationCoordinate2D]()
let step: CLLocationDistance = 50 // Step's distance in meters. Each WPT will be at {{distance}} meters between each other

//------------------- Reading WPT from file -> Return as CLLocationCoordinate2D array ---

func getDownloadsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
    return paths[0]
}

func getCoordsFromFile(file named: String) -> [CLLocationCoordinate2D] {

    var coordinates: [CLLocationCoordinate2D] = []
    var allWords = [String]()
    let fileURL = getDownloadsDirectory().appendingPathComponent(named)

    if let startWords = try? String(contentsOf: fileURL, encoding: .utf8) {
        allWords = startWords.components(separatedBy: "\n")
    }

    let pattern = #"lat\s*=\s*"([^"]+)"\s*lon\s*=\s*"([^"]+)""#
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    var latLonPairs: [(String, String)] = []
    for element in allWords {
        let range = NSRange(location: 0, length: element.utf16.count)
        if let match = regex.firstMatch(in: element, options: [], range: range) {
            if let latRange = Range(match.range(at: 1), in: element),
               let lonRange = Range(match.range(at: 2), in: element) {
                let lat = String(element[latRange])
                let lon = String(element[lonRange])
                latLonPairs.append((lat, lon))
            }
        }
    }

    for (lat, lon) in latLonPairs {
        if let latitude = Double(lat), let longitude = Double(lon) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            coordinates.append(coordinate)
        }
    }
    return coordinates
}

//------------------- Call for getting input coordinates from file ----------------------

waypoints = getCoordsFromFile(file: "inserter.gpx")

//------------------- Interpolation algorithm -------------------------------------------

extension CLLocationCoordinate2D {
    func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return to.distance(from: from)
    }
}
extension CLLocationDistance {
    func countOfSteps(step: CLLocationDistance) -> Int {
        let steps = self / step
        return steps > 0 ? Int(steps) : 1
    }
}

extension CLLocationDegrees {
    func interpolate(to: CLLocationDegrees, with numberOfSteps: Int) -> [CLLocationDegrees] {
        guard numberOfSteps > 0 else { return [self, to] }
        let diff = abs(self - to)
        let offset = diff / Double(numberOfSteps)
        let fromLessThenTo = to < self
        return (0...numberOfSteps).map { step in
            if fromLessThenTo {
                return self - Double(step) * offset
            } else {
                return self + Double(step) * offset
            }
        }
    }
}

extension CLLocationCoordinate2D {
    func interpolate(to: CLLocationCoordinate2D, with distance: CLLocationDistance) -> [CLLocationCoordinate2D] {
        let steps = self.distance(to: to).countOfSteps(step: distance)
        let lats = self.latitude.interpolate(to: to.latitude, with: steps)
        let longs = self.longitude.interpolate(to: to.longitude, with: steps)
        let pair = zip(lats, longs)
        return pair.map { CLLocationCoordinate2D(latitude: $0, longitude: $1) }
    }

    static func interpolateArray(locations: [CLLocationCoordinate2D], with distance: CLLocationDistance) -> [CLLocationCoordinate2D] {
        guard locations.count > 1 else { return locations }
        var result: [CLLocationCoordinate2D] = []
        for i in 0..<locations.count - 1 {
            let start = locations[i]
            let end = locations[i + 1]
            let interpolated = start.interpolate(to: end, with: distance)
            if i > 0 {
                result.append(contentsOf: interpolated.dropFirst())
            } else {
                result.append(contentsOf: interpolated)
            }
        }
        return result
    }
}

//------------------- Interpolation algorithm -> Getting Updated coordinates array ------


let coordinatesArray = CLLocationCoordinate2D.interpolateArray(locations: waypoints, with: step)

//------------------- Print updated coordinates array into updated.gpx file -------------

func coordsToGPXstring(coords: [CLLocationCoordinate2D]) -> String {
    var resultString = ""
    for i in 0...coords.count-1 {
        resultString.append((String(format : "<wpt lat=\"%f\" lon=\"%f\"></wpt> \n", coords[i].latitude, coords[i].longitude)))
    }
    return(resultString)
}

let gpxHeader = """
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.0" creator="GPSBabel - https://www.gpsbabel.org" xmlns="http://www.topografix.com/GPX/1/0"> \n
"""

let gpxFooter = "</gpx>"
let completeGPXString = gpxHeader + coordsToGPXstring(coords: coordinatesArray) + gpxFooter
let filename = getDownloadsDirectory().appendingPathComponent("updated.gpx")

do {
    try completeGPXString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
} catch {
    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
}

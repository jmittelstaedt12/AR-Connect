//
//  NetworkRequests.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/18/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import MapKit

struct NetworkRequests {

    enum Result {
        case success(Data)
        case failure(Error?)
    }

    static func profilePictureNetworkRequest(withUrl url: URL, completion: @escaping (Data) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data else {
                if let error = error { print(error.localizedDescription) }
                return
            }
            completion(data)
        }.resume()
    }

    static func directionsRequest(from coordinate: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let baseUrl = "https://maps.googleapis.com/maps/api/directions/json?"
        let originString = "origin=\(coordinate.latitude),\(coordinate.longitude)"
        let destinationString = "&destination=\(destination.latitude),\(destination.longitude)"
        let modeString = "&mode=walking"
        let keyString = "&key=AIzaSyC4-cZdDc2t--xQ7tF8swf3stVVrEgWrUo"
        let fullUrlString = baseUrl+originString+destinationString+modeString+keyString
        guard let url = URL(string: fullUrlString) else { return }
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)
        session.dataTask(with: URLRequest(url: url)) { (data, _, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                guard let data = data, let json = try? JSONSerialization.jsonObject(with: data), let dictionary = json as? [String: Any] else {
                    print("error getting data")
                    return
                }
                let pointsData = dictionary["routes"]
                    .map { $0 as? [Any] ?? [] }
                    .map { $0.first as? [String: AnyObject] ?? [:] }
                    .map { $0["overview_polyline"] as? [String: AnyObject] ?? [:] }
                    .map { $0["points"] as? String ?? "" }
                guard let points = pointsData, !points.isEmpty else { return }
                print(String(points[points.startIndex..<points.index(points.startIndex, offsetBy: 6)]))
                print(decodePolyline(String(points[points.startIndex..<points.index(points.startIndex, offsetBy: 6)])))
            }
        }.resume()
    }

    static func decodePolyline(_ encoded: String) -> Double? {
        // Functional:
        let binaryString = encoded.unicodeScalars.reversed()
            .map { ($0.value - 63) % 32 }
            .map { String($0, radix: 2) }
            .map { String(repeating: "0", count: 5-$0.count) + $0 }
            .reduce("") { $0 + $1 }
        print(binaryString.count)
        guard let value = Int(binaryString, radix: 2) else { return nil }
        let negationReversed = (value & 1) != 0 ? ~(value >> 1) : (value >> 1)
        // Imperative:
//        var valueString = ""
//        for c in encoded.unicodeScalars.reversed() {
//            var x = c.value - 63
//            x = x % 32
//            var xString = String(x, radix: 2)
//            for _ in xString.count..<5 {
//                xString.insert("0", at: xString.startIndex)
//            }
//            valueString += xString
//        }
//        let imperativeValue = Int(valueString, radix: 2)!
//        let num =  (imperativeValue & 1) != 0 ? ~(imperativeValue >> 1) : (imperativeValue >> 1)

        return Double(negationReversed) / 1E5
    }

}

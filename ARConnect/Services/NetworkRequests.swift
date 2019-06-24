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

//    enum Result {
//        case success(Data)
//        case failure(Error?)
//    }

    static func profilePictureNetworkRequest(withUrl url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let data = data {
                completion(.success(data))
            } else if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }

    static func directionsRequest(from coordinate: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping ([CLLocationCoordinate2D]?) -> Void) {
        let baseUrl = "https://maps.googleapis.com/maps/api/directions/json?"
        let originString = "origin=\(coordinate.latitude),\(coordinate.longitude)"
        let destinationString = "&destination=\(destination.latitude),\(destination.longitude)"
        let modeString = "&mode=walking"
        let keyString = "&key=\(SensitiveData.apiKey)"
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
                print(points)
                completion(decodePolyline(points))

                //                print(dictionary)
                //                let legs = dictionary["routes"]
                //                    .map { $0 as? [Any] ?? [] }
                //                    .map { $0.first as? [String: AnyObject] ?? [:] }
                //                    .map { $0["legs"] as? [Any] ?? [] }
                //                    .map { $0.first as? [String: AnyObject] ?? [:] }
                //                let steps = legs
                //                    .map { $0["steps"] as? [[String: AnyObject]] ?? [] }
                //                let polyline = steps?
                //                    .map { $0["polyline"] as? [String: AnyObject] ?? [:] }
                //                    .map { $0["points"] as? String ?? "" }
                //                    .reduce("") { $0 + $1 }
                //                guard let line = polyline, !line.isEmpty else { return }
                //                print(line)
            }
        }.resume()
//        let points = "ewowFrztbMi@a@n@mBkByAy@q@"
//        completion(decodePolyline(points))
    }

    static func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D]? {
        let encodedValues = String(encoded.reversed())
        let indices = encodedValues.unicodeScalars.enumerated()
            .filter { ($0.element.value - 63) <= 32 }
            .map { $0.offset }
        var coordinates: [CLLocationCoordinate2D] = []
        var isLat = true
        var lat = 0.0
        var lon = 0.0
        for index in stride(from: indices.count-1, to: -1, by: -1) {
            let startIndex = encodedValues.index(encodedValues.startIndex, offsetBy: indices[index])
            let endIndex = (index != indices.count-1) ? encodedValues.index(encodedValues.startIndex, offsetBy: indices[index+1]) : encodedValues.endIndex
            let binaryValues = String(encodedValues[startIndex..<endIndex]).unicodeScalars
                .map { ($0.value - 63) % 32 }
                .map { String($0, radix: 2) }
                .map { String(repeating: "0", count: 5-$0.count) + $0 }
                .reduce("") { $0 + $1 }
            guard let value = Int(binaryValues, radix: 2) else { return nil }
            let negationReversed = Double((value & 1) != 0 ? ~(value >> 1) : (value >> 1)) / 1E5
             if isLat {
                lat += negationReversed
             } else {
                lon += negationReversed
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
             }
            isLat.toggle()
        }
        return coordinates
    }

}

import Foundation
import Firebase
import AppsFlyerLib

final class HTTPConnector {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        let url = try buildAttributionURL(deviceID: deviceID)
        let request = URLRequest(url: url, timeoutInterval: 30)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        return try decodeJSON(data)
    }
    
    func resolveEndpoint(attributionData: [String: Any]) async throws -> String {
        let url = URL(string: "https://feedplannerplus.com/config.php")!
        let payload = assemblePayload(from: attributionData)
        let request = try buildPOSTRequest(url: url, payload: payload)
        
        let (data, _) = try await session.data(for: request)
        let json = try decodeJSON(data)
        
        guard let success = json["ok"] as? Bool, success,
              let endpoint = json["url"] as? String else {
            throw HTTPError.invalidEndpoint
        }
        
        return endpoint
    }
    
    private func buildAttributionURL(deviceID: String) throws -> URL {
        let base = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
        let appID = "id\(Config.appsFlyerId)"
        
        guard var components = URLComponents(string: base + appID) else {
            throw HTTPError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "devkey", value: Config.appsFlyerKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = components.url else {
            throw HTTPError.invalidURL
        }
        
        return url
    }
    
    private func assemblePayload(from data: [String: Any]) -> [String: Any] {
        var payload = data
        
        payload["os"] = DeviceInfo.platform()
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = DeviceInfo.bundleID()
        payload["firebase_project_id"] = DeviceInfo.firebaseProject()
        payload["store_id"] = DeviceInfo.storeID()
        payload["push_token"] = DeviceInfo.pushToken()
        payload["locale"] = DeviceInfo.locale()
        
        return payload
    }
    
    private func buildPOSTRequest(url: URL, payload: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encodeJSON(payload)
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw HTTPError.badResponse
        }
    }
    
    private func decodeJSON(_ data: Data) throws -> [String: Any] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HTTPError.decodingFailed
        }
        return json
    }
    
    private func encodeJSON(_ object: [String: Any]) throws -> Data {
        guard let data = try? JSONSerialization.data(withJSONObject: object) else {
            throw HTTPError.encodingFailed
        }
        return data
    }
}

// MARK: - HTTP Error
enum HTTPError: Error {
    case invalidURL
    case badResponse
    case decodingFailed
    case encodingFailed
    case invalidEndpoint
}

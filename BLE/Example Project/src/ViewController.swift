//
//  ViewController.swift
//  BLEVirus
//
//  Created by Marvin Mouroum on 03.04.20.
//  Copyright © 2020 mouroum. All rights reserved.
//

import UIKit

struct UUIDApi:Codable{
    
    var message:String = "uuid"
    var refids:[String]
}

struct PublishedUUID:Codable {
    var uuids:[String]
}

class ViewController: UIViewController {

    let BLE = BLE_iOS_Connection("Test", Data(base64Encoded: "Test"))
    
    lazy var button:UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "Logo"), for: .normal)
        b.addTarget(self, action: #selector(connect), for: .touchUpInside)
        b.imageView?.contentMode = .scaleAspectFit
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        runBLE()
        
        view.addSubview(button)
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        
        DispatchQueue.main.async {
            sleep(2)
            self.findMe()
        }
    }

    @objc func connect(){
        
        let peris = BLE.uuids.map { (id) -> String in
            return "\"\(id)\""
        }
        
        let ids = BLE.uuids.map { (id) -> String in
            return id.components(separatedBy: "-").joined(separator: "")
        }
        
        print("found \(peris.count) peripherals")
        
        let codable = UUIDApi(refids: ids)

        //create the url with URL
        let url = URL(string: "https://b.sos.foerster-technologies.com/status")! //change the url

        //create the session object
        let session = URLSession.shared

        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(codable)
            request.httpBody = encoded
            print(String(data: encoded, encoding: .utf8)!)
            
        } catch let error {
            print(error.localizedDescription)
        }

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("prototype", forHTTPHeaderField: "Authorization")

        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil else {
                return
            }

            guard let data = data else {
                return
            }

            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                    // handle json...
                }
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
        
    }
    
    func findMe() {
        
        let uuid = BLE.uuid.components(separatedBy: "-").joined(separator: "").uppercased()
        
        //create the url with URL
        let url = URL(string: "https://b.sos.foerster-technologies.com/published-uuids")! //change the url

        //create the session object
        let session = URLSession.shared

        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "GET" //set http method as POST


        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil else {
                return
            }

            guard let data = data else {
                return
            }

            do {
                //create json object from data
                let json = try JSONDecoder().decode(PublishedUUID.self, from: data)
                print(json.uuids)
                
                if json.uuids.contains(uuid.uppercased()){
                    DispatchQueue.main.async {
                        self.view.backgroundColor = .red
                    }
                    
                }
                
            }
            catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    
    func runBLE(){
        BLE.check_state { (state) in
            print("state: \(state[1])")
            return
        }
        
        BLE.start_advertising { (result)-> () in
            print(result)
            return
        }
        
        BLE.start_observing{ (result)-> () in
            print(result)
            return
        }
    }

}

